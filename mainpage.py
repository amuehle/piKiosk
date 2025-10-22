from PySide2.QtCore import QObject, Signal, Slot

import threading
from NetworkManager import NetworkManager, Settings, NM_STATE_CONNECTED_GLOBAL
from gi.repository import GLib
from Xlib import display
from Xlib.ext import dpms

from network import Network
from config import settings, C_LAN_IF, C_WIFI_IF
from event import event

class MainPage(QObject):
    def __init__(self):
        QObject.__init__(self)
        self.settings = settings
        self.net = Network(C_LAN_IF)
        self.wifi = Network(C_WIFI_IF)
        NetworkManager.OnStateChanged(self.nm_statechange)
        self.net.OnIFStateChanged(self.nm_statechange)
        self.wifi.OnIFStateChanged(self.nm_statechange)
        self.nm_thread = threading.Thread(target=GLib.MainLoop().run)
        self.nm_thread.start()
        self.d = display.Display()

    netok = Signal()
    neterror = Signal()
    netwarning = Signal()
    inetok = Signal()
    ineterror = Signal()
    wifiok = Signal()
    wifidisconnected = Signal()
    wifierror = Signal()
    wifiwarning = Signal()
    vpnup = Signal(bool)
    datanetwork = Signal("QVariant", "QVariant", str, arguments = ["ethparams", "wifiparams", "hostname"])
    evtdispatch = Signal(str)

    @Slot()
    def active(self):
        self.nm_statechange()
        self.get_network_data()
        event.attach(self.evthandler)

    def evthandler(self, evt):
        if evt == "EVT_VPN":
            self.nm_statechange()
        else:
            self.evtdispatch.emit(evt)

    def nm_statechange(self, *args, **kwargs):
        self.get_network_data()

        if self.net.get_interface_upandrunning():
            self.netok.emit()
        elif self.net.get_interface_up() or self.net.get_interface_active():
            self.netwarning.emit()
        else:
            self.neterror.emit()

        if NetworkManager.State == NM_STATE_CONNECTED_GLOBAL:
            self.inetok.emit()
        else:
            self.ineterror.emit()

        if self.wifi.get_interface_upandrunning():
            self.wifiok.emit()
        elif not self.wifi.get_connected():
            self.wifidisconnected.emit()
        elif self.wifi.get_interface_up() or self.wifi.get_interface_active():
            self.wifiwarning.emit()
        else:
            self.wifierror.emit()

        self.vpnup.emit(self._vpn_active())

    def get_network_data(self, *args, **kwargs):
        self.datanetwork.emit(self.net.get_network_params(), self.wifi.get_network_params(), Settings.Hostname)

    @Slot(result = str)
    def get_kiosk_url(self):
        return self.settings.get("KIOSK_URL")

    @Slot(result = float)
    def get_zoom_lvl(self):
        return self.settings.get("ZOOM_LEVEL")

    @Slot(result = int)
    def get_dispsleep(self):
        return self.settings.get("DISPSLEEP")

    @Slot(result = bool)
    def get_intkiosk(self):
        return self.settings.get("INT_KIOSK")

    @Slot()
    def display_on(self):
        dpms.force_level(self.d, dpms.DPMSModeOn)
        self.d.sync()

    @Slot()
    def display_off(self):
        dpms.force_level(self.d, dpms.DPMSModeOff)
        self.d.sync()

    def _vpn_active(self):
        for conn in NetworkManager.ActiveConnections:
            settings = conn.Connection.GetSettings()
            if settings["connection"]["type"] == "vpn":
                return True
        return False

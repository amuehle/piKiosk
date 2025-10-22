from PySide2.QtCore import QObject, Signal, Slot
import subprocess
import NetworkManager
import shutil
import sys

from network import Network
from config import settings, C_LAN_IF, C_WIFI_IF, C_APP_VER, C_VPN_FILE
from event import event

class SetupPage(QObject):
    def __init__(self):
        QObject.__init__(self)
        self.settings = settings
        self.net = Network(C_LAN_IF)
        self.wifi = Network(C_WIFI_IF)

    wifiscanresult = Signal(str, int, arguments = ["ssid", "rsnflags"])

    @Slot()
    def active(self):
        event.attach(self.system_action)

    @Slot(int, int)
    def set_display(self, timeout, brightness_level):
        self.settings.setsave("DISPLAY_TIMEOUT", timeout)

    @Slot(str, str, str, str, str)
    def set_network_lan(self, ethip, ethsm, dns1, dns2, router):
        self.net.set_network_settings(ethip, ethsm, dns1, dns2, router)
        self.wifi.connect_wifi("_", "")

    @Slot(str, str, str, str, str, str, str)
    def set_network_wifiandelan(self, wifiip, wifism, dns1, dns2, router, ethip, ethsm):
        self.wifi.set_network_settings(wifiip, wifism, dns1, dns2, router)
        self.net.set_network_settings(ethip, ethsm)

    @Slot(str, str)
    def set_network_wifidhcpandelan(self, ethip, ethsm):
        self.wifi.set_network_settings_dhcp()
        self.net.set_network_settings(ethip, ethsm)

    @Slot()
    def wifi_scan(self):
        for ap in self.wifi.scan():
            self.wifiscanresult.emit(ap.Ssid, ap.RsnFlags)

    @Slot(str, str)
    def wifi_connect(self, ssid, pw):
        self.wifi.connect_wifi(ssid, pw)

    @Slot(str)
    def set_hostname(self, hostname):
        NetworkManager.Settings.SaveHostname(hostname)

    @Slot(str, float, int, bool)
    def set_kiosk(self, KIOSK_URL, ZOOM_LEVEL, DISPSLEEP, INT_KIOSK):
        self.settings.set("KIOSK_URL", KIOSK_URL)
        self.settings.set("ZOOM_LEVEL", ZOOM_LEVEL)
        self.settings.set("DISPSLEEP", DISPSLEEP)
        self.settings.set("INT_KIOSK", INT_KIOSK)
        self.settings.save()
        event.fire("EVT_KIOSK")

    @Slot(str)
    def system_action(self, action):
        if action == "EVT_PWR_SHUTDOWN":
            subprocess.Popen(["/usr/sbin/poweroff"])
        elif action == "EVT_PWR_REBOOT":
            subprocess.Popen(["/usr/sbin/reboot"])
        elif action == "EVT_PWR_SYSRESET":
            self.reset_system()
            subprocess.Popen(["/usr/sbin/reboot"])

    @Slot()
    def setup_done(self):
        self.settings.setsave("FIRSTRUN", False)
        self.system_action("EVT_PWR_REBOOT")

    @Slot()
    def reset_system(self):
        self.settings.clear()
        self.settings.set("FIRSTRUN", True)
        self.settings.save()
        self.net.set_network_settings_dhcp(False)
        self.wifi.set_network_settings_dhcp(False)
        self.wifi.connect_wifi("_", "")
        self._del_vpn_connection(C_VPN_FILE)
        #NetworkManager does not clean up certs on connection delete
        shutil.rmtree(f"{os.path.expanduser('~')}/.local/share/networkmanagement/certificates/nm-openvpn", ignore_errors=True)
        #Clear browser data
        shutil.rmtree(f"{os.path.expanduser('~')}/.local/share/{sys.argv[0]}", ignore_errors=True)
        NetworkManager.Settings.SaveHostname("PIKIOSK")

    @Slot(result = str)
    def get_appver(self):
        return C_APP_VER

    def _del_vpn_connection(self, id):
        for conn in NetworkManager.Settings.ListConnections():
            settings = conn.GetSettings()
            if settings["connection"]["id"] == id and \
                settings["connection"]["type"] == "vpn":
                conn.Delete()
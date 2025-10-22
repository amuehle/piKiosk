import NetworkManager
import ipaddress
import netifaces

class Network:
    def __init__(self, interface):
        self._interface = interface
        self._nm_device = NetworkManager.NetworkManager.GetDeviceByIpIface(self._interface)

    def get_interface_up(self):
        if open(f"/sys/class/net/{self._interface}/operstate", "r").read().strip() == "up":
            return True
        else:
            return False

    def get_interface_active(self):
        return netifaces.AF_INET in netifaces.ifaddresses(self._interface)

    def get_interface_upandrunning(self):
        return self.get_interface_up() and self.get_interface_active()

    def get_network_params(self):
        ifparams = {}
        try:
            ifparams = netifaces.ifaddresses(self._interface)[netifaces.AF_INET][0]
            gw = netifaces.gateways()["default"][netifaces.AF_INET][0]
            dns = _parse_resolv_conf()
            conn_settings = self._nm_device.GetAppliedConnection(0)[0]
            ifparams["dhcp"] = True if conn_settings['ipv4']['method'] == "auto" else False
            ifparams["gw"] = gw
            ifparams["dns1"] = dns["nameservers"][0]
            ifparams["dns2"] = dns["nameservers"][1]
        except:
            conn = self._get_nm_iface_conn()
            conn_settings = conn.GetSettings()
            try:
                ifparams["dhcp"] = True if conn_settings["ipv4"]["method"] == "auto" else False
                address_data = conn_settings["ipv4"]["address-data"][0]
                ifparams = {"addr": address_data["address"], "netmask": str(ipaddress.IPv4Network(f"{address_data['address']}/{address_data['prefix']}", strict=False).netmask)}
                try:
                    ifparams["gw"] = conn_settings["ipv4"]["gateway"]
                    ifparams["dns"] = conn_settings["ipv4"]["dns"]
                except:
                    ifparams["gw"] = ""
                    ifparams["dns"] = ""
            except:
                ifparams["addr"] = ""
                ifparams["netmask"] = ""
                ifparams["gw"] = ""
                ifparams["dns"] = ""
        return ifparams

    def set_network_settings(self, ip, sm, dns1 = None, dns2 = None, router = None, try_apply = True):
        ip_network = ipaddress.IPv4Network((ip, sm), False).compressed
        prefix = int(ip_network.split('/')[1])
        conn = self._get_nm_iface_conn()
        conn_settings = conn.GetSettings()

        conn_settings["ipv4"]["method"] = "manual"
        conn_settings["ipv4"]["addresses"] = [[ip, prefix, router or "0.0.0.0"]]
        conn_settings["ipv4"]["address-data"] = [{"address": ip, "prefix": prefix}]
        if dns1:
            conn_settings["ipv4"]["dns"] = [dns1]
        if dns2:
            conn_settings["ipv4"]["dns"].append(dns2)
        if router:
            conn_settings["ipv4"]["gateway"] = router

        conn.Update(conn_settings)
        if try_apply:
            try:
                self._nm_device.Reapply(conn_settings, 0, 0)
            except:
                pass

    def set_network_settings_dhcp(self, try_apply = True):
        conn = self._get_nm_iface_conn()
        conn_settings = conn.GetSettings()

        conn_settings['ipv4']['method'] = "auto"
        conn_settings['ipv4']['addresses'] = []
        conn_settings['ipv4']['address-data'] = []
        conn_settings['ipv4'].pop("gateway", None)
        conn_settings['ipv4'].pop("dns", None)
        conn_settings['ipv4'].pop("dns-data", None)

        conn.Update(conn_settings)
        if try_apply:
            try:
                self._nm_device.Reapply(conn_settings, 0, 0)
            except:
                pass

    def get_connected(self):
        if self._nm_device.DeviceType != NetworkManager.NM_DEVICE_TYPE_WIFI:
            return

        for connection in NetworkManager.NetworkManager.ActiveConnections:
            if connection.Type == '802-11-wireless':
                return True
        return False

    def scan(self):
        if self._nm_device.DeviceType != NetworkManager.NM_DEVICE_TYPE_WIFI:
            return

        self._nm_device.RequestScan({})
        return self._nm_device.GetAllAccessPoints()

    def connect_wifi(self, ssid, pw):
        if self._nm_device.DeviceType != NetworkManager.NM_DEVICE_TYPE_WIFI:
            return

        conn = self._get_nm_iface_conn()
        conn_settings = conn.GetSettings()
        conn.Delete()

        conn_settings["802-11-wireless"]["ssid"] = ssid
        if pw:
            conn_settings["802-11-wireless"]["security"] = "802-11-wireless-security"
            conn_settings["802-11-wireless-security"] = {"auth-alg": "open", "key-mgmt": "wpa-psk", "psk": pw}
        else:
            conn_settings["802-11-wireless"].pop("security", None)
            conn_settings.pop("802-11-wireless-security", None)

        NetworkManager.NetworkManager.AddAndActivateConnection(conn_settings, self._nm_device, "/")

    def OnIFStateChanged(self, handler_func):
        self._nm_device.OnStateChanged(handler_func)

    def _get_nm_iface_conn(self):
        for conn in NetworkManager.Settings.ListConnections():
            if conn.GetSettings()["connection"].get("interface-name") == self._interface:
                return conn

def _parse_resolv_conf():
    resolv_data = {
        "nameservers": [],
        "search": [],
        "options": []
    }

    with open("/etc/resolv.conf", "r") as f:
        for line in f:
            # Remove comments and whitespace
            line = line.strip()
            if not line or line.startswith("#"):
                continue

            parts = line.split()
            if not parts:
                continue

            keyword = parts[0].lower()
            values = parts[1:]

            if keyword == "nameserver":
                resolv_data["nameservers"].extend(values)
            elif keyword == "search":
                resolv_data["search"].extend(values)
            elif keyword == "options":
                resolv_data["options"].extend(values)

    return resolv_data
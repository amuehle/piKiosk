from libs.adminui import *
from libs.adminui import Timer as UITimer
from cheroot import wsgi
from cheroot.ssl.builtin import BuiltinSSLAdapter
from Xlib import display, X
from PIL import Image
import io, base64, re, bcrypt, ipaddress, socket, psutil, shutil, netifaces
from datetime import datetime
import NetworkManager
import subprocess
import os
import holidays

from config import settings, C_LAN_IF, C_WIFI_IF, C_VPN_FILE, C_WEBADMIN_STYLE, C_APP_VER
from network import Network
from timer import Timer
from event import event
from scheduler import scheduler


net = Network(C_LAN_IF)
wifi = Network(C_WIFI_IF)

uptime_timer = Timer()
inet_timer = Timer()

uptime_timer.start()
if NetworkManager.NetworkManager.State == NetworkManager.NM_STATE_CONNECTED_GLOBAL:
    inet_timer.start()
    if settings.get("VPN_AUTOCON", False):
        if _get_vpn_connection(C_VPN_FILE):
            if not _vpn_active(C_VPN_FILE):
                _vpn_up(C_VPN_FILE)


app = AdminApp()
app.app_title = 'piKiosk'
app.app_logo = 'data:image/png;base64,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'
app.copyright_text = "AQUA Muehle Vorarlberg gGmbH"
app.footer_links = {'Github': 'https://github.com/amuehle/pikiosk', f"piKiosk V{C_APP_VER}": "https://github.com/amuehle/pikiosk/releases"}
app.app_styles = C_WEBADMIN_STYLE
app.default_pass = b'$2b$12$1VwUMBflRE3MbymynIV1P.YEWh8TkmJ5X.zDWLIQl46hMeEXwXUpW'

wsgi = wsgi.Server(('0.0.0.0', 9443), app.prepare())
wsgi.ssl_adapter = BuiltinSSLAdapter("ssl/server.crt", "ssl/server.key", None)


def _capture_screen():
    d = display.Display()
    root = d.screen().root
    geom = root.get_geometry()
    raw = root.get_image(0, 0, geom.width, geom.height, X.ZPixmap, 0xffffffff)
    image = Image.frombytes("RGB", (geom.width, geom.height), raw.data, "raw", "BGRX")

    buffer = io.BytesIO()
    image.save(buffer, format='PNG')
    return base64.b64encode(buffer.getvalue()).decode('utf-8')

def _validate_url(url):
    pattern = re.compile(
        r'^https?:\/\/(?:www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.'
        r'[a-zA-Z0-9()]{1,6}\b(?:[-a-zA-Z0-9()@:%_\+.~#?&\/=]*)$',
        re.IGNORECASE,
    )
    return bool(pattern.match(url))

def _get_ip_address(iface):
    try:
        if iface in netifaces.interfaces():
            addrs = netifaces.ifaddresses(iface)
            if netifaces.AF_INET in addrs:
                return addrs[netifaces.AF_INET][0]['addr']
    except Exception:
        pass
    return "-"

def _on_nm_statechange(*args, **kwargs):
    if NetworkManager.NetworkManager.State == NetworkManager.NM_STATE_CONNECTED_GLOBAL:
        inet_timer.start()
        if settings.get("VPN_AUTOCON", False):
            if _get_vpn_connection(C_VPN_FILE):
                if not _vpn_active(C_VPN_FILE):
                    _vpn_up(C_VPN_FILE)
    else:
        inet_timer.reset()

NetworkManager.NetworkManager.OnStateChanged(_on_nm_statechange)
net.OnIFStateChanged(_on_nm_statechange)
wifi.OnIFStateChanged(_on_nm_statechange)

def _get_vpn_connection(id):
    for conn in NetworkManager.Settings.ListConnections():
        settings = conn.GetSettings()
        if settings["connection"]["id"] == id and \
            settings["connection"]["type"] == "vpn":
            return conn
    return

def _vpn_active(id):
    for conn in NetworkManager.NetworkManager.ActiveConnections:
        settings = conn.Connection.GetSettings()
        if settings["connection"]["id"] == id and \
            settings["connection"]["type"] == "vpn":
            return True
    return False

def _vpn_up(id):
    conn = _get_vpn_connection(id)
    NetworkManager.NetworkManager.ActivateConnection(conn, "/", "/")

def _vpn_down(id):
    for conn in NetworkManager.NetworkManager.ActiveConnections:
        settings = conn.Connection.GetSettings()
        if settings["connection"]["id"] == id and \
            settings["connection"]["type"] == "vpn":
            NetworkManager.NetworkManager.DeactivateConnection(conn)
            return Notification('VPN', 'VPN disconnected successfully.', type='success')

def _screenshot_img():
    return RawHTML(
        f'<img src="data:image/png;base64,{_capture_screen()}" style="max-width: 100%;">',
        id="screenshot_img",
    )

def refresh_screenshot():
    return ReplaceElement("screenshot_img", _screenshot_img())

def _system_info_card():
    cpu_percent = psutil.cpu_percent(interval=0.2)
    cpu_freq = psutil.cpu_freq()
    memory = psutil.virtual_memory()
    disk = psutil.disk_usage('/')
    boot_time = datetime.fromtimestamp(psutil.boot_time()).strftime("%Y-%m-%d %H:%M:%S")

    today_sched = scheduler.get_today_schedule() if scheduler else None
    today_start = today_sched["start"] if today_sched else "-"
    today_end = today_sched["end"] if today_sched else "-"
    next_change = scheduler.get_next_change() if scheduler else None

    return Card(id="sysinfo", content=[
        Header('System Information', 1),

        DetailGroup('Resources', content=[
            DetailItem('CPU Usage', f"{cpu_percent}%"),
            DetailItem('CPU Frequency', f"{cpu_freq.current:.0f} MHz" if cpu_freq else "-"),
            DetailItem('RAM Usage', f"{memory.percent}% "
                       f"({memory.used // (1024**2)} MB / {memory.total // (1024**2)} MB)"),
            DetailItem('Disk Usage', f"{disk.percent}% "
                       f"({disk.used // (1024**3)} GB / {disk.total // (1024**3)} GB)"),
        ], bordered=True),

        Divider(),

        DetailGroup('Timers', content=[
            DetailItem('System Boot Time', boot_time),
            DetailItem('App Uptime', uptime_timer.elapsed_pp_string()),
            DetailItem('Internet Uptime', inet_timer.elapsed_pp_string()),
        ], bordered=True),

        Divider(),

        DetailGroup('Network', content=[
            DetailItem(f'LAN ({C_LAN_IF})', _get_ip_address(C_LAN_IF)),
            DetailItem(f'WIFI ({C_WIFI_IF})', _get_ip_address(C_WIFI_IF)),
            DetailItem('Hostname', socket.gethostname()),
        ], bordered=True),

        Divider(),

        DetailGroup('Display', content=[
            DetailItem('Current State', scheduler.get_state()),
            DetailItem('Today Active Hours', f"{today_start} – {today_end}"),
            DetailItem('Next Change', next_change if next_change else "-"),
        ], bordered=True),
    ])

def _vpn_info_card():
    conn = Card(id="vpninfo", content=[
        Header("OpenVPN", 1),
        Icon('link', size=30),
        DetailGroup("VPN Status", content=[
            DetailItem("Status", "Connected")
        ], bordered=True),
    ])
    disconn = Card(id="vpninfo", content=[
        Header("OpenVPN", 1),
        Icon('disconnect', size=30),
        DetailGroup("VPN Status", content=[
            DetailItem("Status", "Disconnected")
        ],bordered=True),
    ])
    return conn if _vpn_active(C_VPN_FILE) else disconn

def refresh_displayinfo(value, _):
    subdivs = holidays.country_holidays(value).subdivisions
    return ReplaceElement("holiday_subdiv", SelectBox("Subdivision", name="holiday_subdiv", data=subdivs, placeholder="Optional", id="holiday_subdiv"))

def disable_holiday():
    settings.remove('HOLIDAY_COUNTRY')
    settings.remove('HOLIDAY_SUBDIV')
    settings.save()
    return Notification("Display off on holiday disabled", type="success")

def refresh_vpninfo():
    return ReplaceElement("vpninfo", _vpn_info_card())

def on_refresh():
    return ReplaceElement("sysinfo", _system_info_card())

def on_admin_submit(form_data):
    if settings.has_option("WEB_PASSWORD"):
        return

    if bcrypt.checkpw(form_data["old_admpasswd"].encode(), app.default_pass) and \
       form_data["new_admpasswd1"] == form_data["new_admpasswd2"]:
        settings.setsave("WEB_PASSWORD", bcrypt.hashpw(form_data["new_admpasswd1"].encode(), bcrypt.gensalt()))
        return NavigateTo('/')
    return Notification('Failed to set new password', 'Please check password input.', type='error')

def on_net_submit(form_data):
    if form_data["netmode"] == "LAN":
        try:
            if form_data["hostname"] and \
               ipaddress.IPv4Address(form_data["ip_lan"]) and \
               ipaddress.IPv4Address(form_data["sm_lan"]) and \
               ipaddress.IPv4Address(form_data["dns1_lan"]) and \
               ipaddress.IPv4Address(form_data["dns2_lan"]) and \
               ipaddress.IPv4Address(form_data["gw_lan"]):
                net.set_network_settings(form_data["ip_lan"], form_data["sm_lan"],
                                         form_data["dns1_lan"], form_data["dns2_lan"],
                                         form_data["gw_lan"])
                NetworkManager.Settings.SaveHostname(form_data["hostname"])
                return Notification('LAN Settings applied',
                                    'LAN Settings are applied, you may have to reload if the address changed',
                                    type='success')
        except ipaddress.AddressValueError:
            return Notification('Check IP Settings!', 'Cannot apply network settings.', type='error')

    if form_data["netmode"] == "WIFI, Backup LAN" and not form_data.get("ip_wifi"):
        try:
            if form_data["hostname"] and \
               form_data["ssid"] and \
               ipaddress.IPv4Address(form_data["ip_lan"]) and \
               ipaddress.IPv4Address(form_data["sm_lan"]):
                wifi.set_network_settings_dhcp()
                net.set_network_settings(form_data["ip_lan"], form_data["sm_lan"])
                NetworkManager.Settings.SaveHostname(form_data["hostname"])
                wifi.connect_wifi(form_data["ssid"], form_data["wifipasswd"])
                return Notification('WIFI DHCP, Backup LAN applied',
                                    'Settings applied, reload if the address changed.',
                                    type='success')
        except ipaddress.AddressValueError:
            return Notification('Check IP Settings!', 'Cannot apply network settings.', type='error')

    elif form_data["netmode"] == "WIFI, Backup LAN":
        try:
            if form_data["hostname"] and \
               form_data["ssid"] and \
               ipaddress.IPv4Address(form_data["ip_lan"]) and \
               ipaddress.IPv4Address(form_data["sm_lan"]) and \
               ipaddress.IPv4Address(form_data["ip_wifi"]) and \
               ipaddress.IPv4Address(form_data["sm_wifi"]) and \
               ipaddress.IPv4Address(form_data["dns1_wifi"]) and \
               ipaddress.IPv4Address(form_data["dns2_wifi"]) and \
               ipaddress.IPv4Address(form_data["gw_wifi"]):
                wifi.set_network_settings(form_data["ip_wifi"], form_data["sm_wifi"],
                                          form_data["dns1_wifi"], form_data["dns2_wifi"],
                                          form_data["gw_wifi"])
                net.set_network_settings(form_data["ip_lan"], form_data["sm_lan"])
                NetworkManager.Settings.SaveHostname(form_data["hostname"])
                wifi.connect_wifi(form_data["ssid"], form_data["wifipasswd"])
                return Notification('WIFI, Backup LAN applied',
                                    'Settings applied, reload if the address changed.',
                                    type='success')
        except ipaddress.AddressValueError:
            return Notification('Check IP Settings!', 'Cannot apply network settings.', type='error')

    return Notification('Check Network Settings!', 'Cannot apply network settings.', type='error')

def on_netmodechange(value, _):
    return NavigateTo(f'/network?mode={value}')

def on_netconf_change(value, _):
    return ReplaceElement('wifistatic_sect', Divider())

def on_wifi_scan():
    aps = []
    default = None
    for ap in wifi.scan():
        aps.append(ap.Ssid)
    if aps:
        aps = list(set(aps))  # remove duplicates
        default = max(aps, key=len)
    return ReplaceElement('ssid', SelectBox('Select SSID', name="ssid", id="ssid",
                                            data=aps, value=default, placeholder="No SSIDs found"))

def on_kiosk_submit(form_data):
    if _validate_url(form_data["kurl"]) and form_data["dispsleep"].isdigit():
        settings.set("KIOSK_URL", form_data["kurl"])
        settings.set("ZOOM_LEVEL", float(form_data["bzoom"]))
        settings.set("DISPSLEEP", int(form_data["dispsleep"].strip()))
        settings.set("INT_KIOSK", True if form_data.get("int_kiosk", "") else False)
        settings.save()
        event.fire("EVT_KIOSK")
        return Notification('Kiosk settings', 'Kiosk settings saved.', type='success')

    return Notification('Check Kiosk Settings!', 'Cannot apply kiosk settings.', type='error')

def on_display_schedule_submit(form_data):
    schedule = {}
    time_pattern = re.compile(r"^(?:[01]\d|2[0-3]):[0-5]\d$")

    for day in ["mon","tue","wed","thu","fri","sat","sun"]:
        start = form_data.get(f"{day}_start", "").strip()
        end = form_data.get(f"{day}_end", "").strip()
        if start and not time_pattern.match(start):
            return Notification("Invalid Time", f"{day.capitalize()} start time is invalid (use HH:MM).", type="error")
        if end and not time_pattern.match(end):
            return Notification("Invalid Time", f"{day.capitalize()} end time is invalid (use HH:MM).", type="error")
        if start and end:
            schedule[day] = {"start": start, "end": end}

    settings.set("DISPLAY_SCHEDULE", schedule)
    settings.set("HOLIDAY_COUNTRY", form_data.get("holiday_country", ""))
    settings.set("HOLIDAY_SUBDIV", form_data.get("holiday_subdiv", ""))
    settings.save()

    return Notification("Display Schedule", "Schedule settings saved.", type="success")

def on_vpn_submit(form_data):
    action = form_data["action"]

    if action not in {"import", "connect", "disconnect", "delete"}:
        return Notification("VPN", "Please choose a valid action.", type="error")

    try:
        if action == "import":
            vpn_conf = form_data.get("vpn_conf", "")
            if not vpn_conf:
                return Notification("VPN", "Please paste your VPN config.", type="error")

            vpnuser = form_data.get("vpnuser", "")
            vpnpass = form_data.get("vpnpass", "")
            autocon = form_data["autoconn"]
            vpndefault = form_data["vpndefault"]

            import_file = f"/tmp/{C_VPN_FILE}.import"

            conf = _get_vpn_connection(C_VPN_FILE)
            if conf:
                conf.Delete()

            with open(import_file, "w") as tempfile:
                tempfile.write(vpn_conf)

            #For NetworkManager conversion, fallback to nmcli
            import_result = subprocess.run(
                ["nmcli", "connection", "import", "type", "openvpn", "file", import_file],
                capture_output=True, text=True
            )
            os.remove(import_file)

            if import_result.returncode != 0:
                return Notification("VPN Import Failed", import_result.stderr, type="error")

            imported_conf = _get_vpn_connection(C_VPN_FILE)
            conf_settings = imported_conf.GetSettings()

            if vpnuser:
                conf_settings["vpn"]["user-name"] = vpnuser
            if vpnpass:
                conf_settings['vpn']['data']['password-flags'] = '0'
                conf_settings['vpn']['secrets'] = {'password': vpnpass}
            conf_settings['ipv4']['never-default'] = True if vpndefault == "No" else False

            settings.set("VPN_AUTOCON", True if autocon == "Yes" else False)

            imported_conf.Update(conf_settings)

            event.fire("EVT_VPN")

            return Notification("VPN", "Profile imported/updated.", type="success")
        if action == "connect":
            if not _get_vpn_connection(C_VPN_FILE):
                return Notification("VPN Connect", "No VPN profile exists. Please import a profile first.", type="error")

            if _vpn_active(C_VPN_FILE):
                return Notification("VPN Connect", "VPN is already connected.", type="warning")

            _vpn_up(C_VPN_FILE)

            event.fire("EVT_VPN")

        if action == "disconnect":
            if not _get_vpn_connection(C_VPN_FILE):
                return Notification("VPN Disconnect", "No VPN profile exists. Please import a profile first.", type="error")

            if not _vpn_active(C_VPN_FILE):
                return Notification("VPN Disconnect", "VPN is already disconnected.", type="warning")

            _vpn_down(C_VPN_FILE)

            event.fire("EVT_VPN")

            return Notification("VPN Disconnect", "VPN is disconnected.", type="success")
        if action == "delete":
            if not _get_vpn_connection(C_VPN_FILE):
                return Notification("VPN Profile delete", "No VPN profile exists. Please import a profile first.", type="error")

            if _vpn_active(C_VPN_FILE):
                _vpn_down(C_VPN_FILE)

            _get_vpn_connection(C_VPN_FILE).Delete()

            #NetworkManager does not clean up certs on connection delete
            shutil.rmtree(f"{os.path.expanduser('~')}/.local/share/networkmanagement/certificates/nm-openvpn")

            event.fire("EVT_VPN")

            return Notification("VPN Delete", "Profile deleted successfully.", type="success")
    except Exception as ex:
        return Notification("Error", str(ex), type="error")

def on_sys_action(action):
    event.fire(action)
    return Result(title="Success", status='success', sub_title=f"Action {action} was executed")

@app.login()
def login_page(username, password):
    #Reload config in case password was resetted by CLI
    settings.reload_file()

    if not settings.has_option("WEB_PASSWORD") and \
       username == "admin" and bcrypt.checkpw(password.encode(), app.default_pass):
        return LoggedInUser(auth=[], redirect_to='/adminsetup')

    if settings.has_option("WEB_PASSWORD") and \
       username == "admin" and bcrypt.checkpw(password.encode(), settings.get("WEB_PASSWORD")):
        return LoggedInUser(username, avatar=None)

    return LoginFailed()

@app.page('/adminsetup', "form")
def adminsetup_page():
    if not settings.has_option("WEB_PASSWORD"):
        return [
            Form(on_submit=on_admin_submit, content=[
                TextField('Old password', name="old_admpasswd", required_message='Please input old admin password!', password=True),
                TextField('New password', name="new_admpasswd1", required_message='Please specify new admin password!', password=True),
                TextField('New password (repeat)', name="new_admpasswd2", required_message='Please repeat new admin password!', password=True),
                FormActions(content=[SubmitButton('Submit')])
            ])
        ]

    return Notification('404', 'Admin password already set.', type='error')

@app.page('/', 'Dashboard', auth_needed='user')
def dashboard_page():
    return [
        Card('Logged In', [
            Header('You are logged in'),
            Divider(),
            _screenshot_img(),
        ]),
        UITimer(1, refresh_screenshot),
    ]

@app.page('/network', 'form', auth_needed='user')
def network_page(_, params):
    sb_opts = ["LAN", "WIFI, Backup LAN"]
    sb = SelectBox('Connection-Mode', name="netmode", data=sb_opts,
                   placeholder="Select Mode", on_change=on_netmodechange)
    content = [sb]

    if not params:
        return [Form(content=content)]

    content.append(TextField('Hostname', name="hostname", required_message='Hostname is required!'))

    if params == {'mode': sb_opts[0]}:
        sb.value = sb_opts[0]
        content.append(
            DetailGroup('LAN', content=[
                TextField("LAN-IP", name='ip_lan', required_message='IP required!'),
                TextField("LAN-SM", name='sm_lan', required_message='Subnet required!'),
                TextField("LAN-DNS 1", name='dns1_lan', required_message='DNS required!'),
                TextField("LAN-DNS 2", name='dns2_lan', required_message='DNS required!'),
                TextField("LAN-GW", name='gw_lan', required_message='Gateway required!'),
            ])
        )

    if params == {'mode': sb_opts[1]}:
        sb.value = sb_opts[1]
        content.append(
            DetailGroup('LAN', content=[
                TextField("LAN-IP", name='ip_lan', value="192.168.1.1", required_message='IP required!'),
                TextField("LAN-SM", name='sm_lan', value="255.255.255.0", required_message='Subnet required!'),
            ])
        )
        content.append(
            DetailGroup('WIFI', id="wifistatic_sect", content=[
                RadioGroup('Mode', data=['DHCP', 'Static'], value="Static", on_change=on_netconf_change),
                TextField("WIFI-IP", name='ip_wifi', required_message='IP required!'),
                TextField("WIFI-SM", name='sm_wifi', required_message='Subnet required!'),
                TextField("WIFI-DNS 1", name='dns1_wifi', required_message='DNS required!'),
                TextField("WIFI-DNS 2", name='dns2_wifi', required_message='DNS required!'),
                TextField("WIFI-GW", name='gw_wifi', required_message='Gateway required!'),
            ])
        )
        content.append(
            DetailGroup('WIFI', content=[
                Card(content=[Button('Scan', on_click=on_wifi_scan)]),
                TextField('Manual SSID', name="ssid", id="ssid", placeholder="Input WIFI SSID",
                          required_message="SSID required!"),
                TextField('Passphrase', name="wifipasswd", password=True),
            ])
        )

    content.append(FormActions(content=[SubmitButton('Submit')]))
    return [Form(on_submit=on_net_submit, content=content)]

@app.page('/kiosk', 'form', auth_needed='user')
def kiosk_page():
    return [
        Form(on_submit=on_kiosk_submit, content=[
            TextField('Kiosk URL', name="kurl", value = settings.get("KIOSK_URL"), placeholder="https://example.com",
                      required_message='Kiosk URL is required!'),
            SelectBox('Browser Zoom-Factor', name="bzoom",
                      data=[f"{x/100:.2f}" for x in range(25, 505, 25)],
                      value = str(settings.get("ZOOM_LEVEL")),
                      placeholder="Select One"),
            TextField('Display-Sleep (s)', name="dispsleep",
                      placeholder="Specify display inactivity timeout",
                      value = str(settings.get("DISPSLEEP")),
                      required_message='Parameter is required!'),
            Tooltip("Enables touch input and dispsleep setting", [
                CheckboxGroup('Interactive Kiosk', value = "Enabled" if settings.get("INT_KIOSK") else None, data=['Enabled'], name="int_kiosk")
            ]),
            FormActions(content=[SubmitButton('Submit')])
        ])
    ]

@app.page('/display', 'form', auth_needed='user')
def display_page():
    schedule = settings.get("DISPLAY_SCHEDULE", {})
    country = settings.get("HOLIDAY_COUNTRY", "")
    subdiv = settings.get("HOLIDAY_SUBDIV", "")
    countries = sorted(holidays.list_supported_countries())

    def _time_val(day, key):
        return schedule.get(day, {}).get(key, "")

    form_fields = []
    holiday_settings = []

    holiday_settings.append(Header("Keep display off on holidays", level=2))
    holiday_settings.append(Link("List of countries, subdivisions", link_to="https://holidays.readthedocs.io/en/latest/#available-countries"))
    holiday_settings.append(SelectBox("Holiday Country", name="holiday_country", data=countries, value=country, on_change=refresh_displayinfo))
    if country:
        subdivs = holidays.country_holidays(country).subdivisions
        holiday_settings.append(SelectBox("Subdivision", name="holiday_subdiv", data=subdivs, value=subdiv, placeholder="Optional", id="holiday_subdiv"))
        holiday_settings.append(Button("Disable display off on holidays", on_click=disable_holiday))
    else:
        holiday_settings.append(SelectBox("Subdivision", name="holiday_subdiv", placeholder="Select a country to select subdivision", id="holiday_subdiv"))

    form_fields.append(
        Card(content=holiday_settings)
    )

    for day in ["mon","tue","wed","thu","fri","sat","sun"]:
        form_fields.append(
            DetailGroup(day.capitalize(), content=[
                TextField(f"{day.capitalize()} Start", name=f"{day}_start", placeholder="HH:MM", value=_time_val(day, "start")),
                TextField(f"{day.capitalize()} End", name=f"{day}_end", placeholder="HH:MM", value=_time_val(day, "end")),
            ], bordered=True)
        )

    form_fields.append(FormActions(content=[SubmitButton("Save Schedule")]))

    return [Form(on_submit=on_display_schedule_submit, content=form_fields)]

@app.page('/vpn', 'form', auth_needed='user')
def vpn_page():
    return [
        _vpn_info_card(),
        UITimer(2, refresh_vpninfo),

        Form(on_submit=on_vpn_submit, content=[
            SelectBox('Action', name='action',
                      data=['import', 'connect', 'disconnect', 'delete'],
                      placeholder='Choose action'),

            DetailGroup('Credentials (optional)', content=[
                TextField('Username', name='vpnuser'),
                TextField('Password', name='vpnpass', password=True),
            ], bordered=True),

            DetailGroup('Connection settings', content=[
                RadioGroup('Autoconnect', name="autoconn", data=['Yes', 'No'], value='Yes'),
                RadioGroup('Route all traffic through vpn', name="vpndefault", data=['Yes', 'No'], value='No'),
                TextArea('OpenVPN Profile', name='vpn_conf',
                         placeholder='Paste the full OpenVPN profile file here for import/update')
            ], bordered=True),

            FormActions(content=[SubmitButton('Apply')])
        ])
    ]

@app.page('/info', 'System Info', auth_needed='user')
def info_page():
    return [
        _system_info_card(),
        UITimer(1, on_refresh),
    ]

@app.page('/power', 'System action', auth_needed='user')
def syspower_page():
    return [
        Card(content=[
            Popconfirm('Really shutdown system?', on_submit=on_sys_action, content=[
                Button('System shutdown', icon="poweroff", style='danger')
            ], data="EVT_PWR_SHUTDOWN"),
            Popconfirm('Really reboot?', on_submit=on_sys_action, content=[
                Button('System reboot', icon="poweroff", style='danger')
            ], data="EVT_PWR_REBOOT"),
            Popconfirm('System is resetted and rebooted. Continue?', on_submit=on_sys_action, content=[
                Button('System reset', icon="setting", style='danger')
            ], data="EVT_PWR_SYSRESET"),
        ]),
    ]

@app.page('/certreload', '', auth_needed='user')
def reload_ssl_cert():
    wsgi.ssl_adapter = BuiltinSSLAdapter("ssl/server.crt", "ssl/server.key", None)
    return [Empty()]

app.set_menu([
    MenuItem('Dashboard', '/', icon="dashboard"),
    MenuItem('Settings', '', icon="setting", children=[
        MenuItem('Network', '/network', icon="apartment"),
        MenuItem('Kiosk', '/kiosk', icon="desktop"),
        MenuItem('Display', '/display', icon="schedule"),
        MenuItem('OpenVPN', '/vpn', icon="cloud-server")
    ]),
    MenuItem('Info', '/info', icon="info-circle"),
    MenuItem('Power', '/power', icon="poweroff")
])

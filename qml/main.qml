import QtQuick 2.15
import QtWebEngine 1.10
import QtQuick.Controls 2.15
import QtGraphicalEffects 1.15
import QtQuick.Window 2.15
import QtQuick.Layouts 1.15
import "components"
import "js/extract.js" as Extract
import "js/format.js" as Format
import "js/validate.js" as Validate

Window {
    id: appWindow
    visibility: Qt.WindowFullScreen
    title: "piKiosk"
    visible: true
    Component.onCompleted: backend.active()
    onClosing: {close.accepted = false} 

    WebEngineView {
        id: webengine
        anchors.fill: parent
        url: backend.get_kiosk_url()
        zoomFactor: backend.get_zoom_lvl()
        onLoadingChanged: {
            if (Extract.getDomain(this.url.toString()) !== Extract.getDomain(backend.get_kiosk_url())) {
                this.url = backend.get_kiosk_url()
            }
        }
    }

    Rectangle {
        id: nonint_overlay
        anchors.fill: parent
        color: "transparent"
        visible: !backend.get_intkiosk()

        MouseArea {anchors.fill: parent}
    }

    Rectangle {
        id: offlineOverlay
        anchors.fill: parent
        color: "#999999"
        visible: false

        Column {
            spacing: 5
            anchors.centerIn: parent

            Image {
                source: "images/nointernet_icon.svg"
                anchors.horizontalCenter: parent.horizontalCenter
                width: 150
                height: 150
            }

            Text {
                id: offlineText
                text: ""
                color: "white"
                font.pixelSize: 28
                wrapMode: Text.Wrap
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
        }
    }

    Rectangle {
        id: settingsOverlay
        anchors.fill: parent
        color: "black"
        visible: false
        Component.onCompleted: settingsbackend.active()

        QtObject {
            id: submit_netset

            function validset() {
                if (
                    netselComboBox.currentIndex === 0 &&
                    Validate.ip_address(lanipTextField.text) &&
                    Validate.ip_address(lansmTextField.text) &&
                    Validate.ip_address(landns1TextField.text) &&
                    (Validate.ip_address(landns2TextField.text) || !landns2TextField.text) &&
                    Validate.ip_address(langwTextField.text)
                ) {
                    settingsbackend.set_network_lan(
                        lanipTextField.text,
                        lansmTextField.text,
                        landns1TextField.text,
                        landns2TextField.text,
                        langwTextField.text
                    )
                    return true
                } else if (
                    netselComboBox.currentIndex === 1 &&
                    Validate.ip_address(wifiipTextField.text) &&
                    Validate.ip_address(wifismTextField.text) &&
                    Validate.ip_address(wifidns1TextField.text) &&
                    (wifidns2TextField.text === "" || Validate.ip_address(wifidns2TextField.text)) &&
                    Validate.ip_address(wifigwTextField.text) &&
                    Validate.ip_address(lanipTextField.text) &&
                    Validate.ip_address(lansmTextField.text)
                ) {
                    settingsbackend.set_network_wifiandelan(
                        wifiipTextField.text,
                        wifismTextField.text,
                        wifidns1TextField.text,
                        wifidns2TextField.text,
                        wifigwTextField.text,
                        lanipTextField.text,
                        lansmTextField.text
                    )
                    return true
                } else if (
                    netselComboBox.currentIndex === 1 &&
                    wifidhcpCheckbox.checked &&
                    Validate.ip_address(lanipTextField.text) &&
                    Validate.ip_address(lansmTextField.text)
                ) {
                    settingsbackend.set_network_wifidhcpandelan(
                        lanipTextField.text,
                        lansmTextField.text
                    )
                    return true
                } else {
                    edialog.bodyText = "Check IP Setting!"
                    edialog.open()
                    return false
                }
            }

        }

        Item {
            anchors.fill: parent

            Rectangle {
                id: statusBar
                width: parent.width
                height: 60
                anchors.top: parent.top
                color: "#1c1d20"

                Rectangle {
                    id: titleBar
                    anchors.fill: parent
                    color: "#00000000"

                    Text {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.leftMargin: 10
                        color: "#c3cbdd"
                        text: "piKiosk Settings"
                        font.pointSize: 17
                    }

                    Text {
                        anchors.centerIn: parent
                        color: "#c3cbdd"
                        text: `piKiosk V${settingsbackend.get_appver()}`
                        font.pointSize: 10
                    }

                    Row {
                        id: rowStatus
                        width: 310
                        height: parent.height
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 10

                        Item {
                            width: 35
                            height: parent.height

                            Image {
                                id: iconStatusVPN
                                source: "images/vpn_icon.svg"
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.horizontalCenter: parent.horizontalCenter
                                height: parent.height
                                width: parent.width
                                visible: true
                                fillMode: Image.PreserveAspectFit
                                mipmap: true
                            }

                            ColorOverlay {
                                id: iconStatusVPNColor
                                source: iconStatusVPN
                                anchors.fill: iconStatusVPN
                                color: "#ffffff"
                                anchors.verticalCenter: parent.verticalCenter
                                width: parent.width
                                height: parent.height
                                visible: false
                            }

                        }

                        Item {
                            width: 35
                            height: parent.height

                            Image {
                                id: iconStatusNet
                                source: "images/network_icon.svg"
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.horizontalCenter: parent.horizontalCenter
                                height: parent.height
                                width: parent.width
                                visible: true
                                fillMode: Image.PreserveAspectFit
                                mipmap: true
                            }

                            ColorOverlay {
                                id: iconStatusNetColor
                                source: iconStatusNet
                                anchors.fill: iconStatusNet
                                color: "#ffffff"
                                anchors.verticalCenter: parent.verticalCenter
                                width: parent.width
                                height: parent.height
                                visible: false
                            }

                            ColorOverlay {
                                id: iconStatusNetColorWarning
                                source: iconStatusNet
                                anchors.fill: iconStatusNet
                                color: "#fff000"
                                anchors.verticalCenter: parent.verticalCenter
                                width: parent.width
                                height: parent.height
                                visible: false
                            }

                            ColorOverlay {
                                id: iconStatusNetColorError
                                source: iconStatusNet
                                anchors.fill: iconStatusNet
                                color: "#ff0000"
                                anchors.verticalCenter: parent.verticalCenter
                                width: parent.width
                                height: parent.height
                                visible: false
                            }

                        }

                        Item {
                            width: 35
                            height: parent.height

                            Image {
                                id: iconStatusInet
                                source: "images/web_icon.svg"
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.horizontalCenter: parent.horizontalCenter
                                height: parent.height
                                width: parent.width
                                visible: true
                                fillMode: Image.PreserveAspectFit
                                mipmap: true
                            }

                            ColorOverlay {
                                id: iconStatusInetColor
                                source: iconStatusInet
                                anchors.fill: iconStatusInet
                                color: "#ffffff"
                                anchors.verticalCenter: parent.verticalCenter
                                width: parent.width
                                height: parent.height
                                visible: false
                            }

                        }

                        Item {
                            width: 35
                            height: parent.height

                            Image {
                                id: iconStatusWIFI
                                source: "images/wifi_icon.svg"
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.horizontalCenter: parent.horizontalCenter
                                height: parent.height
                                width: parent.width
                                visible: true
                                fillMode: Image.PreserveAspectFit
                                mipmap: true
                            }

                            ColorOverlay {
                                id: iconStatusWIFIColor
                                source: iconStatusWIFI
                                anchors.fill: iconStatusWIFI
                                color: "#ffffff"
                                anchors.verticalCenter: parent.verticalCenter
                                width: parent.width
                                height: parent.height
                                visible: false
                            }

                            ColorOverlay {
                                id: iconStatusWIFIColorWarning
                                source: iconStatusWIFI
                                anchors.fill: iconStatusWIFI
                                color: "#fff000"
                                anchors.verticalCenter: parent.verticalCenter
                                width: parent.width
                                height: parent.height
                                visible: false
                            }

                            ColorOverlay {
                                id: iconStatusWIFIColorError
                                source: iconStatusWIFI
                                anchors.fill: iconStatusWIFI
                                color: "#ff0000"
                                anchors.verticalCenter: parent.verticalCenter
                                width: parent.width
                                height: parent.height
                                visible: false
                            }

                        }

                        Item {
                            width: 150
                            height: 60

                            Text {
                                id: labelTime
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.horizontalCenter: parent.horizontalCenter
                                color: "#c3cbdd"
                                font.pointSize: 17
                            }

                            Timer {
                                id: timerClock
                                repeat: true
                                running: true
                                onTriggered: labelTime.text = Qt.formatTime(new Date(),"hh:mm:ss")
                            }

                        }

                    }
                }
            }

            TabBar {
                id: tabBar
                width: parent.width
                anchors.top: statusBar.bottom

                TabButton { text: "Netzwerk" }
                TabButton { text: "Kiosk" }
                TabButton { text: "Info" }
            }

            StackLayout {
                id: contentStack
                anchors.top: tabBar.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                currentIndex: tabBar.currentIndex

                Item {
                    id: networkTab

                    Column {
                        spacing: 10
                        anchors.centerIn: parent

                        ComboBox {
                            id: netselComboBox
                            width: parent.width
                            height: 33
                            currentIndex: 0
                            model: ["LAN", "WIFI, Backup LAN"]
                            onCurrentIndexChanged: {
                                if (this.currentIndex === 0) {
                                    wifinetPanel.visible = false
                                    wificonnPanel.visible = false
                                } else if (this.currentIndex === 1) {
                                    wifinetPanel.visible = true
                                    wificonnPanel.visible = true
                                }
                            }
                        }

                        Rectangle {
                            width: parent.width
                            height: 70
                            color: "#403a3a"
                            radius: 10

                            Text {
                                anchors.top: parent.top
                                anchors.horizontalCenter: parent.horizontalCenter
                                color: "#c3cbdd"
                                text: "Hostname"
                                font.pixelSize: 12
                            }

                            CustomTextField {
                                id: hostnameTextField
                                anchors.centerIn: parent
                                width: parent.width
                                placeholderText: ""
                                inputMethodHints: Qt.ImhNoPredictiveText
                            }

                        }

                        Row {
                            spacing: 10

                            Rectangle {
                                width: 150
                                height: 500
                                color: "#1c1d20"
                                radius: 10
                                anchors.verticalCenter: parent.verticalCenter

                                Text {
                                    anchors.top: parent.top
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    color: "#c3cbdd"
                                    text: "LAN"
                                    font.pixelSize: 12
                                }

                                Column {
                                    width: parent.width
                                    anchors.centerIn: parent
                                    spacing: 30

                                    Rectangle {
                                        width: parent.width
                                        height: 70
                                        color: "#403a3a"
                                        radius: 10

                                        Text {
                                            anchors.top: parent.top
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            color: "#c3cbdd"
                                            text: "IP"
                                            font.pixelSize: 12
                                        }

                                        CustomTextField {
                                            id: lanipTextField
                                            anchors.centerIn: parent
                                            width: parent.width
                                            placeholderText: "x.x.x.x"
                                            text: netselComboBox.currentIndex === 1 ? "192.168.1.1" : ""
                                            validator: RegularExpressionValidator {
                                                regularExpression: /^((25[0-5]|(2[0-4]|1\d|[1-9]|)\d)(\.(?!$)|$)){4}$/
                                            }
                                            inputMethodHints: Qt.ImhDigitsOnly | Qt.ImhNoPredictiveText
                                        }

                                    }

                                    Rectangle {
                                        width: parent.width
                                        height: 70
                                        color: "#403a3a"
                                        radius: 10

                                        Text {
                                            anchors.top: parent.top
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            color: "#c3cbdd"
                                            text: "SM"
                                            font.pixelSize: 12
                                        }

                                        CustomTextField {
                                            id: lansmTextField
                                            anchors.centerIn: parent
                                            width: parent.width
                                            placeholderText: "x.x.x.x"
                                            text: netselComboBox.currentIndex === 1 ? "255.255.255.0" : ""
                                            validator: RegularExpressionValidator {
                                                regularExpression: /^((25[0-5]|(2[0-4]|1\d|[1-9]|)\d)(\.(?!$)|$)){4}$/
                                            }
                                            inputMethodHints: Qt.ImhDigitsOnly | Qt.ImhNoPredictiveText
                                        }

                                    }

                                    Rectangle {
                                        width: parent.width
                                        visible: netselComboBox.currentIndex !== 1
                                        height: 70
                                        color: "#403a3a"
                                        radius: 10

                                        Text {
                                            anchors.top: parent.top
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            color: "#c3cbdd"
                                            text: "DNS1"
                                            font.pixelSize: 12
                                        }

                                        CustomTextField {
                                            id: landns1TextField
                                            anchors.centerIn: parent
                                            width: parent.width
                                            placeholderText: "x.x.x.x"
                                            validator: RegularExpressionValidator {
                                                regularExpression: /^((25[0-5]|(2[0-4]|1\d|[1-9]|)\d)(\.(?!$)|$)){4}$/
                                            }
                                            inputMethodHints: Qt.ImhDigitsOnly | Qt.ImhNoPredictiveText
                                        }

                                    }

                                    Rectangle {
                                        width: parent.width
                                        visible: netselComboBox.currentIndex !== 1
                                        height: 70
                                        color: "#403a3a"
                                        radius: 10

                                        Text {
                                            anchors.top: parent.top
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            color: "#c3cbdd"
                                            text: "DNS2"
                                            font.pixelSize: 12
                                        }

                                        CustomTextField {
                                            id: landns2TextField
                                            anchors.centerIn: parent
                                            width: parent.width
                                            placeholderText: "x.x.x.x"
                                            validator: RegularExpressionValidator {
                                                regularExpression: /^((25[0-5]|(2[0-4]|1\d|[1-9]|)\d)(\.(?!$)|$)){4}$/
                                            }
                                            inputMethodHints: Qt.ImhDigitsOnly | Qt.ImhNoPredictiveText
                                        }

                                    }

                                    Rectangle {
                                        width: parent.width
                                        visible: netselComboBox.currentIndex !== 1
                                        height: 70
                                        color: "#403a3a"
                                        radius: 10

                                        Text {
                                            anchors.top: parent.top
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            color: "#c3cbdd"
                                            text: "GW"
                                            font.pixelSize: 12
                                        }

                                        CustomTextField {
                                            id: langwTextField
                                            anchors.centerIn: parent
                                            width: parent.width
                                            placeholderText: "x.x.x.x"
                                            validator: RegularExpressionValidator {
                                                regularExpression: /^((25[0-5]|(2[0-4]|1\d|[1-9]|)\d)(\.(?!$)|$)){4}$/
                                            }
                                            inputMethodHints: Qt.ImhDigitsOnly | Qt.ImhNoPredictiveText
                                        }

                                    }

                                }

                            }

                            Rectangle {
                                id: wifinetPanel
                                visible: false
                                width: 150
                                height: 600
                                color: "#1c1d20"
                                radius: 10
                                anchors.verticalCenter: parent.verticalCenter

                                Text {
                                    anchors.top: parent.top
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    color: "#c3cbdd"
                                    text: "WIFI"
                                    font.pixelSize: 12
                                }

                                Column {
                                    width: parent.width
                                    anchors.centerIn: parent
                                    spacing: 30

                                    Rectangle {
                                        width: parent.width
                                        height: 50
                                        color: "#403a3a"
                                        radius: 10

                                        Text {
                                            anchors.top: parent.top
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            color: "#c3cbdd"
                                            text: "Mode"
                                            font.pixelSize: 12
                                        }

                                        CheckBox {
                                            id: wifidhcpCheckbox
                                            anchors.centerIn: parent
                                            text: "DHCP"
                                        }

                                    }

                                    Rectangle {
                                        width: parent.width
                                        height: 70
                                        color: "#403a3a"
                                        radius: 10

                                        Text {
                                            anchors.top: parent.top
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            color: "#c3cbdd"
                                            text: "IP"
                                            font.pixelSize: 12
                                        }

                                        CustomTextField {
                                            id: wifiipTextField
                                            anchors.centerIn: parent
                                            width: parent.width
                                            placeholderText: "x.x.x.x"
                                            validator: RegularExpressionValidator {
                                                regularExpression: /^((25[0-5]|(2[0-4]|1\d|[1-9]|)\d)(\.(?!$)|$)){4}$/
                                            }
                                            inputMethodHints: Qt.ImhDigitsOnly | Qt.ImhNoPredictiveText
                                            enabled: !wifidhcpCheckbox.checked
                                        }

                                    }

                                    Rectangle {
                                        width: parent.width
                                        height: 70
                                        color: "#403a3a"
                                        radius: 10

                                        Text {
                                            anchors.top: parent.top
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            color: "#c3cbdd"
                                            text: "SM"
                                            font.pixelSize: 12
                                        }

                                        CustomTextField {
                                            id: wifismTextField
                                            anchors.centerIn: parent
                                            width: parent.width
                                            placeholderText: "x.x.x.x"
                                            validator: RegularExpressionValidator {
                                                regularExpression: /^((25[0-5]|(2[0-4]|1\d|[1-9]|)\d)(\.(?!$)|$)){4}$/
                                            }
                                            inputMethodHints: Qt.ImhDigitsOnly | Qt.ImhNoPredictiveText
                                            enabled: !wifidhcpCheckbox.checked
                                        }

                                    }

                                    Rectangle {
                                        width: parent.width
                                        height: 70
                                        color: "#403a3a"
                                        radius: 10

                                        Text {
                                            anchors.top: parent.top
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            color: "#c3cbdd"
                                            text: "GW"
                                            font.pixelSize: 12
                                        }

                                        CustomTextField {
                                            id: wifigwTextField
                                            anchors.centerIn: parent
                                            width: parent.width
                                            placeholderText: "x.x.x.x"
                                            validator: RegularExpressionValidator {
                                                regularExpression: /^((25[0-5]|(2[0-4]|1\d|[1-9]|)\d)(\.(?!$)|$)){4}$/
                                            }
                                            inputMethodHints: Qt.ImhDigitsOnly | Qt.ImhNoPredictiveText
                                            enabled: !wifidhcpCheckbox.checked
                                        }

                                    }

                                    Rectangle {
                                        width: parent.width
                                        height: 70
                                        color: "#403a3a"
                                        radius: 10

                                        Text {
                                            anchors.top: parent.top
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            color: "#c3cbdd"
                                            text: "DNS1"
                                            font.pixelSize: 12
                                        }

                                        CustomTextField {
                                            id: wifidns1TextField
                                            anchors.centerIn: parent
                                            width: parent.width
                                            placeholderText: "x.x.x.x"
                                            validator: RegularExpressionValidator {
                                                regularExpression: /^((25[0-5]|(2[0-4]|1\d|[1-9]|)\d)(\.(?!$)|$)){4}$/
                                            }
                                            inputMethodHints: Qt.ImhDigitsOnly | Qt.ImhNoPredictiveText
                                            enabled: !wifidhcpCheckbox.checked
                                        }

                                    }

                                    Rectangle {
                                        width: parent.width
                                        height: 70
                                        color: "#403a3a"
                                        radius: 10

                                        Text {
                                            anchors.top: parent.top
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            color: "#c3cbdd"
                                            text: "DNS2"
                                            font.pixelSize: 12
                                        }

                                        CustomTextField {
                                            id: wifidns2TextField
                                            anchors.centerIn: parent
                                            width: parent.width
                                            placeholderText: "x.x.x.x"
                                            validator: RegularExpressionValidator {
                                                regularExpression: /^((25[0-5]|(2[0-4]|1\d|[1-9]|)\d)(\.(?!$)|$)){4}$/
                                            }
                                            inputMethodHints: Qt.ImhDigitsOnly | Qt.ImhNoPredictiveText
                                            enabled: !wifidhcpCheckbox.checked
                                        }

                                    }

                                }

                            }

                            Rectangle {
                                id: wificonnPanel
                                visible: false
                                width: 150
                                height: 500
                                color: "#1c1d20"
                                radius: 10
                                anchors.verticalCenter: parent.verticalCenter

                                Text {
                                    anchors.top: parent.top
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    color: "#c3cbdd"
                                    text: "WIFI"
                                    font.pixelSize: 12
                                }

                                Column {
                                    width: parent.width
                                    anchors.centerIn: parent
                                    spacing: 30

                                    CustomButton {
                                        id: scanwifiButton
                                        width: parent.width
                                        height: 35
                                        text: "Scan"
                                        onClicked: {
                                            wifiscanModel.clear()
                                            settingsbackend.wifi_scan()
                                        }
                                    }

                                    Rectangle {
                                        width: parent.width
                                        height: 85
                                        color: "#403a3a"
                                        radius: 10
                                        clip: true

                                        Column {
                                            anchors.fill: parent
                                            spacing: 10

                                            Repeater {
                                                model: ListModel {
                                                    id: wifiscanModel
                                                }

                                                Rectangle {
                                                    height: 10
                                                    width: parent.width
                                                    color: model.security ? "red" : "green"

                                                    Text {
                                                        text: model.ssid
                                                        font.pixelSize: 10
                                                        anchors.left: parent.left
                                                    }

                                                    MouseArea {
                                                        anchors.fill: parent
                                                        onClicked: {
                                                            wifissidTextField.text = model.ssid
                                                            pwRect.visible = model.security
                                                            wifipwTextField.text = ""
                                                        }
                                                    }

                                                }

                                            }

                                        }

                                    }

                                    Rectangle {
                                        width: parent.width
                                        height: 70
                                        color: "#403a3a"
                                        radius: 10

                                        Text {
                                            anchors.top: parent.top
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            color: "#c3cbdd"
                                            text: "SSID"
                                            font.pixelSize: 12
                                        }

                                        CustomTextField {
                                            id: wifissidTextField
                                            anchors.centerIn: parent
                                            width: parent.width
                                            placeholderText: ""
                                            inputMethodHints: Qt.ImhPreferLowercase | Qt.ImhNoPredictiveText
                                        }

                                    }

                                    Rectangle {
                                        id: pwRect
                                        width: parent.width
                                        height: 70
                                        color: "#403a3a"
                                        radius: 10

                                        Text {
                                            anchors.top: parent.top
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            color: "#c3cbdd"
                                            text: "Passphrase"
                                            font.pixelSize: 12
                                        }

                                        CustomTextField {
                                            id: wifipwTextField
                                            anchors.centerIn: parent
                                            width: parent.width
                                            echoMode: TextInput.Password
                                            inputMethodHints: Qt.ImhNoAutoUppercase | Qt.ImhPreferLowercase | Qt.ImhSensitiveData | Qt.ImhNoPredictiveText
                                            placeholderText: ""
                                        }

                                    }

                                }

                        }
                    }
                    }

                CustomButton {
                    id: netsubmitButton
                    width: 50
                    height: 35
                    anchors.bottom: parent.bottom
                    anchors.right: parent.right
                    text: "Submit"
                    onClicked: {
                        if (submit_netset.validset() && hostnameTextField.text) {
                            if (netselComboBox.currentIndex === 0) {
                                settingsbackend.set_hostname(hostnameTextField.text)
                                stackLayout.currentIndex++
                            }
                            if (netselComboBox.currentIndex === 1 && (wifissidTextField.length > 0) && ((pwRect.visible && wifipwTextField.length >= 8) || (!pwRect.visible))) {
                                settingsbackend.wifi_connect(wifissidTextField.text, wifipwTextField.text)
                                settingsbackend.set_hostname(hostnameTextField.text)
                                stackLayout.currentIndex++
                            } else {
                                edialog.bodyText = "Check Network Settings!"
                                edialog.open()
                            }
                        } else {
                            edialog.bodyText = "Check Network Settings!"
                            edialog.open()
                        }
                    }
                }

                }
                Item {
                    id: kioskTab

                    Row {
                        spacing: 10
                        anchors.centerIn: parent

                        Rectangle {
                            width: 250
                            height: 400
                            color: "#1c1d20"
                            radius: 10
                            anchors.verticalCenter: parent.verticalCenter

                            Text {
                                anchors.top: parent.top
                                anchors.horizontalCenter: parent.horizontalCenter
                                color: "#c3cbdd"
                                text: "App-Config"
                                font.pixelSize: 12
                            }

                            Column {
                                width: parent.width
                                spacing: 30
                                anchors.centerIn: parent

                                Rectangle {
                                    width: parent.width
                                    height: 70
                                    color: "#403a3a"
                                    radius: 10

                                    Text {
                                        anchors.top: parent.top
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        color: "#c3cbdd"
                                        text: "Kiosk URL"
                                        font.pixelSize: 12
                                    }

                                    CustomTextField {
                                        id: kurlTextField
                                        anchors.centerIn: parent
                                        width: parent.width
                                        placeholderText: ""
                                        inputMethodHints: Qt.ImhPreferLowercase | Qt.ImhNoPredictiveText
                                        validator: RegularExpressionValidator {
                                            regularExpression: /^https?:\/\/(?:www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b(?:[-a-zA-Z0-9()@:%_\+.~#?&\/=]*)$/
                                        }
                                    }

                                }

                                Rectangle {
                                    width: parent.width
                                    height: 70
                                    color: "#403a3a"
                                    radius: 10

                                    Text {
                                        anchors.top: parent.top
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        color: "#c3cbdd"
                                        text: "Browser Zoom-Factor"
                                        font.pixelSize: 12
                                    }

                                    ComboBox {
                                        id: bzoomComboBox
                                        anchors.centerIn: parent
                                        width: parent.width
                                        height: 33
                                        currentIndex: 3
                                        model: ["0.25", "0.50", "0.75", "1.0", "1.25", "1.50", "1.75", "2.0", "2.25", "2.50", "2.75", "3.0", "3.25", "3.50", "3.75", "4.0", "4.25", "4.50", "4.75", "5.0"]
                                    }

                                }

                                Rectangle {
                                    width: parent.width
                                    height: 70
                                    color: "#403a3a"
                                    radius: 10

                                    Text {
                                        anchors.top: parent.top
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        color: "#c3cbdd"
                                        text: "Display-Sleep (s)"
                                        font.pixelSize: 12
                                    }

                                    CustomTextField {
                                        id: dispsleeptimeTextField
                                        anchors.centerIn: parent
                                        width: parent.width
                                        text: "60"
                                        inputMethodHints: Qt.ImhDigitsOnly | Qt.ImhNoPredictiveText
                                    }

                                }

                                Rectangle {
                                    width: parent.width
                                    height: 70
                                    color: "#403a3a"
                                    radius: 10

                                    Text {
                                        anchors.top: parent.top
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        color: "#c3cbdd"
                                        text: "Interactive Kiosk"
                                        font.pixelSize: 12
                                    }

                                    CheckBox {
                                        id: intkioskCheckbox
                                        checked: true
                                        anchors.centerIn: parent
                                        text: "Enabled"
                                    }

                                }

                            }

                        }
                    }

                CustomButton {
                    id: kiosksubmitButton
                    width: 50
                    height: 35
                    anchors.bottom: parent.bottom
                    anchors.right: parent.right
                    text: "Submit"
                    onClicked: {
                        if (Validate.http_addr(kurlTextField.text)) {
                            settingsbackend.set_kiosk(kurlTextField.text, bzoomComboBox.currentText, dispsleeptimeTextField.text, intkioskCheckbox.checked)
                        } else {
                            edialog.bodyText = "Check Kiosk Settings!"
                            edialog.open()
                        }
                    }
                }

                }
                Item {
                    id: infoTab
                    Row {
                        spacing: 10
                        anchors.centerIn: parent

                        Rectangle {
                            x: 465
                            y: 45
                            width: 280
                            height: 220
                            color: "#1c1d20"
                            radius: 10
                            Text {
                                anchors.top: parent.top
                                anchors.horizontalCenter: parent.horizontalCenter
                                color: "#c3cbdd"
                                text: "Internet"
                                font.pixelSize: 12
                            }

                            Column {
                                width: 210
                                anchors.centerIn: parent
                                spacing: 30

                                Rectangle {
                                    width: parent.width
                                    height: 70
                                    color: "#403a3a"
                                    radius: 10

                                    Text {
                                        anchors.top: parent.top
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        color: "#c3cbdd"
                                        text: "Runtime"
                                        font.pixelSize: 12
                                    }

                                    Text {
                                        id: inetruntimeText
                                        text: Format.formatTime(netup_elapsed)
                                        width: parent.width
                                        height: parent.height
                                        verticalAlignment: Text.AlignVCenter
                                        horizontalAlignment: Text.AlignHCenter
                                        color: "#c3cbdd"
                                        font.pixelSize: 14
                                        font.bold: true
                                        wrapMode: Text.Wrap
                                    }

                                }
                            }
                        }
                        Rectangle {
                            x: 465
                            y: 45
                            width: 280
                            height: 220
                            color: "#1c1d20"
                            radius: 10
                            Text {
                                anchors.top: parent.top
                                anchors.horizontalCenter: parent.horizontalCenter
                                color: "#c3cbdd"
                                text: "System"
                                font.pixelSize: 12
                            }

                            Column {
                                width: 210
                                anchors.centerIn: parent
                                spacing: 30

                                Rectangle {
                                    width: parent.width
                                    height: 70
                                    color: "#403a3a"
                                    radius: 10

                                    Text {
                                        anchors.top: parent.top
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        color: "#c3cbdd"
                                        text: "Runtime"
                                        font.pixelSize: 12
                                    }

                                    Text {
                                        id: sysruntimeText
                                        text: Format.formatTime(uptime_elapsed)
                                        width: parent.width
                                        height: parent.height
                                        verticalAlignment: Text.AlignVCenter
                                        horizontalAlignment: Text.AlignHCenter
                                        color: "#c3cbdd"
                                        font.pixelSize: 14
                                        font.bold: true
                                        wrapMode: Text.Wrap
                                    }

                                }
                            }
                        }
                        Rectangle {
                            x: 465
                            y: 45
                            width: 280
                            height: 220
                            color: "#1c1d20"
                            radius: 10
                            Text {
                                anchors.top: parent.top
                                anchors.horizontalCenter: parent.horizontalCenter
                                color: "#c3cbdd"
                                text: "Power"
                                font.pixelSize: 12
                            }

                            Column {
                                width: 210
                                anchors.centerIn: parent
                                spacing: 30

                                Rectangle {
                                    width: parent.width
                                    height: 70
                                    color: "#403a3a"
                                    radius: 10

                                    Column {
                                        width: parent.width
                                        spacing: 10

                                        CustomButton {
                                            id: shutdownButton
                                            width: parent.width
                                            height: 30
                                            text: "Shutdown system"
                                            onClicked: {
                                                qdialog.headerTitle = "Shutdown"
                                                qdialog.bodyText = "Really shutdown system?"
                                                qdialog.action = "EVT_PWR_SHUTDOWN"
                                                qdialog.open()
                                            }
                                        }

                                        CustomButton {
                                            id: rebootButton
                                            width: parent.width
                                            height: 30
                                            text: "Reboot system"
                                            onClicked: {
                                                qdialog.headerTitle = "Reboot"
                                                qdialog.bodyText = "Really reboot?"
                                                qdialog.action = "EVT_PWR_REBOOT"
                                                qdialog.open()
                                            }
                                            onPressAndHold: {
                                                qdialog.headerTitle = "System reset"
                                                qdialog.bodyText = "System is resetted and rebooted. Continue?"
                                                qdialog.action = "EVT_PWR_SYSRESET"
                                                qdialog.open()
                                            }
                                        }
                                    }

                                }
                            }
                        }
                    }
                }
            }
        }
    }

    CustomDialog {
        id: edialog
        colorContent: "red"
        headerPic: "images/warning_icon.svg"
        headerTitle: "Error"
        bodyText: "Check setting!"
        acceptedButtonText: "OK"
        rejectedButtonText: ""
    }

    CustomDialog {
        id: qdialog
        property string action
        onAcceptedButtonClicked: settingsbackend.system_action(this.action)
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.AllButtons
        hoverEnabled: true
        propagateComposedEvents: true
        preventStealing: false
        onPressed: (mouse) => {
            sleepTimer.restart()
            mouse.accepted = false
        }
        onReleased: (mouse) => {
            sleepTimer.restart()
            mouse.accepted = false
        }
    }

    Rectangle {
        id: sleepOverlay
        anchors.fill: parent
        color: "black"
        visible: false

        MouseArea {
            anchors.fill: parent
            onPressed: {
                backend.display_on()
                wakeupTimer.start()
            }
        }
    }

    MouseArea {
    visible: !settingsOverlay.visible
    anchors.fill: parent
    enabled: false
    cursorShape: Qt.BlankCursor
    }

    Shortcut {
        sequence: "F6"
        onActivated: settingsOverlay.visible = true
    }

    Shortcut {
        sequence: "Esc"
        onActivated: settingsOverlay.visible = false
    }

    property int uptime_elapsed: 0
    Timer {
        id: uptimeTimer
        interval: 1000
        repeat: true
        running: true
        onTriggered: uptime_elapsed++
    }

    Timer {
        id: sleepTimer
        interval: backend.get_dispsleep() * 1000
        repeat: false
        running: backend.get_intkiosk()
        onTriggered: {
            backend.display_off()
            sleepOverlay.visible = true
        }
    }

    Timer {
        id: wakeupTimer
        interval: 3000
        repeat: false
        running: false
        onTriggered: {
            sleepOverlay.visible = false
            sleepTimer.start()
        }
    }

    property int netup_elapsed: 0
    Timer {
        id: netupTimer
        interval: 1000
        repeat: true
        running: false
        onTriggered: netup_elapsed++
    }

    Connections {
        target: backend

        function onNetok() {
            iconStatusNetColor.visible = true
            iconStatusNetColorWarning.visible = false
            iconStatusNetColorError.visible = false
        }

        function onNeterror() {
            iconStatusNetColor.visible = false
            iconStatusNetColorWarning.visible = false
            iconStatusNetColorError.visible = true
        }

        function onNetwarning() {
            iconStatusNetColor.visible = false
            iconStatusNetColorWarning.visible = true
            iconStatusNetColorError.visible = false
        }

        function onInetok() {
            netupTimer.running = true
            iconStatusInet.visible = false
            iconStatusInetColor.visible = true
            webengine.reloadAndBypassCache()
            webengine.visible = true
            offlineOverlay.visible = false
        }

        function onIneterror() {
            netupTimer.running = false
            netup_elapsed = 0
            iconStatusInet.visible = true
            iconStatusInetColor.visible = false
            webengine.visible = false
            offlineText.text = "No internet connection"
            offlineOverlay.visible = true
        }

        function onWifiok() {
            iconStatusWIFI.visible = false
            iconStatusWIFIColor.visible = true
            iconStatusWIFIColorWarning.visible = false
            iconStatusWIFIColorError.visible = false
        }

        function onWifidisconnected() {
            iconStatusWIFI.visible = true
            iconStatusWIFIColor.visible = false
            iconStatusWIFIColorWarning.visible = false
            iconStatusWIFIColorError.visible = false
        }

        function onWifierror() {
            iconStatusWIFI.visible = false
            iconStatusWIFIColor.visible = false
            iconStatusWIFIColorWarning.visible = false
            iconStatusWIFIColorError.visible = true
        }

        function onWifiwarning() {
            iconStatusWIFI.visible = false
            iconStatusWIFIColor.visible = false
            iconStatusWIFIColorWarning.visible = true
            iconStatusWIFIColorError.visible = false
        }

        function onVpnup(state) {
            if (state) {
                iconStatusVPN.visible = false
                iconStatusVPNColor.visible = true
            } else {
                iconStatusVPN.visible = true
                iconStatusVPNColor.visible = false
            }
        }

        function onEvtdispatch(evt) {
            switch (evt) {
                case "EVT_KIOSK":
                    webengine.reloadAndBypassCache()
                    webengine.zoomFactor = backend.get_zoom_lvl()
                    wakeupTimer.running = backend.get_intkiosk()
                    sleepTimer.running = backend.get_intkiosk()
                    sleepTimer.interval = backend.get_dispsleep() * 1000
                    sleepOverlay.visible = backend.get_intkiosk()
                    nonint_overlay.visible = !backend.get_intkiosk()
            }
        }

    }

    Connections {
        target: settingsbackend

        function onWifiscanresult(ssid, rsnflags) {
            wifiscanModel.append({ssid: ssid, security: rsnflags})
        }
    }

    Connections {
        target: backend

        function onDatanetwork(ethparams, wifiparams, hostname) {
            lanipTextField.text = ethparams.addr
            lansmTextField.text = ethparams.netmask
            wifidhcpCheckbox.checked = wifiparams.dhcp
            wifiipTextField.text = wifiparams.addr
            wifismTextField.text = wifiparams.netmask
            wifigwTextField.text = wifiparams.gw
            wifidns1TextField.text = wifiparams.dns1
            wifidns2TextField.text = wifiparams.dns2
            hostnameTextField.text = hostname
        }
    }

}

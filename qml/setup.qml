import QtQuick 2.15
import QtQuick.Window 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.VirtualKeyboard 2.15
import "components"
import "js/validate.js" as Validate

Window {
    id: setupWindow
    visibility: Qt.WindowFullScreen
    visible: true
    Component.onCompleted: settingsbackend.active()
    onClosing: {close.accepted = false} 

    CustomDialog {
        id: edialog
        colorContent: "red"
        headerPic: "images/warning_icon.svg"
        headerTitle: "Error"
        bodyText: "Check setting!"
        acceptedButtonText: "OK"
        rejectedButtonText: ""
    }

    Rectangle {
        id: bg
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        color: "#2c313c"
        z: 1

        Text {
            anchors.top: parent.top
            anchors.left: parent.left
            color: "#c3cbdd"
            text: `piKiosk V${settingsbackend.get_appver()}`
            font.pixelSize: 7
        }

        Text {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.margins: 20
            color: "#c3cbdd"
            text: "piKiosk Setup"
            font.pixelSize: 24
        }

        Rectangle {
            id: stageBar
            width: parent.width
            height: 50
            anchors.top: parent.top
            anchors.topMargin: 130
            color: "#1c1d20"

            Rectangle {
                width: 200
                height: 200
                radius: width / 2
                color: "dodgerblue"

                // Position circle horizontally depending on step
                x: {
                    let steps = stackLayout.count - 1
                    if (steps === 0) return 0
                    let progress = stackLayout.currentIndex / steps
                    return progress * (stageBar.width - width)
                }

                // Vertically align on top of bar
                y: - (height / 2) + (stageBar.height / 2)

                Behavior on x {
                    NumberAnimation {
                        duration: 300
                        easing.type: Easing.InOutQuad
                    }
                }

                Text {
                    anchors.centerIn: parent
                    color: "#c3cbdd"
                    text: stackLayout.currentIndex + 1
                    font.pixelSize: 48
                }
            }
        }

        StackLayout {
            id: stackLayout
            width: parent.width
            height: parent.height

            Item {
                id: networkTab

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
                                        checked: true
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

            }

            Item {
                id: appTab

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
                                    text: "https://example.com"
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

            }

        }

        CustomButton {
            width: 200
            height: 50
            anchors.bottom: parent.bottom
            anchors.right: parent.right
            text: stackLayout.currentIndex == stackLayout.count -1 ? "Complete" : "Next"
            onClicked: {
                switch (stackLayout.currentIndex) {
                    case 0:
                        if (submit_netset.validset() && hostnameTextField.text) {
                            if (netselComboBox.currentIndex === 0) {
                                settingsbackend.set_hostname(hostnameTextField.text)
                                stackLayout.currentIndex++
                                break
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
                        break
                    case 1:
                        if (Validate.http_addr(kurlTextField.text)) {
                            settingsbackend.set_kiosk(kurlTextField.text, bzoomComboBox.currentText, dispsleeptimeTextField.text, intkioskCheckbox.checked)
                            settingsbackend.setup_done()
                        } else {
                            edialog.bodyText = "Check Kiosk Settings!"
                            edialog.open()
                        }
                        break
                }

            }
        }

    }

    Connections {
        target: settingsbackend

        function onWifiscanresult(ssid, rsnflags) {
            wifiscanModel.append({ssid: ssid, security: rsnflags})
        }
    }

}
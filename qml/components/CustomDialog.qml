import QtQuick 2.15
import QtQuick.Controls 2.15

Dialog {
    id: dialog

    property color colorContent: "lightblue"
    property url headerPic: "../images/question_icon.svg"
    property string headerTitle
    property string bodyText
    property string acceptedButtonText: "Ja"
    property string rejectedButtonText: "Nein"
    signal acceptedButtonClicked()
    signal rejectedButtonClicked()


    modal: true
    parent: Overlay.overlay
    anchors.centerIn: parent

    contentItem: Rectangle {
        width: 300
        height: 150
        color: colorContent
        radius: 10

        Column {
            spacing: 10
            anchors.centerIn: parent

            Row {
                spacing: 20

                Image {
                    source: headerPic
                    width: 25
                    height: 25
                    anchors.verticalCenter: parent.verticalCenter
                    mipmap: true
                }

                Text {
                    text: headerTitle
                    font.bold: true
                    font.pixelSize: 20
                }

            }

            Text {
                text: bodyText
                font.pixelSize: 16
                anchors.horizontalCenter: parent.horizontalCenter
                wrapMode: Text.WordWrap
            }

            Row {
                spacing: 10
                anchors.horizontalCenter: parent.horizontalCenter

                Button {
                    text: acceptedButtonText
                    visible: acceptedButtonText
                    onClicked: {
                        acceptedButtonClicked()
                        dialog.close()
                    }
                }

                Button {
                    text: rejectedButtonText
                    visible: rejectedButtonText
                    onClicked: {
                        rejectedButtonClicked()
                        dialog.close()
                    }
                }

            }

        }
    }

}

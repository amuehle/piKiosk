import QtQuick 2.15
import QtQuick.Controls 2.15
import QtGraphicalEffects 1.15

Button {
    id: button

    property color colorDefault: "#4891d9"
    property color colorPressed: "#3F7EBD"
    property color colorDisabled: "#c3cbdd"

    QtObject{
        id: internal

        property var dynamicColor: (button.down) ? colorPressed : colorDefault
    }

    text: "Button"

    contentItem: Item {

        Text {
            id: name
            text: button.text
            font: button.font
            color: "#ffffff"
            anchors.verticalCenter: parent.verticalCenter
            anchors.horizontalCenter: parent.horizontalCenter
        }

    }

    background: Rectangle{
        color: enabled ? internal.dynamicColor : colorDisabled
        radius: 10
    }
}

import QtQuick 2.15
import QtQuick.Controls 2.15
import QtGraphicalEffects 1.15

TextField {
    id: textField

    property color colorDefault: "#282c34"
    property color colorOnFocus: "#242831"

    QtObject {
        id: internal

        property var dynamicColor: (textField.focus) ? colorOnFocus : colorDefault
    }

    implicitWidth: 300
    implicitHeight: 40
    placeholderText: "Placeholder"
    color: "#ffffff"
    background: Rectangle {
        color: internal.dynamicColor
        radius: 10
    }
    selectedTextColor: "#FFFFFF"
    placeholderTextColor: "#81848c"
}

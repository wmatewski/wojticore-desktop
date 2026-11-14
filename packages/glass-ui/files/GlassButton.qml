import QtQuick
import QtQuick.Controls

Button {
    id: control
    implicitHeight: 38
    contentItem: Text {
        text: control.text
        color: Theme.text
        font.pixelSize: 13
        font.weight: Font.DemiBold
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }
    background: Rectangle {
        radius: 11
        color: control.down ? "#805e68c7" : control.hovered ? "#70445180" : "#55303c63"
        border.color: Theme.border
        border.width: 1
    }
}

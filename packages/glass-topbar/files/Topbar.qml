import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import GlassUI

PanelWindow {
    id: panel
    anchors { top: true; left: true; right: true }
    implicitHeight: 48
    property int activeWorkspace: Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.id : 1
    property var currentTime: new Date()
    color: "transparent"
    exclusionMode: ExclusionMode.Auto

    Timer { interval: 1000; running: true; repeat: true; onTriggered: panel.currentTime = new Date() }

    Rectangle {
        anchors.fill: parent
        anchors.margins: 7
        radius: 14
        color: "#bd111a31"
        border.color: "#438fa8ef"
        border.width: 1

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 15
            anchors.rightMargin: 15
            spacing: 20
            Text { text: "◈  Wojticore"; color: Theme.text; font.pixelSize: 13; font.weight: Font.DemiBold }
            RowLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignHCenter
                spacing: 5
                Repeater {
                    model: 4
                    delegate: Button {
                        required property int index
                        text: String(index + 1)
                        implicitWidth: 30
                        implicitHeight: 28
                        onClicked: Hyprland.dispatch("workspace " + String(index + 1))
                        contentItem: Text { text: parent.text; color: Theme.text; font.pixelSize: 12; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                        background: Rectangle { radius: 8; color: index + 1 === panel.activeWorkspace ? "#7d8798f2" : "transparent" }
                    }
                }
            }
            Text { text: "◉  ◖  ▰"; color: "#d7def4"; font.pixelSize: 12 }
            Text {
                text: Qt.formatDateTime(panel.currentTime, "ddd, d MMM  ·  HH:mm")
                color: Theme.text
                font.pixelSize: 12
            }
        }
    }
}

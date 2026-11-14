import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import GlassUI

PanelWindow {
    anchors { left: true; bottom: true }
    margins { left: (screen.width - implicitWidth) / 2; bottom: 8 }
    implicitWidth: dockRow.implicitWidth + 24
    implicitHeight: 58
    color: "transparent"
    exclusiveZone: 0

    Rectangle {
        anchors.fill: parent
        radius: 17
        color: "#c0131d38"
        border.color: "#668ea7e9"
        border.width: 1

        RowLayout {
            id: dockRow
            anchors.centerIn: parent
            spacing: 7
            Repeater {
                model: ["Firefox", "Terminal", "Files", "Text Editor"]
                delegate: Button {
                    required property string modelData
                    property var entry: DesktopEntries.heuristicLookup(modelData)
                    implicitWidth: 36
                    implicitHeight: 36
                    Accessible.name: entry ? entry.name : "Application unavailable"
                    enabled: entry !== null
                    onClicked: if (entry) entry.execute()
                    contentItem: IconImage { source: entry ? entry.icon : "application-x-executable"; implicitWidth: 21; implicitHeight: 21 }
                    background: Rectangle { radius: 11; color: parent.hovered ? "#704d5c8a" : "#33334568"; border.color: "#276b82bd"; border.width: 1 }
                    ToolTip.visible: hovered && entry
                    ToolTip.text: entry ? entry.name : "Application unavailable"
                }
            }
            Rectangle { Layout.preferredWidth: 1; Layout.preferredHeight: 25; color: "#4cdae1f4" }
            Button {
                text: "⠿"
                implicitWidth: 36; implicitHeight: 36
                onClicked: Quickshell.execDetached({ command: ["quickshell", "ipc", "call", "glass-launcher", "toggle"] })
                contentItem: Text { text: "⠿"; color: Theme.text; font.pixelSize: 18; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                background: Rectangle { radius: 11; color: parent.hovered ? "#704d5c8a" : "#33334568" }
            }
        }
    }
}

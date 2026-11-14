import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import GlassUI

FloatingWindow {
    id: launcher
    property string query: ""
    title: "Glass Launcher"
    visible: false
    implicitWidth: 410
    implicitHeight: 430
    color: "transparent"

    IpcHandler {
        target: "glass-launcher"
        function toggle(): void { launcher.visible = !launcher.visible; if (launcher.visible) search.forceActiveFocus() }
    }
    GlobalShortcut {
        name: "glass-launcher-toggle"
        description: "Toggle the Glass application launcher"
        onPressed: {
            launcher.visible = !launcher.visible
            if (launcher.visible) search.forceActiveFocus()
        }
    }
    GlassCard {
        anchors.fill: parent
        anchors.margins: 4
        color: "#e1101932"
        radius: 20
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 10
            TextField {
                id: search
                Layout.fillWidth: true
                placeholderText: "Search applications…"
                color: Theme.text
                placeholderTextColor: Theme.muted
                font.pixelSize: 14
                onTextChanged: launcher.query = text
                background: Rectangle { radius: 10; color: "#66333f67"; border.color: Theme.border; border.width: 1 }
                Keys.onEscapePressed: launcher.visible = false
                Keys.onReturnPressed: {
                    const first = DesktopEntries.applications.values.find(app => app.name.toLowerCase().includes(launcher.query.toLowerCase()))
                    if (first) { first.execute(); launcher.visible = false }
                }
            }
            ListView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                model: DesktopEntries.applications
                delegate: Button {
                    required property var modelData
                    property var appEntry: modelData
                    visible: launcher.query.length === 0 || appEntry.name.toLowerCase().includes(launcher.query.toLowerCase()) || appEntry.genericName.toLowerCase().includes(launcher.query.toLowerCase())
                    width: ListView.view.width
                    height: visible ? 45 : 0
                    onClicked: { appEntry.execute(); launcher.visible = false }
                    contentItem: RowLayout {
                        Text { text: appEntry.icon || "◈"; color: Theme.text; font.pixelSize: 17; Layout.preferredWidth: 30; horizontalAlignment: Text.AlignHCenter }
                        ColumnLayout {
                            spacing: 1
                            Text { text: appEntry.name; color: Theme.text; font.pixelSize: 13 }
                            Text { text: appEntry.genericName || appEntry.comment; color: Theme.muted; font.pixelSize: 10; elide: Text.ElideRight }
                        }
                    }
                    background: Rectangle { radius: 9; color: parent.hovered ? "#554b5c91" : "transparent" }
                }
            }
        }
    }
}

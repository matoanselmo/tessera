import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import qs

// Workspaces belonging to this bar's own monitor. Hyprland creates workspaces
// lazily, so only the ones that currently exist are shown.
Rectangle {
    id: root

    required property ShellScreen screen

    readonly property HyprlandMonitor monitor: Hyprland.monitorFor(root.screen)

    color: ShellGlobals.materialColors.primary
    radius: ShellGlobals.radius

    implicitWidth: row.implicitWidth + 12
    implicitHeight: ShellGlobals.barThickness

    Layout.preferredHeight: ShellGlobals.barThickness
    Layout.alignment: Qt.AlignVCenter

    visible: repeater.count > 0

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: 4

        Repeater {
            id: repeater

            model: ScriptModel {
                // Negative ids are Hyprland's special workspaces, which do not
                // belong in a linear strip.
                values: [...Hyprland.workspaces.values].filter(ws => ws.id >= 0 && ws.monitor === root.monitor).sort((a, b) => a.id - b.id)
            }

            delegate: Rectangle {
                id: pill
                required property HyprlandWorkspace modelData

                readonly property bool isFocused: pill.modelData.focused
                readonly property bool isUrgent: pill.modelData.urgent

                implicitWidth: pill.isFocused ? 28 : 22
                implicitHeight: 22
                radius: ShellGlobals.radius

                color: {
                    if (pill.isUrgent)
                        return ShellGlobals.materialColors.errorcontainer;
                    if (pill.isFocused)
                        return ShellGlobals.materialColors.secondary;

                    return ShellGlobals.materialColors.tertiary;
                }

                Behavior on implicitWidth {
                    NumberAnimation {
                        duration: 140
                        easing.type: Easing.OutCubic
                    }
                }

                Behavior on color {
                    ColorAnimation {
                        duration: 140
                    }
                }

                Text {
                    anchors.centerIn: parent
                    text: pill.modelData.name
                    font.family: ShellGlobals.fontFamily
                    font.pixelSize: ShellGlobals.fontSize
                    font.bold: true
                    font.letterSpacing: ShellGlobals.letterSpacing

                    color: {
                        if (pill.isUrgent)
                            return ShellGlobals.materialColors.onerrorcontainer;
                        if (pill.isFocused)
                            return ShellGlobals.materialColors.onsecondary;

                        return ShellGlobals.materialColors.ontertiary;
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: pill.modelData.activate()
                }
            }
        }
    }
}

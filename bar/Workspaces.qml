import QtQuick
import QtQuick.Layouts
import Quickshell
import qs
import qs.services
import qs.components

// Workspaces belonging to this bar's own output. niri always keeps an empty
// workspace at the end of each output, so empty ones are hidden unless active.
Rectangle {
    id: root

    required property ShellScreen screen

    color: ShellGlobals.materialColors.primary
    radius: ShellGlobals.radius

    implicitWidth: row.implicitWidth + 12
    implicitHeight: ShellGlobals.barThickness

    Layout.preferredHeight: ShellGlobals.barThickness
    Layout.alignment: Qt.AlignVCenter

    visible: repeater.count > 0

    // Below the pills, so their left-click keeps priority; a right press there
    // is not accepted by them and falls through to here.
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.RightButton
        onClicked: Niri.toggleOverview()
    }

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: 4

        Repeater {
            id: repeater

            model: ScriptModel {
                // Keyed by id: niri replaces every workspace object on each
                // event, and comparing by identity would rebuild the pills and
                // cut their animations short.
                objectProp: "id"
                values: Niri.workspaces.filter(ws => ws.output === root.screen.name && (ws.is_active || ws.active_window_id !== null)).sort((a, b) => a.idx - b.idx)
            }

            delegate: Rectangle {
                id: pill
                required property var modelData

                // Looked up live so state stays current on a reused delegate.
                readonly property var workspace: Niri.workspaceById(pill.modelData.id) ?? pill.modelData
                readonly property bool isFocused: pill.workspace.is_active
                readonly property bool isUrgent: pill.workspace.is_urgent

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

                // The focused pill widens with the faintest overshoot.
                Behavior on implicitWidth {
                    Anim {
                        easing.type: Easing.OutBack
                        easing.overshoot: 1.2
                    }
                }

                Behavior on color {
                    CAnim {}
                }

                StyledText {
                    anchors.centerIn: parent
                    text: pill.workspace.name ?? pill.workspace.idx
                    font.pixelSize: ShellGlobals.fontSize
                    font.bold: true

                    color: {
                        if (pill.isUrgent)
                            return ShellGlobals.materialColors.onerrorcontainer;
                        if (pill.isFocused)
                            return ShellGlobals.materialColors.onsecondary;

                        return ShellGlobals.materialColors.ontertiary;
                    }
                }

                MouseArea {
                    cursorShape: Qt.PointingHandCursor
                    anchors.fill: parent
                    onClicked: Niri.focusWorkspace(pill.workspace)
                }
            }
        }
    }
}

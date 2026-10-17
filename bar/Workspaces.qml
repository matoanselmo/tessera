import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs
import qs.services
import qs.components

// Workspaces belonging to this bar's own output, each showing its number and
// the icons of the apps on it, in the order they sit. niri always keeps an
// empty workspace at the end of each output, so empty ones are hidden unless
// active.
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

                readonly property var apps: Niri.windowsOn(pill.workspace.id)
                // Past this many, the rest collapse into "+n".
                readonly property int maxIcons: 4

                implicitWidth: Math.max(pill.isFocused ? 28 : 22, content.implicitWidth + 14)
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

                readonly property color foreground: {
                    if (pill.isUrgent)
                        return ShellGlobals.materialColors.onerrorcontainer;
                    if (pill.isFocused)
                        return ShellGlobals.materialColors.onsecondary;

                    return ShellGlobals.materialColors.ontertiary;
                }

                Row {
                    id: content
                    anchors.centerIn: parent
                    spacing: 5

                    StyledText {
                        anchors.verticalCenter: parent.verticalCenter
                        text: pill.workspace.name ?? pill.workspace.idx
                        font.pixelSize: ShellGlobals.fontSize
                        font.bold: true
                        color: pill.foreground

                        Behavior on color {
                            CAnim {}
                        }
                    }

                    Repeater {
                        model: ScriptModel {
                            // Keyed by window id, so a window moving or
                            // retitling keeps its icon instead of rebuilding it.
                            objectProp: "id"
                            values: pill.apps.slice(0, pill.maxIcons)
                        }

                        Item {
                            id: app
                            required property var modelData

                            readonly property string icon: {
                                const entry = DesktopEntries.heuristicLookup(app.modelData.app_id ?? "");
                                return Quickshell.iconPath(entry?.icon || app.modelData.app_id || "", true);
                            }

                            anchors.verticalCenter: parent.verticalCenter
                            implicitWidth: 14
                            implicitHeight: 14
                            // Quieter on workspaces you are not looking at.
                            opacity: pill.isFocused ? 1 : 0.75

                            Behavior on opacity {
                                Anim {}
                            }

                            Anim on opacity {
                                from: 0
                                to: pill.isFocused ? 1 : 0.75
                            }

                            IconImage {
                                anchors.fill: parent
                                visible: app.icon !== ""
                                source: app.icon
                                asynchronous: true
                            }

                            // No themed icon for this app: a plain window glyph.
                            TintedIcon {
                                anchors.fill: parent
                                visible: app.icon === ""
                                size: 14
                                source: Qt.resolvedUrl("icons/window.png")
                                color: pill.foreground
                            }
                        }
                    }

                    StyledText {
                        anchors.verticalCenter: parent.verticalCenter
                        visible: pill.apps.length > pill.maxIcons
                        text: `+${pill.apps.length - pill.maxIcons}`
                        font.pixelSize: ShellGlobals.fontSize - 1
                        font.bold: true
                        color: pill.foreground
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

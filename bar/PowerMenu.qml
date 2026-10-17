import QtQuick
import QtQuick.Layouts
import Quickshell
import qs
import qs.components
import qs.logout

// Drops from the power button: a column of icon-only power actions, top to
// bottom, exactly as wide as the button so it reads as an extension of it.
BarPopup {
    id: menu

    required property PanelWindow bar
    required property Item anchorItem

    anchor.item: menu.anchorItem
    anchor.edges: Edges.Bottom | Edges.Right
    anchor.gravity: Edges.Bottom | Edges.Left
    anchor.margins.top: ShellGlobals.barGap

    implicitWidth: menu.anchorItem.width
    contentHeight: column.implicitHeight

    // Open state lives in LogoutState so the "logout" IPC target is registered
    // once; hiding the popup by any route writes back to it.
    readonly property bool shouldShow: LogoutState.menuOpen

    onShouldShowChanged: menu.shouldShow ? menu.open() : menu.close()
    onHidden: LogoutState.menuOpen = false

    ColumnLayout {
        id: column
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
        }
        spacing: 0

        Repeater {
            model: LogoutState.actions

            delegate: Rectangle {
                id: row
                required property LogoutButton modelData

                // Waiting for the confirming second click; see LogoutButton.confirm.
                property bool armed: false
                readonly property color foreground: {
                    if (row.armed)
                        return ShellGlobals.materialColors.onerrorcontainer;
                    if (hover.containsMouse)
                        return ShellGlobals.materialColors.ontertiary;
                    return ShellGlobals.materialColors.ontertiarycontainer;
                }

                Layout.fillWidth: true
                // Square, matching the button above.
                Layout.preferredHeight: menu.anchorItem.width
                radius: ShellGlobals.radius
                color: {
                    if (row.armed)
                        return ShellGlobals.materialColors.errorcontainer;
                    if (hover.containsMouse)
                        return ShellGlobals.materialColors.tertiary;
                    return "transparent";
                }

                Behavior on color {
                    CAnim {}
                }

                TintedIcon {
                    anchors.centerIn: parent
                    source: row.modelData.iconUrl
                    color: row.foreground
                }

                Timer {
                    running: row.armed
                    interval: 3000
                    onTriggered: row.armed = false
                }

                Connections {
                    target: menu


                    function onHidden() {
                        row.armed = false;
                    }
                }

                Tooltip {
                    target: row
                    text: row.armed ? row.modelData.confirm : row.modelData.text
                    hovered: hover.containsMouse
                    edge: Edges.Left
                }

                MouseArea {
                    id: hover
                    cursorShape: Qt.PointingHandCursor
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        if (row.modelData.confirm !== "" && !row.armed) {
                            row.armed = true;
                            return;
                        }

                        menu.close();
                        row.modelData.exec();
                    }
                }
            }
        }
    }
}

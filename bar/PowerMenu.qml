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
    implicitHeight: column.implicitHeight

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

                Layout.fillWidth: true
                // Square, matching the button above.
                Layout.preferredHeight: menu.anchorItem.width
                radius: ShellGlobals.radius
                color: hover.containsMouse ? ShellGlobals.materialColors.tertiary : "transparent"

                Behavior on color {
                    ColorAnimation {
                        duration: ShellGlobals.animFast
                    }
                }

                TintedIcon {
                    anchors.centerIn: parent
                    source: row.modelData.iconUrl
                    color: hover.containsMouse ? ShellGlobals.materialColors.ontertiary : ShellGlobals.materialColors.ontertiarycontainer
                }

                MouseArea {
                    id: hover
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        menu.close();
                        row.modelData.exec();
                    }
                }
            }
        }
    }
}

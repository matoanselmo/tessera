import QtQuick
import QtQuick.Layouts
import Quickshell
import qs
import qs.components
import qs.logout

// Drops from the power button: one row per power action, top to bottom.
BarPopup {
    id: menu

    required property PanelWindow bar
    required property Item anchorItem

    anchor.item: menu.anchorItem
    anchor.edges: Edges.Bottom | Edges.Right
    anchor.gravity: Edges.Bottom | Edges.Left
    anchor.margins.top: ShellGlobals.barGap

    implicitWidth: 180
    implicitHeight: column.implicitHeight + ShellGlobals.barGap * 2

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
            margins: ShellGlobals.barGap
        }
        spacing: 2

        Repeater {
            model: LogoutState.actions

            delegate: Rectangle {
                id: row
                required property LogoutButton modelData

                Layout.fillWidth: true
                Layout.preferredHeight: 34
                radius: ShellGlobals.radius
                color: hover.containsMouse ? ShellGlobals.materialColors.tertiary : "transparent"

                Behavior on color {
                    ColorAnimation {
                        duration: ShellGlobals.animFast
                    }
                }

                RowLayout {
                    anchors {
                        left: parent.left
                        right: parent.right
                        verticalCenter: parent.verticalCenter
                        leftMargin: 10
                        rightMargin: 10
                    }
                    spacing: 10

                    TintedIcon {
                        source: row.modelData.iconUrl
                        color: hover.containsMouse ? ShellGlobals.materialColors.ontertiary : ShellGlobals.materialColors.ontertiarycontainer
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: row.modelData.text
                        font.bold: true
                        font.pixelSize: 13
                        color: hover.containsMouse ? ShellGlobals.materialColors.ontertiary : ShellGlobals.materialColors.ontertiarycontainer
                    }
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

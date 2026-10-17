import Quickshell
import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Notifications
import qs
import qs.components

BarPopup {
    id: panel
    required property PanelWindow bar

    // Hangs below the top bar, flush with its right edge.
    anchor.window: bar
    anchor.rect.x: bar.width - panel.width - ShellGlobals.barGap
    anchor.rect.y: bar.height

    implicitWidth: 360
    implicitHeight: Math.min(header.implicitHeight + 13 + panel.listHeight, bar.screen.height * 0.8)

    readonly property int listHeight: listView.count === 0 ? 56 : listView.contentHeight + 16

    // Open state lives in the singleton so the "notifications" IPC target is
    // registered once, not once per screen. Every path that hides the popup
    // writes back to it, which keeps the IPC toggle in step.
    readonly property bool shouldShow: NotifServer.menuOpen

    onShouldShowChanged: panel.shouldShow ? panel.open() : panel.close()
    onHidden: NotifServer.menuOpen = false

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        RowLayout {
            id: header
            Layout.leftMargin: 10
            Layout.rightMargin: 10
            Layout.bottomMargin: 6
            Layout.topMargin: 6

            StyledText {
                text: "Notifications"
                font.bold: true
                font.pixelSize: 15
            }

            Item {
                Layout.fillWidth: true
            }

            TintedIcon {
                visible: listView.count > 0
                source: Qt.resolvedUrl("icons/clear_all.png")

                MouseArea {
                    anchors.fill: parent
                    onClicked: NotifServer.clearNotifs()
                }
            }
        }

        Divider {}

        StyledText {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: listView.count === 0
            text: "No notifications"
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            opacity: 0.6
            font.pixelSize: 13
        }

        ListView {
            id: listView

            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.minimumHeight: 0
            Layout.leftMargin: 10
            Layout.rightMargin: 10

            visible: listView.count > 0
            clip: true
            topMargin: 6
            bottomMargin: 10
            spacing: 6

            model: NotifServer.notifications

            delegate: NotificationEntry {
                id: toast
                required property Notification modelData

                width: listView.width
                notif: modelData

                NumberAnimation on opacity {
                    from: 0
                    to: 1
                    duration: ShellGlobals.animSlow
                }
            }
        }
    }
}

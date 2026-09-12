import Quickshell
import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Notifications
import Qt5Compat.GraphicalEffects
import qs

PopupWindow {
    id: panel
    required property PanelWindow bar

    color: "transparent"
    visible: false

    // Hangs below the top bar, flush with its right edge.
    anchor.window: bar
    anchor.rect.x: bar.width - panel.width - ShellGlobals.barGap
    anchor.rect.y: bar.height

    implicitWidth: 360
    implicitHeight: Math.min(header.implicitHeight + 13 + panel.listHeight, bar.screen.height * 0.8)

    readonly property int listHeight: listView.count === 0 ? 56 : listView.contentHeight + 16

    // Driven from the singleton so the "notifications" IPC target is registered
    // once, not once per screen.
    readonly property bool shouldShow: NotifServer.menuOpen

    onShouldShowChanged: {
        if (panel.shouldShow) {
            panel.visible = true;
            cardbox.state = "Open";
        } else {
            cardbox.state = "Closed";
        }
    }

    Rectangle {
        id: background
        anchors.fill: parent
        color: ShellGlobals.materialColors.tertiarycontainer
        opacity: cardbox.opacity
        radius: ShellGlobals.radius
    }

    ColumnLayout {
        id: cardbox
        anchors.fill: parent
        spacing: 0

        state: "Closed"
        states: [
            State {
                name: "Open"
                PropertyChanges {
                    cardbox.opacity: 1
                }
            },
            State {
                name: "Closed"
                PropertyChanges {
                    cardbox.opacity: 0
                }
            }
        ]

        onOpacityChanged: {
            if (cardbox.opacity == 0) {
                panel.visible = false;
            }
        }

        Behavior on opacity {
            NumberAnimation {
                duration: 160
            }
        }

        RowLayout {
            id: header
            Layout.leftMargin: 10
            Layout.rightMargin: 10
            Layout.bottomMargin: 6
            Layout.topMargin: 6

            Text {
                text: "Notifications"
                font.bold: true
                font.pixelSize: 15
                font.family: ShellGlobals.fontFamily
                font.letterSpacing: ShellGlobals.letterSpacing
                color: ShellGlobals.materialColors.ontertiarycontainer
            }

            Item {
                Layout.fillWidth: true
            }

            Item {
                visible: listView.count > 0
                Layout.preferredWidth: 18
                Layout.preferredHeight: 18

                MouseArea {
                    anchors.fill: parent
                    onClicked: NotifServer.clearNotifs()
                }

                Image {
                    id: clear_all
                    source: "icons/clear_all.png"
                    anchors.fill: parent
                    smooth: true
                    mipmap: true
                    visible: false
                }

                ColorOverlay {
                    anchors.fill: parent
                    source: clear_all
                    color: ShellGlobals.materialColors.ontertiarycontainer
                }
            }
        }

        // A layout child must be sized through Layout.*; a bare width/height
        // here is undefined behaviour and was silently ignored.
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            color: ShellGlobals.materialColors.ontertiarycontainer
            opacity: 0.15
        }

        Text {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: listView.count === 0
            text: "No notifications"
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            color: ShellGlobals.materialColors.ontertiarycontainer
            opacity: 0.6
            font.pixelSize: 13
            font.family: ShellGlobals.fontFamily
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
                    duration: 320
                }
            }
        }
    }
}

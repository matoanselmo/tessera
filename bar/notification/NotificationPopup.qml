import QtQuick
import Quickshell
import qs
import qs.services

// Stack of toasts hanging below the bar's right edge, newest at the bottom.
// Each leaves on its own timeout (paused while hovered) or when its
// notification closes; the list itself lives in Notifications.
PopupWindow {
    id: root

    required property PanelWindow bar
    required property PopupWindow menu

    color: "transparent"
    visible: Notifications.toasts.length > 0 && !root.menu.visible

    anchor.window: bar
    anchor.rect.x: bar.width - root.width - ShellGlobals.barGap
    anchor.rect.y: bar.height

    implicitWidth: 360
    implicitHeight: Math.max(1, stack.implicitHeight)

    Column {
        id: stack
        width: parent.width
        spacing: 6

        Repeater {
            model: ScriptModel {
                values: Notifications.toasts
            }

            delegate: NotificationEntry {
                id: toast
                required property var modelData

                width: stack.width
                notif: toast.modelData

                NumberAnimation on opacity {
                    from: 0
                    to: 1
                    duration: ShellGlobals.animSlow
                }

                HoverHandler {
                    id: hover
                }

                // Restarts from the full timeout once the pointer leaves, so a
                // toast you were reading does not vanish the instant you look away.
                Timer {
                    interval: Notifications.toastTimeout(toast.modelData)
                    running: interval > 0 && !hover.hovered
                    onTriggered: Notifications.dropToast(toast.modelData)
                }
            }
        }
    }
}

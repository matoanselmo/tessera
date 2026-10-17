import QtQuick
import Quickshell
import qs
import qs.components
import qs.services

// Stack of toasts hanging below the bar's right edge, newest at the bottom.
// Each leaves on its own timeout (paused while hovered) or when its
// notification closes; the list itself lives in Notifications.
PopupWindow {
    id: root

    required property PanelWindow bar
    required property PopupWindow menu

    color: "transparent"
    // Held up briefly after the last toast goes, so its exit can play.
    visible: (Notifications.toasts.length > 0 || linger.running) && !root.menu.visible

    anchor.window: bar
    anchor.rect.x: bar.width - root.width - ShellGlobals.barGap
    anchor.rect.y: bar.height

    implicitWidth: 360
    // Grows at once so an arriving toast has room; shrinks only as the stack
    // below glides up, so nothing is cut off mid-motion.
    implicitHeight: Math.max(1, list.contentHeight, root.trailingHeight)

    property real trailingHeight: list.contentHeight

    Behavior on trailingHeight {
        Anim {}
    }

    Connections {
        target: Notifications

        function onToastsChanged() {
            if (Notifications.toasts.length === 0)
                linger.restart();
        }
    }

    Timer {
        id: linger
        interval: ShellGlobals.animNormal * ShellGlobals.motionScale
    }

    ListView {
        id: list

        width: parent.width
        height: Math.max(1, list.contentHeight)
        interactive: false
        // At most four toasts: build them all, whatever the current height.
        cacheBuffer: 2000
        spacing: 6

        model: ScriptModel {
            values: Notifications.toasts
        }

        // Toasts slide in from the screen edge they hang off, and back out.
        add: Transition {
            Anim {
                property: "x"
                from: 40
                to: 0
                time: ShellGlobals.animSlow
            }
            Anim {
                property: "opacity"
                from: 0
                to: 1
                time: ShellGlobals.animSlow
            }
        }

        remove: Transition {
            Anim {
                property: "x"
                to: 40
                curve: ShellGlobals.easeIn
            }
            Anim {
                property: "opacity"
                to: 0
                curve: ShellGlobals.easeIn
            }
        }

        displaced: Transition {
            Anim {
                property: "y"
            }
            // An add or remove interrupted midway can leave a toast faded.
            Anim {
                property: "opacity"
                to: 1
            }
        }

        delegate: NotificationEntry {
            id: toast
            required property var modelData

            width: list.width
            notif: toast.modelData

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

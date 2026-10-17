import QtQuick
import Quickshell
import qs

PopupWindow {
    id: root

    required property PanelWindow bar
    required property PopupWindow menu

    visible: false
    color: "transparent"

    anchor.window: bar
    anchor.rect.x: bar.width - root.width - ShellGlobals.barGap
    anchor.rect.y: bar.height

    implicitWidth: 360
    implicitHeight: popup.implicitHeight

    NotificationEntry {
        id: popup
        width: parent.width
        height: implicitHeight
        notif: null
        opacity: 0

        Behavior on opacity {
            NumberAnimation {
                duration: ShellGlobals.animSlow
            }
        }

        onOpacityChanged: {
            if (popup.opacity == 0)
                root.visible = false;
        }
    }

    Timer {
        id: timer
        interval: 3000
        onTriggered: popup.opacity = 0
    }

    // Declarative, rather than hand-wiring signals in Component.onCompleted.
    Connections {
        target: NotifServer.notifServer

        function onNotification(n) {
            if (ShellGlobals.isDnd)
                return;

            popup.notif = n;
            popup.opacity = 1;
            root.visible = true;
            timer.restart();
        }
    }

    Connections {
        target: root.menu

        function onVisibleChanged() {
            if (root.menu.visible)
                root.visible = false;
        }
    }
}

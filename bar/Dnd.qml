import QtQuick
import qs
import qs.services

BarWidget {
    icon: Notifications.dnd ? "notifications_off" : "notifications_active"
    color: ShellGlobals.materialColors.primarycontainer
    foreground: ShellGlobals.materialColors.onprimarycontainer

    interactive: true
    onClicked: Notifications.setDnd(!Notifications.dnd)
}

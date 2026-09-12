import QtQuick
import qs

BarWidget {
    icon: ShellGlobals.isDnd ? "notifications_off" : "notifications_active"
    color: ShellGlobals.materialColors.primarycontainer
    foreground: ShellGlobals.materialColors.onprimarycontainer

    interactive: true
    onClicked: ShellGlobals.isDnd = !ShellGlobals.isDnd
}

import QtQuick
import qs
import qs.services

// Connection type and strength; opens the network panel.
BarWidget {
    id: root

    signal toggleRequested

    icon: Internet.icon
    color: ShellGlobals.materialColors.tertiarycontainer
    foreground: ShellGlobals.materialColors.ontertiarycontainer

    interactive: true
    tooltip: Internet.summary
    onClicked: root.toggleRequested()
}

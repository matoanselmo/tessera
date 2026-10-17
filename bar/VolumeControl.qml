import QtQuick
import qs
import qs.services

BarWidget {
    id: root

    signal toggleRequested

    icon: Audio.icon
    label: Audio.muted ? "off" : `${Audio.percent}%`
    tooltip: Audio.sink?.description ?? "No output device"
    color: ShellGlobals.materialColors.tertiarycontainer
    foreground: ShellGlobals.materialColors.ontertiarycontainer

    interactive: true
    onClicked: root.toggleRequested()
    onScrolled: delta => Audio.nudge(delta > 0 ? 0.05 : -0.05)
}

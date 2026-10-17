import QtQuick
import qs
import qs.services

BarWidget {
    id: root

    signal toggleRequested

    icon: {
        if (Audio.muted || Audio.percent === 0)
            return "volume-muted.svg";
        if (Audio.percent < 34)
            return "volume-low.svg";
        if (Audio.percent < 67)
            return "volume-medium.svg";

        return "volume-high.svg";
    }

    label: Audio.muted ? "off" : `${Audio.percent}%`
    tooltip: Audio.sink?.description ?? "No output device"
    color: ShellGlobals.materialColors.tertiarycontainer
    foreground: ShellGlobals.materialColors.ontertiarycontainer

    interactive: true
    onClicked: root.toggleRequested()
    onScrolled: delta => Audio.nudge(delta > 0 ? 0.05 : -0.05)
}

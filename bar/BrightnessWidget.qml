import QtQuick
import qs
import qs.services

// The screen's backlight level; only on machines that have one. Scrolling
// adjusts it, clicking opens the brightness panel.
BarWidget {
    id: root

    signal toggleRequested

    present: Brightness.available
    icon: "brightness.svg"
    label: `${Brightness.percent}%`
    tooltip: Brightness.available ? `Brightness ${Brightness.percent}% · scroll to adjust` : ""
    color: ShellGlobals.materialColors.tertiarycontainer
    foreground: ShellGlobals.materialColors.ontertiarycontainer

    interactive: true
    onClicked: root.toggleRequested()
    onScrolled: delta => Brightness.nudge(delta > 0 ? Brightness.step : -Brightness.step)
}

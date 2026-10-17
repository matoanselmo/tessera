import QtQuick
import Quickshell
import qs
import qs.services

// SystemClock only wakes on the boundary we actually render, instead of the
// old 1Hz timer that reformatted the string 60 times per visible change.
BarWidget {
    id: root

    signal toggleRequested

    icon: "clock"
    badge: Media.playing ? "music.svg" : ""
    label: Qt.formatDateTime(clock.date, "HH:mm")
    color: root.hovered ? ShellGlobals.materialColors.surfacebright : ShellGlobals.materialColors.tertiary
    foreground: ShellGlobals.materialColors.ontertiary

    interactive: true
    tooltip: Qt.formatDateTime(clock.date, "dddd, d MMMM yyyy")
    onClicked: root.toggleRequested()

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }
}

import QtQuick
import Quickshell
import Quickshell.Services.Mpris
import qs

// SystemClock only wakes on the boundary we actually render, instead of the
// old 1Hz timer that reformatted the string 60 times per visible change.
BarWidget {
    id: root

    signal toggleRequested

    icon: "clock"
    badge: Mpris.players.values.some(p => p.isPlaying) ? "music.svg" : ""
    label: Qt.formatDateTime(clock.date, "HH:mm")
    color: root.hovered ? ShellGlobals.materialColors.surfacebright : ShellGlobals.materialColors.tertiary
    foreground: ShellGlobals.materialColors.ontertiary

    interactive: true
    onClicked: root.toggleRequested()

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }
}

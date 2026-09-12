import QtQuick
import Quickshell
import qs

// SystemClock only wakes on the boundary we actually render, instead of the
// old 1Hz timer that reformatted the string 60 times per visible change.
BarWidget {
    icon: "clock"
    label: Qt.formatDateTime(clock.date, "HH:mm")
    color: ShellGlobals.materialColors.tertiary
    foreground: ShellGlobals.materialColors.ontertiary

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }
}

import QtQuick
import qs
import qs.services

BarWidget {
    icon: "cpu"
    label: `${SystemStats.cpuPercent}%`
    tooltip: "CPU usage"
    color: ShellGlobals.materialColors.primary
    foreground: ShellGlobals.materialColors.onprimary
}

import QtQuick
import qs
import qs.services

import "../services/Procs.js" as Procs

// Hovering lists the five busiest processes; clicking opens the system
// monitor, sorted by CPU.
BarWidget {
    id: root

    icon: "cpu"
    label: `${SystemStats.cpuPercent}%`
    tooltip: SystemStats.topCpu.length > 0 ? `CPU usage ${SystemStats.cpuPercent}%\n\n${Procs.listing(SystemStats.topCpu, "cpu")}` : `CPU usage ${SystemStats.cpuPercent}%`
    tooltipMono: true
    color: ShellGlobals.materialColors.primary
    foreground: ShellGlobals.materialColors.onprimary

    interactive: true

    onHoveredChanged: SystemStats.peek(root.hovered)
    Component.onDestruction: {
        if (root.hovered)
            SystemStats.peek(false);
    }
}

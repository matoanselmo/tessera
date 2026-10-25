import QtQuick
import qs
import qs.components
import qs.services

import "../services/Procs.js" as Procs

// Hovering lists the five processes holding the most memory; clicking opens
// the system monitor, sorted by memory.
BarWidget {
    id: root

    icon: "memory"
    label: `${SystemStats.memPercent}%`
    readonly property string summary: `Memory: ${(SystemStats.memUsed / 1048576).toFixed(1)} of ${(SystemStats.memTotal / 1048576).toFixed(1)} GiB`
    tooltip: SystemStats.topMem.length > 0 ? `${root.summary}\n\n${Procs.listing(SystemStats.topMem, "mem")}` : root.summary
    tooltipMono: true
    color: root.memCritical ? ShellGlobals.materialColors.errorcontainer : ShellGlobals.materialColors.primary
    foreground: root.memCritical ? ShellGlobals.materialColors.onerrorcontainer : ShellGlobals.materialColors.onprimary

    readonly property bool memCritical: SystemStats.memPercent >= 90

    interactive: true

    onHoveredChanged: SystemStats.peek(root.hovered)
    Component.onDestruction: {
        if (root.hovered)
            SystemStats.peek(false);
    }

    Behavior on color {
        CAnim {}
    }

    SequentialAnimation on opacity {
        running: root.memCritical
        loops: Animation.Infinite
        Anim {
            to: 0.72
            time: 420
            curve: ShellGlobals.easeInOut
        }
        Anim {
            to: 1
            time: 420
            curve: ShellGlobals.easeInOut
        }
        onStopped: root.opacity = 1
    }
}

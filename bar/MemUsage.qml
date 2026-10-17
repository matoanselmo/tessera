import QtQuick
import qs
import qs.components
import qs.services

BarWidget {
    id: root

    icon: "memory"
    label: `${SystemStats.memPercent}%`
    tooltip: `Memory: ${(SystemStats.memUsed / 1048576).toFixed(1)} of ${(SystemStats.memTotal / 1048576).toFixed(1)} GiB`
    color: root.memCritical ? ShellGlobals.materialColors.errorcontainer : ShellGlobals.materialColors.primary
    foreground: root.memCritical ? ShellGlobals.materialColors.onerrorcontainer : ShellGlobals.materialColors.onprimary

    readonly property bool memCritical: SystemStats.memPercent >= 90

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

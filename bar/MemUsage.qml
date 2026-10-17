import QtQuick
import qs
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
        ColorAnimation {
            duration: 180
        }
    }

    SequentialAnimation on opacity {
        running: root.memCritical
        loops: Animation.Infinite
        NumberAnimation {
            to: 0.72
            duration: 420
            easing.type: Easing.InOutQuad
        }
        NumberAnimation {
            to: 1
            duration: 420
            easing.type: Easing.InOutQuad
        }
        onStopped: root.opacity = 1
    }
}

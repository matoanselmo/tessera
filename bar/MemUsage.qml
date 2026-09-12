import QtQuick
import Quickshell.Io
import qs

BarWidget {
    id: root

    icon: "memory"
    label: `${root.memUsage}%`
    color: root.memCritical ? ShellGlobals.materialColors.errorcontainer : ShellGlobals.materialColors.primary
    foreground: root.memCritical ? ShellGlobals.materialColors.onerrorcontainer : ShellGlobals.materialColors.onprimary

    property int memUsage: 0
    property bool memCritical: memUsage >= 90

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

    // MemTotal minus MemAvailable is the figure that actually reflects pressure;
    // it excludes reclaimable page cache the way `free`'s used column does.
    FileView {
        id: memFile
        path: "/proc/meminfo"
        preload: true

        onLoaded: {
            let total = 0;
            let available = 0;

            for (const line of memFile.text().split("\n")) {
                if (line.startsWith("MemTotal:"))
                    total = parseInt(line.split(/\s+/)[1]) || 0;
                else if (line.startsWith("MemAvailable:"))
                    available = parseInt(line.split(/\s+/)[1]) || 0;

                if (total > 0 && available > 0)
                    break;
            }

            if (total > 0)
                root.memUsage = Math.round(100 * (total - available) / total);
        }
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        onTriggered: memFile.reload()
    }
}

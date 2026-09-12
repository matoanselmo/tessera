import QtQuick
import Quickshell.Io
import qs

BarWidget {
    id: root

    icon: "cpu"
    label: `${root.cpuUsage}%`
    color: ShellGlobals.materialColors.primary
    foreground: ShellGlobals.materialColors.onprimary

    property int cpuUsage: 0

    // These accumulate raw jiffy counters from /proc/stat, which pass 2^31 after
    // roughly three weeks of uptime on a multi-core box. They must be `real`;
    // as `int` they wrapped and the reading became permanently wrong.
    property real lastTotal: 0
    property real lastIdle: 0

    FileView {
        id: statFile
        path: "/proc/stat"
        preload: true

        onLoaded: {
            const line = statFile.text().split("\n", 1)[0];
            const parts = line.trim().split(/\s+/);
            if (parts[0] !== "cpu")
                return;

            // Fields 1..8 are user, nice, system, idle, iowait, irq, softirq,
            // steal. guest and guest_nice are already counted inside user/nice.
            let total = 0;
            for (let i = 1; i <= 8 && i < parts.length; i++)
                total += parseInt(parts[i]) || 0;

            const idleTime = (parseInt(parts[4]) || 0) + (parseInt(parts[5]) || 0);

            if (root.lastTotal > 0) {
                const totalDiff = total - root.lastTotal;
                const idleDiff = idleTime - root.lastIdle;
                if (totalDiff > 0) {
                    const pct = Math.round(100 * (totalDiff - idleDiff) / totalDiff);
                    root.cpuUsage = Math.max(0, Math.min(100, pct));
                }
            }

            root.lastTotal = total;
            root.lastIdle = idleTime;
        }
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        onTriggered: statFile.reload()
    }
}

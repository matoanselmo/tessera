pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// CPU and memory usage, sampled once for the whole shell rather than once
// per bar.
Singleton {
    id: root

    property int cpuPercent: 0
    property int memPercent: 0
    // In KiB, as /proc/meminfo reports them.
    property real memUsed: 0
    property real memTotal: 0

    readonly property int interval: 2000

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
                    root.cpuPercent = Math.max(0, Math.min(100, pct));
                }
            }

            root.lastTotal = total;
            root.lastIdle = idleTime;
        }
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

            if (total > 0) {
                root.memTotal = total;
                root.memUsed = total - available;
                root.memPercent = Math.round(100 * (total - available) / total);
            }
        }
    }

    Timer {
        interval: root.interval
        running: true
        repeat: true
        onTriggered: {
            statFile.reload();
            memFile.reload();
        }
    }
}

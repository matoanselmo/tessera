pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

import "Procs.js" as Procs

// CPU and memory usage, sampled once for the whole shell rather than once
// per bar. Also the system monitor panel's state and IPC target, and its
// process list, which is only read while something shows it: the panel, or
// a CPU or memory tooltip.
//
//     qs ipc call system toggle|open|close
Singleton {
    id: root

    property bool panelOpen: false
    // What the panel's process list is ordered by: "cpu" or "mem".
    property string sortBy: "cpu"

    property int cpuPercent: 0
    // One percentage per core (per thread, really), in /proc/stat's order.
    property var corePercents: []
    // The last `historyLength` readings of cpuPercent, oldest first.
    property var cpuHistory: []
    readonly property int historyLength: 60

    property int memPercent: 0
    // In KiB, as /proc/meminfo reports them.
    property real memUsed: 0
    property real memTotal: 0
    property real memCached: 0
    property real swapUsed: 0
    property real swapTotal: 0

    // The 1, 5 and 15 minute load averages, and seconds since boot.
    property var loadAverage: [0, 0, 0]
    property real uptime: 0

    // `{ pid, name, cpu, mem, rss }` for every process, while `sampling`.
    property var processes: []
    readonly property var topCpu: Procs.top(root.processes, "cpu", 5)
    readonly property var topMem: Procs.top(root.processes, "mem", 5)

    // Hovered CPU and memory widgets, across every bar. They count themselves
    // in and out with peek().
    property int peekers: 0
    readonly property bool sampling: root.panelOpen || root.peekers > 0

    readonly property int interval: 2000

    // These accumulate raw jiffy counters from /proc/stat, which pass 2^31 after
    // roughly three weeks of uptime on a multi-core box. JS numbers are doubles,
    // so the arrays are safe; as `int` properties they wrapped and the reading
    // became permanently wrong.
    property var lastCpus: []
    property var lastProcs: null

    // Every machine Tessera runs on uses 4 KiB pages.
    readonly property int pageKiB: 4

    function peek(on: bool): void {
        root.peekers = Math.max(0, root.peekers + (on ? 1 : -1));
    }

    // SIGTERM, the polite kind: the process may clean up, or ignore it.
    function terminate(pid: int): void {
        Quickshell.execDetached(["kill", "-TERM", String(pid)]);
    }

    function percentOf(now: var, before: var): int {
        const total = now.total - before.total;
        if (total <= 0)
            return 0;
        const pct = Math.round(100 * (total - (now.idle - before.idle)) / total);
        return Math.max(0, Math.min(100, pct));
    }

    FileView {
        id: statFile
        path: "/proc/stat"
        preload: true

        onLoaded: {
            const cpus = Procs.parseCpuLines(statFile.text());
            if (cpus.length === 0)
                return;

            if (root.lastCpus.length === cpus.length) {
                root.cpuPercent = root.percentOf(cpus[0], root.lastCpus[0]);
                root.corePercents = cpus.slice(1).map((c, i) => root.percentOf(c, root.lastCpus[i + 1]));
                root.cpuHistory = root.cpuHistory.concat([root.cpuPercent]).slice(-root.historyLength);
            }

            root.lastCpus = cpus;
        }
    }

    // MemTotal minus MemAvailable is the figure that actually reflects pressure;
    // it excludes reclaimable page cache the way `free`'s used column does.
    FileView {
        id: memFile
        path: "/proc/meminfo"
        preload: true

        onLoaded: {
            const info = {};
            for (const line of memFile.text().split("\n")) {
                const [key, value] = line.split(/:\s+/);
                if (value !== undefined)
                    info[key] = parseInt(value) || 0;
            }

            const total = info.MemTotal ?? 0;
            const available = info.MemAvailable ?? 0;
            if (total > 0) {
                root.memTotal = total;
                root.memUsed = total - available;
                root.memPercent = Math.round(100 * (total - available) / total);
                root.memCached = (info.Cached ?? 0) + (info.Buffers ?? 0);
                root.swapTotal = info.SwapTotal ?? 0;
                root.swapUsed = root.swapTotal - (info.SwapFree ?? 0);
            }
        }
    }

    FileView {
        id: loadFile
        path: "/proc/loadavg"

        onLoaded: root.loadAverage = loadFile.text().split(" ").slice(0, 3).map(v => parseFloat(v) || 0)
    }

    FileView {
        id: uptimeFile
        path: "/proc/uptime"

        onLoaded: root.uptime = parseFloat(uptimeFile.text()) || 0
    }

    // One snapshot of the machine's counters and every process's, read in a
    // single pass so the CPU shares are measured over the same interval.
    // Processes that exit mid-read are simply missing.
    Process {
        id: procQuery
        command: ["sh", "-c", "cat /proc/stat /proc/[0-9]*/stat 2>/dev/null"]

        stdout: StdioCollector {
            onStreamFinished: {
                if (!root.sampling)
                    return;
                const result = Procs.sample(text, root.lastProcs, root.memTotal, root.pageKiB);
                root.lastProcs = result.state;
                root.processes = result.rows;
            }
        }
    }

    function sampleProcesses(): void {
        if (!procQuery.running)
            procQuery.running = true;
    }

    function refreshPanelFiles(): void {
        loadFile.reload();
        uptimeFile.reload();
    }

    // CPU shares need two snapshots, so a fresh look takes one straight away
    // and another shortly after, in time for the tooltip's delay, instead of
    // showing nothing for a whole interval.
    onSamplingChanged: {
        if (root.sampling) {
            root.sampleProcesses();
            root.refreshPanelFiles();
            followUp.restart();
        } else {
            followUp.stop();
            root.lastProcs = null;
            root.processes = [];
        }
    }

    Timer {
        id: followUp
        interval: 450
        onTriggered: root.sampleProcesses()
    }

    Timer {
        interval: root.interval
        running: true
        repeat: true
        onTriggered: {
            statFile.reload();
            memFile.reload();
            if (root.sampling) {
                root.sampleProcesses();
                root.refreshPanelFiles();
            }
        }
    }

    IpcHandler {
        target: "system"

        function toggle(): void {
            root.panelOpen = !root.panelOpen;
        }

        function open(): void {
            root.panelOpen = true;
        }

        function close(): void {
            root.panelOpen = false;
        }
    }
}

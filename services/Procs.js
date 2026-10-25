.pragma library

// Parsing for the process list behind the system monitor. Kept free of QML so
// tests/run.sh can exercise it.

// The aggregate and per-core lines of /proc/stat, as `{ total, idle }` jiffy
// counts: index 0 is the whole machine, 1.. are the cores in order. Fields
// 1..8 are user, nice, system, idle, iowait, irq, softirq, steal; guest and
// guest_nice are already counted inside user and nice.
function parseCpuLines(text) {
    const cpus = [];
    for (const line of text.split("\n")) {
        if (!line.startsWith("cpu"))
            continue;
        const parts = line.trim().split(/\s+/);
        let total = 0;
        for (let i = 1; i <= 8 && i < parts.length; i++)
            total += parseInt(parts[i]) || 0;
        const idle = (parseInt(parts[4]) || 0) + (parseInt(parts[5]) || 0);
        cpus.push({ total, idle });
    }
    return cpus;
}

// One /proc/<pid>/stat line into `{ pid, ppid, name, ticks, rss }`, or null. The
// name sits in parentheses and may itself hold spaces or parentheses, so the
// fields after it are found from the last ')'. `ticks` is utime + stime in
// jiffies, `rss` is resident pages.
function parseProcStat(line) {
    const open = line.indexOf("(");
    const close = line.lastIndexOf(")");
    if (open < 0 || close < open)
        return null;

    const pid = parseInt(line.slice(0, open));
    if (!(pid > 0))
        return null;

    // After ')': state is field 3, so field n sits at index n - 3.
    const rest = line.slice(close + 2).split(" ");
    const ticks = (parseInt(rest[11]) || 0) + (parseInt(rest[12]) || 0);
    const rss = parseInt(rest[21]) || 0;
    const ppid = parseInt(rest[1]) || 0;

    return { pid, ppid, name: line.slice(open + 1, close), ticks, rss };
}

// Turns one snapshot (`cat /proc/stat /proc/[0-9]*/stat`) into process rows,
// given the previous snapshot's `{ total, ticks }` (ticks keyed by pid). Each
// row is `{ pid, ppid, name, cpu, mem, rss }`: cpu as a percentage of the whole
// machine (btop's default), mem as a percentage of `memTotalKiB`, rss in KiB.
// A process new since the last snapshot reads 0% CPU until the next one.
//
// Returns `{ rows, state }`; hand `state` back in next time.
function sample(text, previous, memTotalKiB, pageKiB) {
    const lines = text.split("\n");
    const machine = parseCpuLines(lines.filter(l => l.startsWith("cpu ")).join("\n"))[0];
    const total = machine ? machine.total : 0;
    const elapsed = previous && total > previous.total ? total - previous.total : 0;

    const ticks = {};
    const rows = [];
    for (const line of lines) {
        if (line === "" || line.startsWith("cpu") || !/^\d/.test(line))
            continue;
        const p = parseProcStat(line);
        if (!p)
            continue;

        ticks[p.pid] = p.ticks;
        const before = previous ? previous.ticks[p.pid] : undefined;
        const used = elapsed > 0 && before !== undefined ? Math.max(0, p.ticks - before) : 0;
        const rss = p.rss * pageKiB;

        rows.push({
            pid: p.pid,
            ppid: p.ppid,
            name: p.name,
            cpu: elapsed > 0 ? 100 * used / elapsed : 0,
            mem: memTotalKiB > 0 ? 100 * rss / memTotalKiB : 0,
            rss
        });
    }

    return { rows, state: { total, ticks } };
}

// What a session's processes hang from rather than belong to: init, the
// systemd user manager, the compositor, display managers, and the shell
// itself (Tessera launches apps). An app is the topmost process below one
// of these.
const SESSION = ["systemd", "niri", "sway", "greetd", ".quickshell-wra", "quickshell", "qs", "kthreadd"];

// Nix wraps binaries, so `zen` runs as `.zen-wrapped`; comm also cuts names
// at 15 characters (`.quickshell-wra`). Both read better without it.
function appName(comm) {
    if (!comm.startsWith("."))
        return comm;
    return comm.slice(1).replace(/-w(r(a(p(p(e(d)?)?)?)?)?)?$/, "") || comm;
}

// Folds process rows into one row per app, in the same shape plus `count`.
// A process belongs to the app at the top of its ancestry below the
// session (see SESSION): Zen's content processes to Zen, a shell and what
// runs in it to its terminal. The row keeps the app's own pid, so ending it
// ends the app; cpu, mem and rss are summed.
function group(rows) {
    const byPid = {};
    for (const r of rows)
        byPid[r.pid] = r;

    const isRoot = r => !r || r.pid <= 1 || SESSION.includes(r.name);
    const appOf = {};
    const findApp = r => {
        if (appOf[r.pid] !== undefined)
            return appOf[r.pid];
        let app = r;
        // Bounded, in case a snapshot taken mid-fork holds a cycle.
        for (let i = 0; i < 64; i++) {
            const parent = byPid[app.ppid];
            if (isRoot(parent))
                break;
            app = parent;
        }
        return appOf[r.pid] = app.pid;
    };

    const apps = {};
    for (const r of rows) {
        // The session's own processes stand alone.
        const pid = isRoot(r) ? r.pid : findApp(r);
        if (!apps[pid]) {
            apps[pid] = {
                pid,
                ppid: byPid[pid].ppid,
                name: appName(byPid[pid].name),
                cpu: 0,
                mem: 0,
                rss: 0,
                count: 0
            };
        }
        const app = apps[pid];
        app.cpu += r.cpu;
        app.mem += r.mem;
        app.rss += r.rss;
        app.count += 1;
    }
    return Object.values(apps);
}

// The `n` heaviest rows by `key` ("cpu" or "mem"), ties broken by the other.
function top(rows, key, n) {
    const other = key === "cpu" ? "rss" : "cpu";
    const by = key === "cpu" ? "cpu" : "rss";
    return rows.slice().sort((a, b) => (b[by] - a[by]) || (b[other] - a[other]) || (a.pid - b.pid)).slice(0, n);
}

// KiB as `512K`, `412M` or `1.2G`, the way btop and top print memory.
function size(kib) {
    if (kib >= 1048576)
        return `${(kib / 1048576).toFixed(1)}G`;
    if (kib >= 1024)
        return `${Math.round(kib / 1024)}M`;
    return `${Math.round(kib)}K`;
}

// A text meter, `██████░░░░`, `width` cells long for a 0-100 value.
function bar(percent, width) {
    const filled = Math.round(Math.max(0, Math.min(100, percent)) / 100 * width);
    return "█".repeat(filled) + "░".repeat(width - filled);
}

// The tooltip's process lines: name, then the figure it is ranked by, in
// columns for a monospace font. `zen-beta          12.3%` or
// `zen-beta     1.2G   7.8%`.
function listing(rows, key) {
    return rows.map(r => {
        const name = r.name.length > 16 ? r.name.slice(0, 15) + "…" : r.name.padEnd(16);
        const figure = key === "cpu" ? `${r.cpu.toFixed(1)}%`.padStart(7) : `${size(r.rss).padStart(6)} ${`${r.mem.toFixed(1)}%`.padStart(6)}`;
        return `${name} ${figure}`;
    }).join("\n");
}

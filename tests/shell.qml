import Quickshell
import QtQuick

// Run with tests/run.sh, which copies this next to the files under test.
import "launcher/Calculator.js" as Calculator
import "launcher/Fuzzy.js" as Fuzzy
import "launcher/WebSearch.js" as WebSearch
import "launcher/Emoji.js" as Emoji
import "keybinds/parse.js" as Parse
import "services/Nmcli.js" as Nmcli
import "services/Procs.js" as Procs
import "settings/clocks.js" as Clocks

Scope {
    id: root

    function eq(name: string, actual: var, expected: var): void {
        const a = JSON.stringify(actual);
        const e = JSON.stringify(expected);
        console.warn(a === e ? `PASS ${name}` : `FAIL ${name}: expected ${e}, got ${a}`);
    }

    function calculator(): void {
        const thin = " ";
        root.eq("calc: arithmetic", Calculator.evaluate("2+3*4"), { display: "14", copy: "14" });
        root.eq("calc: groups digits, copies them plain", Calculator.evaluate("1000*1000"), { display: `1${thin}000${thin}000`, copy: "1000000" });
        root.eq("calc: float noise trimmed", Calculator.evaluate("0.1+0.2")?.display, "0.3");
        root.eq("calc: thousands separator", Calculator.evaluate("1,000 + 1")?.copy, "1001");
        root.eq("calc: implicit multiplication", Calculator.evaluate("2(3+4)")?.copy, "14");
        root.eq("calc: paren-less function", Calculator.evaluate("sqrt 16")?.copy, "4");
        root.eq("calc: function missing from old pre-filter", Calculator.evaluate("asin 1")?.copy, "1.57079632679");
        root.eq("calc: two-argument function", Calculator.evaluate("atan2(1,1)")?.copy, "0.785398163397");
        root.eq("calc: negative result", Calculator.evaluate("-5*3")?.copy, "-15");
        root.eq("calc: app name is not maths", Calculator.evaluate("firefox"), null);
        root.eq("calc: bare constant is not maths", Calculator.evaluate("e"), null);
        root.eq("calc: function name alone", Calculator.evaluate("exp"), null);
    }

    function fuzzy(): void {
        const apps = ["File Roller", "Firefox", "Files", "Terminal", "Fire Alarm", "Office", "Foot"];
        const name = a => a;
        const boost = { "Foot": 20, "File Roller": 8 };
        const used = a => boost[a] ?? 0;

        root.eq("fuzzy: subsequence filter", Fuzzy.rank("ff", apps, name), ["Office", "Firefox"]);
        root.eq("fuzzy: no match", Fuzzy.rank("zz", apps, name), []);
        root.eq("fuzzy: longest first run wins", Fuzzy.rank("fire", apps, name)[0], "Firefox");
        root.eq("fuzzy: usage orders an empty query", Fuzzy.rank("", apps, name, used).slice(0, 2), ["Foot", "File Roller"]);
        root.eq("fuzzy: usage breaks ties", Fuzzy.rank("f", apps, name, used).slice(0, 2), ["Foot", "File Roller"]);
        root.eq("fuzzy: usage never beats a better match", Fuzzy.rank("fire", apps, name, used).slice(0, 2), ["Firefox", "Fire Alarm"]);
    }

    function webSearch(): void {
        const engine = "https://example.org/?q=%s";
        const act = q => {
            const a = WebSearch.actionFor(q, engine, "Example");
            return a ? [a.kind, a.url] : null;
        };

        root.eq("web: bare domain opens", act("example.com"), ["open", "https://example.com"]);
        root.eq("web: scheme kept", act("http://a.b/c"), ["open", "http://a.b/c"]);
        root.eq("web: localhost uses http", act("localhost:8080"), ["open", "http://localhost:8080"]);
        root.eq("web: filename is a search", act("config.qml"), ["search", "https://example.org/?q=config.qml"]);
        root.eq("web: words are encoded", act("a b&c"), ["search", "https://example.org/?q=a%20b%26c"]);
        root.eq("web: empty query", act("   "), null);
    }

    function emoji(): void {
        const named = n => Emoji.list.find(e => e[1] === n)?.[0];
        root.eq("emoji: table loads", Emoji.list.length > 1000, true);
        root.eq("emoji: names are lower case", Emoji.list.every(e => e[1] === e[1].toLowerCase()), true);
        root.eq("emoji: pictograph", named("fire"), "\u{1F525}");
        root.eq("emoji: classic symbol kept", named("hot beverage"), "\u2615");
        root.eq("emoji: skin tones skipped", Emoji.list.some(e => e[1].startsWith("emoji modifier")), false);
    }

    function keybinds(): void {
        const src = `
            input { keyboard { numlock; } }
            binds {
                // A comment, and a commented-out bind below.
                /-Mod+X { spawn "nope"; }
                Mod+Return hotkey-overlay-title="Terminal: foot" { spawn "foot"; }
                Mod+Q { close-window; }
                Mod+1 { focus-workspace 1; }
                Mod+2 { focus-workspace 2; }
                Mod+3 { focus-workspace 3; }
                Mod+H hotkey-overlay-title=null { focus-column-left; }
                /* block comment { with braces } */
                XF86AudioMute { spawn-sh "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"; }
            }`;
        const rows = Parse.parseBinds(src);

        root.eq("binds: hidden and commented binds dropped", rows.length, 4);
        root.eq("binds: grouped by category in order", rows.map(r => r.category), ["Apps & shell", "Windows", "Workspaces", "Media"]);
        root.eq("binds: overlay title wins", rows[0].text, "Terminal: foot");
        root.eq("binds: keys formatted", rows[0].keys, ["Super", "Enter"]);
        root.eq("binds: action described", rows[1].text, "Close window");
        root.eq("binds: digit run collapsed", [rows[2].keys, rows[2].text], [["Super", "1–3"], "Focus workspace 1–3"]);
        root.eq("binds: XF86 key named", rows[3].keys, ["Audio Mute"]);
        root.eq("binds: filter adds headers", Parse.filterRows(rows, "close").map(r => r.text), ["Windows", "Close window"]);
    }

    function nmcli(): void {
        root.eq("nmcli: plain fields", Nmcli.splitTerse("enp7s0:ethernet:connected:Wired 1"), ["enp7s0", "ethernet", "connected", "Wired 1"]);
        root.eq("nmcli: escaped colon in SSID", Nmcli.splitTerse("wlp8s0:wifi:connected:Cafe\\:5G"), ["wlp8s0", "wifi", "connected", "Cafe:5G"]);
        root.eq("nmcli: empty trailing field", Nmcli.splitTerse("wlp8s0:wifi:disconnected:"), ["wlp8s0", "wifi", "disconnected", ""]);
    }

    function procs(): void {
        // utime 300, stime 100, rss 2048 pages; the name has a space and a ')'.
        const line = "42 (Web Content) x) S 1 42 42 0 -1 4194560 0 0 0 0 300 100 0 0 20 0 1 0 100 0 2048 0";
        root.eq("procs: stat line", Procs.parseProcStat(line), { pid: 42, ppid: 1, name: "Web Content) x", ticks: 400, rss: 2048 });
        root.eq("procs: garbage line", Procs.parseProcStat("nonsense"), null);
        root.eq("procs: cpu lines", Procs.parseCpuLines("cpu  10 0 10 70 10 0 0 0 0 0\ncpu0 5 0 5 35 5 0 0 0 0 0\nintr 1"), [{ total: 100, idle: 80 }, { total: 50, idle: 40 }]);

        const proc = (pid, ticks, rss) => `${pid} (p${pid}) S 1 1 1 0 -1 0 0 0 0 0 ${ticks} 0 0 0 20 0 1 0 1 0 ${rss} 0`;
        const first = Procs.sample(`cpu  100 0 0 900 0 0 0 0\n${proc(1, 50, 256)}\n${proc(2, 10, 0)}`, null, 4096, 4);
        root.eq("procs: first sample has no cpu yet", first.rows.map(r => r.cpu), [0, 0]);
        root.eq("procs: memory share", first.rows[0].mem, 25);

        const second = Procs.sample(`cpu  200 0 0 1000 0 0 0 0\n${proc(1, 100, 256)}\n${proc(2, 30, 0)}\n${proc(3, 99, 0)}`, first.state, 4096, 4);
        root.eq("procs: cpu share of the interval", second.rows.map(r => r.cpu), [25, 10, 0]);
        root.eq("procs: top by cpu", Procs.top(second.rows, "cpu", 2).map(r => r.pid), [1, 2]);
        root.eq("procs: top by mem", Procs.top(second.rows, "mem", 1).map(r => r.pid), [1]);
        root.eq("procs: sizes", [Procs.size(512), Procs.size(421888), Procs.size(1258291)], ["512K", "412M", "1.2G"]);
        root.eq("procs: meter", Procs.bar(50, 4), "██░░");

        // systemd(1) > niri(10) > zen(20) > content(21, 22) ; niri > foot(30) > fish(31) > btop(32)
        const row = (pid, ppid, name, cpu, rss) => ({ pid, ppid, name, cpu, mem: 0, rss });
        const tree = [row(1, 0, "systemd", 0, 10), row(10, 1, "niri", 2, 100), row(20, 10, ".zen-wrapped", 5, 300),
                      row(21, 20, "Isolated Web Co", 10, 200), row(22, 20, "Web Content", 1, 100),
                      row(30, 10, "foot", 1, 20), row(31, 30, "fish", 0, 10), row(32, 31, "btop", 3, 5)];
        const apps = Procs.group(tree);
        const app = name => apps.find(a => a.name === name);
        root.eq("procs: app takes its children", [app("zen")?.count, app("zen")?.cpu, app("zen")?.rss, app("zen")?.pid], [3, 16, 600, 20]);
        root.eq("procs: terminal takes what runs in it", [app("foot")?.count, app("foot")?.cpu], [3, 4]);
        root.eq("procs: session processes stand alone", [app("niri")?.count, app("systemd")?.count], [1, 1]);
        root.eq("procs: wrapper names cleaned", [Procs.appName(".quickshell-wra"), Procs.appName("foo-w"), Procs.appName("zen")], ["quickshell", "foo-w", "zen"]);
    }

    function clocks(): void {
        root.eq("clocks: half-hour offset", Clocks.parse("Yangon +6:30"), { name: "Yangon", offsetMinutes: 390 });
        root.eq("clocks: negative, city with a space", Clocks.parse("Los Angeles -8"), { name: "Los Angeles", offsetMinutes: -480 });
        root.eq("clocks: UTC prefix, no colon", Clocks.parse("Kathmandu UTC+545"), { name: "Kathmandu", offsetMinutes: 345 });
        root.eq("clocks: zero", Clocks.parse("Lisbon 0"), { name: "Lisbon", offsetMinutes: 0 });
        root.eq("clocks: no offset", Clocks.parse("Paris"), null);
        root.eq("clocks: out of range", Clocks.parse("Nowhere +15"), null);
        root.eq("clocks: format", [Clocks.format(390), Clocks.format(-180), Clocks.format(0)], ["UTC+6:30", "UTC−3", "UTC"]);
    }

    Component.onCompleted: {
        for (const suite of [root.calculator, root.fuzzy, root.webSearch, root.emoji, root.keybinds, root.nmcli, root.procs, root.clocks]) {
            try {
                suite();
            } catch (e) {
                console.warn(`FAIL ${suite.name} threw: ${e}`);
            }
        }
        console.warn("DONE");
    }
}

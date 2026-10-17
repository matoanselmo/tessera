import Quickshell
import QtQuick

// Run with tests/run.sh, which copies this next to the files under test.
import "launcher/Calculator.js" as Calculator
import "launcher/Fuzzy.js" as Fuzzy
import "launcher/WebSearch.js" as WebSearch
import "keybinds/parse.js" as Parse
import "services/Nmcli.js" as Nmcli

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

    Component.onCompleted: {
        for (const suite of [root.calculator, root.fuzzy, root.webSearch, root.keybinds, root.nmcli]) {
            try {
                suite();
            } catch (e) {
                console.warn(`FAIL ${suite.name} threw: ${e}`);
            }
        }
        console.warn("DONE");
    }
}

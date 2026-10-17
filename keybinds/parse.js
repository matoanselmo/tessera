.pragma library

// Reads the `binds { }` block out of a niri config.kdl and turns it into rows
// for the keybinds menu. This is not a KDL parser: it only understands enough
// (strings, comments, braces, slashdash) to walk the bind nodes reliably.

const categoryOrder = ["Apps & shell", "Windows", "Workspaces", "Media", "Screenshots", "System"];

const keyNames = {
    Mod: "Super",
    Super: "Super",
    Win: "Super",
    Ctrl: "Ctrl",
    Control: "Ctrl",
    Shift: "Shift",
    Alt: "Alt",
    ISO_Level3_Shift: "AltGr",
    Return: "Enter",
    Escape: "Esc",
    BackSpace: "Backspace",
    Left: "←",
    Right: "→",
    Up: "↑",
    Down: "↓",
    Page_Up: "PgUp",
    Page_Down: "PgDn",
    Minus: "-",
    Equal: "=",
    Comma: ",",
    Period: ".",
    Slash: "/",
    Print: "PrtSc",
    WheelScrollUp: "Scroll ↑",
    WheelScrollDown: "Scroll ↓",
    WheelScrollLeft: "Scroll ←",
    WheelScrollRight: "Scroll →",
    TouchpadScrollUp: "Touchpad ↑",
    TouchpadScrollDown: "Touchpad ↓",
    TouchpadScrollLeft: "Touchpad ←",
    TouchpadScrollRight: "Touchpad →",
    MouseLeft: "Mouse left",
    MouseRight: "Mouse right",
    MouseMiddle: "Mouse middle",
    MouseBack: "Mouse back",
    MouseForward: "Mouse forward"
};

function stripComments(src) {
    let out = "";
    let i = 0;
    while (i < src.length) {
        const c = src[i];
        if (c === '"') {
            const end = stringEnd(src, i);
            out += src.slice(i, end);
            i = end;
        } else if (c === "/" && src[i + 1] === "/") {
            while (i < src.length && src[i] !== "\n")
                i++;
        } else if (c === "/" && src[i + 1] === "*") {
            const end = src.indexOf("*/", i + 2);
            i = end < 0 ? src.length : end + 2;
        } else {
            out += c;
            i++;
        }
    }
    return out;
}

// Index just past the closing quote of the string opening at `start`.
function stringEnd(src, start) {
    let i = start + 1;
    while (i < src.length && src[i] !== '"') {
        if (src[i] === "\\")
            i++;
        i++;
    }
    return i + 1;
}

function unquote(token) {
    if (token[0] !== '"')
        return token;
    try {
        return JSON.parse(token);
    } catch (e) {
        return token.slice(1, -1);
    }
}

function formatKey(part) {
    if (keyNames[part])
        return keyNames[part];
    if (part.indexOf("XF86") === 0)
        return part.slice(4).replace(/([a-z])([A-Z])/g, "$1 $2");
    return part.length === 1 ? part.toUpperCase() : part;
}

function describe(action, args) {
    if (action === "spawn") {
        const argv = args[0] === "sh" && args[1] === "-c" ? args.slice(2) : args;
        return "Run " + argv.join(" ");
    }
    if (action === "spawn-sh")
        return "Run " + args.join(" ");

    const text = [action.split("-").join(" ")].concat(args.filter(a => a.indexOf("=") < 0)).join(" ");
    return text[0].toUpperCase() + text.slice(1);
}

function categorize(key, action, args) {
    const cmd = args.join(" ");
    if (/XF86(Audio|MonBrightness)/.test(key) || /wpctl|playerctl|pactl|brightnessctl/.test(cmd))
        return "Media";
    if (action.indexOf("screenshot") === 0)
        return "Screenshots";
    if (action === "spawn" || action === "spawn-sh")
        return "Apps & shell";
    if (/workspace|overview/.test(action))
        return "Workspaces";
    if (/window|column|fullscreen|maximize|floating|tiling|center|consume|expel|tabbed/.test(action))
        return "Windows";
    return "System";
}

// Splits the body of the binds node into its child nodes' header and body text.
function bindNodes(src) {
    const open = /(^|\n)\s*binds\s*\{/.exec(src);
    if (!open)
        return [];

    const nodes = [];
    let header = "";
    let body = "";
    let depth = 0;

    for (let i = open.index + open[0].length; i < src.length; i++) {
        const c = src[i];
        if (c === '"') {
            const end = stringEnd(src, i);
            if (depth === 0)
                header += src.slice(i, end);
            else
                body += src.slice(i, end);
            i = end - 1;
        } else if (c === "{") {
            if (depth > 0)
                body += c;
            depth++;
        } else if (c === "}") {
            if (depth === 0)
                break;
            depth--;
            if (depth === 0) {
                nodes.push({
                    header: header.trim(),
                    body: body.trim()
                });
                header = "";
                body = "";
            } else {
                body += c;
            }
        } else if (depth === 0) {
            header += c;
        } else {
            body += c;
        }
    }
    return nodes;
}

function parseNode(node) {
    if (node.header === "" || node.header.indexOf("/-") === 0)
        return null;

    const key = node.header.split(/\s+/)[0];
    let title = undefined;
    const attr = /hotkey-overlay-title=("(?:[^"\\]|\\.)*"|\S+)/.exec(node.header);
    if (attr) {
        // niri hides binds titled null from its own overlay; do the same.
        if (attr[1] === "null" || attr[1] === "#null")
            return null;
        title = unquote(attr[1]);
    }

    const tokens = node.body.match(/"(?:[^"\\]|\\.)*"|;|[^\s;"]+/g) || [];
    const end = tokens.indexOf(";");
    const words = (end < 0 ? tokens : tokens.slice(0, end)).map(unquote);
    if (words.length === 0 || words[0].indexOf("/-") === 0)
        return null;

    const action = words[0];
    const args = words.slice(1);
    const parts = key.split("+");

    return {
        mods: parts.slice(0, -1).map(formatKey),
        key: parts[parts.length - 1],
        action: action,
        args: args,
        title: title,
        category: categorize(key, action, args)
    };
}

// Mod+1 .. Mod+0 style runs become one row each, e.g. "Super 1–0".
function collapseDigits(binds) {
    const out = [];
    for (const b of binds) {
        const numeric = /^[0-9]$/.test(b.key) && b.args.length === 1 && /^[0-9]+$/.test(b.args[0]) && !b.title;
        const prev = out[out.length - 1];
        if (numeric && prev && prev.run && prev.action === b.action && prev.mods.join("+") === b.mods.join("+")) {
            prev.run.push(b);
            continue;
        }
        out.push(numeric ? Object.assign({
            run: [b]
        }, b) : b);
    }
    return out;
}

function toRow(b) {
    if (b.run && b.run.length > 2) {
        const first = b.run[0];
        const last = b.run[b.run.length - 1];
        return {
            header: false,
            category: b.category,
            keys: b.mods.concat([first.key + "–" + last.key]),
            text: describe(b.action, [first.args[0] + "–" + last.args[0]])
        };
    }
    return {
        header: false,
        category: b.category,
        keys: b.mods.concat([formatKey(b.key)]),
        text: b.title !== undefined ? b.title : describe(b.action, b.args)
    };
}

function parseBinds(src) {
    const binds = bindNodes(stripComments(src)).map(parseNode).filter(b => b !== null);

    let rows = [];
    for (const b of collapseDigits(binds)) {
        if (b.run && b.run.length <= 2)
            rows = rows.concat(b.run.map(toRow));
        else
            rows.push(toRow(b));
    }

    // Stable: config order is kept inside each category.
    return rows.map((r, i) => ({
        r: r,
        i: i
    })).sort((a, b) => categoryOrder.indexOf(a.r.category) - categoryOrder.indexOf(b.r.category) || a.i - b.i).map(e => e.r);
}

// Adds a header row before each category, keeping only rows matching `query`.
function filterRows(rows, query) {
    const words = query.toLowerCase().split(/\s+/).filter(w => w !== "");
    const out = [];
    let lastCategory = "";

    for (const r of rows) {
        const hay = (r.text + " " + r.keys.join(" ") + " " + r.category).toLowerCase();
        if (!words.every(w => hay.indexOf(w) >= 0))
            continue;
        if (r.category !== lastCategory) {
            out.push({
                header: true,
                text: r.category,
                keys: []
            });
            lastCategory = r.category;
        }
        out.push(r);
    }
    return out;
}

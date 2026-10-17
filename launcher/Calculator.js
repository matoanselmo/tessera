.pragma library

// Recursive-descent arithmetic evaluator for the launcher's inline calculator.
//
// Deliberately not `eval()`: the launcher feeds it every keystroke the user
// types, so it must never run anything but arithmetic, and it must fail
// quietly on the 99% of inputs that are application names.

const CONSTANTS = {
    pi: Math.PI,
    "π": Math.PI,
    tau: Math.PI * 2,
    e: Math.E,
    inf: Infinity
};

// arity -1 means variadic.
const FUNCTIONS = {
    sin: [1, Math.sin],
    cos: [1, Math.cos],
    tan: [1, Math.tan],
    asin: [1, Math.asin],
    acos: [1, Math.acos],
    atan: [1, Math.atan],
    atan2: [2, Math.atan2],
    sinh: [1, Math.sinh],
    cosh: [1, Math.cosh],
    tanh: [1, Math.tanh],
    ln: [1, Math.log],
    log: [1, Math.log10],
    log2: [1, Math.log2],
    log10: [1, Math.log10],
    exp: [1, Math.exp],
    sqrt: [1, Math.sqrt],
    cbrt: [1, Math.cbrt],
    abs: [1, Math.abs],
    sign: [1, Math.sign],
    round: [1, Math.round],
    floor: [1, Math.floor],
    ceil: [1, Math.ceil],
    trunc: [1, Math.trunc],
    pow: [2, Math.pow],
    hypot: [-1, Math.hypot],
    min: [-1, Math.min],
    max: [-1, Math.max],
    // Degree-flavoured trig, since a launcher is where you reach for it.
    sind: [1, x => Math.sin(x * Math.PI / 180)],
    cosd: [1, x => Math.cos(x * Math.PI / 180)],
    tand: [1, x => Math.tan(x * Math.PI / 180)],
    deg: [1, x => x * 180 / Math.PI],
    rad: [1, x => x * Math.PI / 180]
};

// Any function or multi-letter constant, built from the tables so a new
// entry is recognised without touching the pre-filter in `evaluate()`.
const NAMED_RE = new RegExp("\\b(?:" + Object.keys(FUNCTIONS).concat(Object.keys(CONSTANTS).filter(k => /^[a-z]{2,}$/.test(k))).join("|") + ")\\b", "i");

const NUMBER_RE = /^(?:0[xX][0-9a-fA-F]+|0[bB][01]+|(?:\d+\.?\d*|\.\d+)(?:[eE][+-]?\d+)?)/;
const IDENT_RE = /^[a-zA-Zπ][a-zA-Z0-9]*/;

function tokenize(src) {
    const tokens = [];
    let rest = src;

    while (rest.length > 0) {
        const c = rest[0];

        if (c === " " || c === "\t") {
            rest = rest.slice(1);
            continue;
        }

        // Thousands separators, but only between digits: `1,000` is a number
        // while `max(1,2)` keeps its argument separator.
        if (c === "," && /^,\d{3}(?!\d)/.test(rest) && tokens.length > 0 && tokens[tokens.length - 1].t === "num") {
            const prev = tokens[tokens.length - 1];
            prev.v = prev.v * 1000 + Number(rest.slice(1, 4));
            rest = rest.slice(4);
            continue;
        }

        let m = NUMBER_RE.exec(rest);
        if (m) {
            tokens.push({ t: "num", v: Number(m[0]) });
            rest = rest.slice(m[0].length);
            continue;
        }

        m = IDENT_RE.exec(rest);
        if (m) {
            tokens.push({ t: "ident", v: m[0] });
            rest = rest.slice(m[0].length);
            continue;
        }

        if (rest.startsWith("**")) {
            tokens.push({ t: "op", v: "^" });
            rest = rest.slice(2);
            continue;
        }

        if ("+-*/%^(),".indexOf(c) !== -1) {
            tokens.push({ t: c === "(" || c === ")" || c === "," ? c : "op", v: c });
            rest = rest.slice(1);
            continue;
        }

        if (c === "×") { tokens.push({ t: "op", v: "*" }); rest = rest.slice(1); continue; }
        if (c === "÷") { tokens.push({ t: "op", v: "/" }); rest = rest.slice(1); continue; }
        if (c === "−") { tokens.push({ t: "op", v: "-" }); rest = rest.slice(1); continue; }

        throw new Error("unexpected character");
    }

    return tokens;
}

function parse(tokens) {
    let pos = 0;

    const peek = () => tokens[pos];
    const atOp = v => peek() && peek().t === "op" && peek().v === v;

    function expect(type) {
        const tok = peek();
        if (!tok || tok.t !== type)
            throw new Error("expected " + type);
        pos++;
        return tok;
    }

    // Juxtaposition means multiplication: `2(3+4)`, `2pi`, `3 sqrt(2)`.
    function startsPrimaryAt(index) {
        const tok = tokens[index];
        if (!tok)
            return false;
        return tok.t === "num" || tok.t === "ident" || tok.t === "(";
    }

    function startsPrimary() {
        return startsPrimaryAt(pos);
    }

    function expr() {
        let left = term();
        while (atOp("+") || atOp("-")) {
            const op = tokens[pos++].v;
            const right = term();
            left = op === "+" ? left + right : left - right;
        }
        return left;
    }

    function term() {
        let left = unary();
        while (true) {
            if (atOp("*") || atOp("/") || atOp("%")) {
                const op = tokens[pos++].v;
                const right = unary();
                left = op === "*" ? left * right : op === "/" ? left / right : left % right;
            } else if (startsPrimary()) {
                left = left * unary();
            } else {
                return left;
            }
        }
    }

    function unary() {
        if (atOp("-")) { pos++; return -unary(); }
        if (atOp("+")) { pos++; return unary(); }
        return power();
    }

    function power() {
        const base = primary();
        if (atOp("^")) {
            pos++;
            return Math.pow(base, unary()); // right-associative
        }
        return base;
    }

    function primary() {
        const tok = peek();
        if (!tok)
            throw new Error("unexpected end");

        if (tok.t === "num") {
            pos++;
            return tok.v;
        }

        if (tok.t === "(") {
            pos++;
            const value = expr();
            expect(")");
            return value;
        }

        if (tok.t === "ident") {
            const name = tok.v;
            const lower = name.toLowerCase();

            if (FUNCTIONS[lower] && FUNCTIONS[lower][0] === 1 && startsPrimaryAt(pos + 1)
                && !(tokens[pos + 1] && tokens[pos + 1].t === "(")) {
                // Paren-less single-argument call: `sqrt 2`, `ln e`.
                pos++;
                return FUNCTIONS[lower][1](power());
            }

            if (tokens[pos + 1] && tokens[pos + 1].t === "(" && FUNCTIONS[lower]) {
                pos += 2;
                const args = [];
                if (!peek() || peek().t !== ")") {
                    args.push(expr());
                    while (peek() && peek().t === ",") {
                        pos++;
                        args.push(expr());
                    }
                }
                expect(")");

                const [arity, fn] = FUNCTIONS[lower];
                if (arity !== -1 && args.length !== arity)
                    throw new Error("wrong argument count");
                return fn.apply(null, args);
            }

            if (Object.prototype.hasOwnProperty.call(CONSTANTS, lower)) {
                pos++;
                return CONSTANTS[lower];
            }

            throw new Error("unknown name");
        }

        throw new Error("unexpected token");
    }

    const value = expr();
    if (pos !== tokens.length)
        throw new Error("trailing input");
    return value;
}

// Trims the float noise that makes `0.1 + 0.2` embarrassing, then groups
// the integer part so long results stay readable.
function format(value) {
    if (!isFinite(value))
        return value > 0 ? "∞" : (value < 0 ? "-∞" : "undefined");
    if (Number.isInteger(value) && Math.abs(value) < 1e21)
        return group(value.toFixed(0));

    const rounded = Number(value.toPrecision(12));
    if (Math.abs(rounded) >= 1e15 || (rounded !== 0 && Math.abs(rounded) < 1e-6))
        return rounded.toExponential(6).replace(/\.?0+e/, "e");
    return group(String(rounded));
}

function group(text) {
    const negative = text.startsWith("-");
    const body = negative ? text.slice(1) : text;
    const dot = body.indexOf(".");
    const intPart = dot === -1 ? body : body.slice(0, dot);
    const frac = dot === -1 ? "" : body.slice(dot);
    return (negative ? "-" : "") + intPart.replace(/\B(?=(\d{3})+(?!\d))/g, " ") + frac;
}

/// Returns `{ display, copy }` for an expression worth showing, else `null`.
function evaluate(input) {
    const src = String(input || "").trim()
        .replace(/^=\s*/, "").replace(/=$/, "")
        .replace(/\u00d7/g, "*").replace(/\u00f7/g, "/").replace(/\u2212/g, "-")
        .trim();
    if (src.length === 0 || src.length > 200)
        return null;

    // An expression has to actually compute something. Without this every
    // bare app name that happens to parse (`e`, `5`) would claim the top row.
    if (!/[-+*/%^()]|π|\d\s*(?:pi|tau)\b/i.test(src) && !NAMED_RE.test(src))
        return null;
    if (!/\d|\bpi\b|\btau\b|\be\b|π/i.test(src))
        return null;

    let value;
    try {
        value = parse(tokenize(src));
    } catch (e) {
        return null;
    }

    if (typeof value !== "number" || Number.isNaN(value))
        return null;

    const display = format(value);
    return {
        display: display,
        // Derived from the displayed text so the two can never disagree.
        copy: isFinite(value) ? display.replace(/\s/g, "") : String(value)
    };
}

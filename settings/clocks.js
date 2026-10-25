.pragma library

// World clocks as typed in the settings window: a city, then its UTC offset,
// e.g. "Yangon +6:30", "Lisbon 0" or "Los Angeles -8". Returns
// `{ name, offsetMinutes }`, or null when it does not read as one.
function parse(text) {
    const m = /^\s*(.+?)\s+(?:UTC\s*)?([+\-−]?)(\d{1,2})(?::?(\d{2}))?\s*$/i.exec(text);
    if (!m)
        return null;
    const hours = parseInt(m[3]);
    const minutes = m[4] ? parseInt(m[4]) : 0;
    if (hours > 14 || minutes >= 60)
        return null;
    const sign = m[2] === "-" || m[2] === "−" ? -1 : 1;
    return { name: m[1], offsetMinutes: sign * (hours * 60 + minutes) };
}

// 390 → "UTC+6:30", -180 → "UTC−3", 0 → "UTC".
function format(offsetMinutes) {
    if (offsetMinutes === 0)
        return "UTC";
    const abs = Math.abs(offsetMinutes);
    const h = Math.floor(abs / 60);
    const m = abs % 60;
    return `UTC${offsetMinutes < 0 ? "−" : "+"}${h}${m ? `:${String(m).padStart(2, "0")}` : ""}`;
}

.pragma library

// Splits one line of nmcli's terse (-t) output into its fields. Fields are
// separated by ':', and literal colons (common in SSIDs) and backslashes
// are escaped with '\'.
function splitTerse(line) {
    const fields = [];
    let field = "";
    for (let i = 0; i < line.length; i++) {
        if (line[i] === "\\" && i + 1 < line.length) {
            field += line[++i];
        } else if (line[i] === ":") {
            fields.push(field);
            field = "";
        } else {
            field += line[i];
        }
    }
    fields.push(field);
    return fields;
}

.pragma library

// Subsequence matcher for the launcher's application list.
//
// Every query character must appear in the name in order. Runs of
// consecutive matches are recorded so that ranking can prefer names where the
// query lands in long, early runs ("fire" in "Firefox" over "File Roller").

// Returns the matched runs as `{ index, length }`, or null when `query` is not
// a subsequence of `name`. Both are compared case-insensitively.
function match(query, name) {
    const q = query.toLowerCase();
    const n = name.toLowerCase();
    const runs = [];
    let ni = 0;
    let start = -1;

    for (let qi = 0; qi < q.length; qi++) {
        while (true) {
            if (ni === n.length)
                return null;

            if (n[ni++] === q[qi]) {
                if (start === -1)
                    start = ni - 1;
                break;
            }

            if (start !== -1) {
                runs.push({ index: start, length: ni - 1 - start });
                start = -1;
            }
        }
    }

    if (start !== -1)
        runs.push({ index: start, length: ni - start });

    return runs;
}

// Longer runs first, then earlier runs, then fewer runs, then shorter names.
function compare(a, b) {
    for (let i = 0; i < a.runs.length && i < b.runs.length; i++) {
        const s = (b.runs[i].length - a.runs[i].length) || (a.runs[i].index - b.runs[i].index);
        if (s !== 0)
            return s;
    }

    return (a.runs.length - b.runs.length)
        || (a.name.length - b.name.length)
        || a.name.localeCompare(b.name);
}

/// Filters `items` to those whose `nameOf(item)` matches `query`, best first.
function rank(query, items, nameOf) {
    return items
        .map(item => ({ item: item, name: nameOf(item), runs: match(query, nameOf(item)) }))
        .filter(e => e.runs !== null)
        .sort(compare)
        .map(e => e.item);
}

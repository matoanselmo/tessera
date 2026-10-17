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

// The first run decides (longer, then earlier), so what you typed always
// matters most. Among equally good matches the more-used app wins; after that,
// the remaining runs, fewer runs, then shorter names.
function compare(a, b) {
    if (a.runs.length > 0 && b.runs.length > 0) {
        const s = (b.runs[0].length - a.runs[0].length) || (a.runs[0].index - b.runs[0].index);
        if (s !== 0)
            return s;
    }

    if (a.boost !== b.boost)
        return b.boost - a.boost;

    for (let i = 1; i < a.runs.length && i < b.runs.length; i++) {
        const s = (b.runs[i].length - a.runs[i].length) || (a.runs[i].index - b.runs[i].index);
        if (s !== 0)
            return s;
    }

    return (a.runs.length - b.runs.length)
        || (a.name.length - b.name.length)
        || a.name.localeCompare(b.name);
}

/// Filters `items` to those whose `nameOf(item)` matches `query`, best first.
/// `boostOf(item)`, if given, ranks equally good matches (higher first).
function rank(query, items, nameOf, boostOf) {
    return items
        .map(item => ({ item: item, name: nameOf(item), runs: match(query, nameOf(item)), boost: boostOf ? boostOf(item) : 0 }))
        .filter(e => e.runs !== null)
        .sort(compare)
        .map(e => e.item);
}

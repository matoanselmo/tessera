.pragma library

// Anything with a dot and no spaces that ends in a plausible TLD. Kept
// deliberately tight so that `config.qml` or `2.5` don't read as addresses.
const URL_RE = /^[a-zA-Z0-9][a-zA-Z0-9-]*(?:\.[a-zA-Z0-9][a-zA-Z0-9-]*)*\.[a-zA-Z]{2,}(?::\d+)?(?:[/?#]\S*)?$/;
const SCHEME_RE = /^[a-zA-Z][a-zA-Z0-9+.-]*:\/\//;

// Filenames that happen to satisfy URL_RE. `.com` is a real TLD and a real
// DOS extension; the ones here are simply the extensions worth not guessing.
const NOT_A_TLD = ["qml", "js", "json", "conf", "config", "log", "txt", "md", "sh", "py", "rs", "toml", "yaml", "yml", "png", "jpg", "svg", "css", "html", "ts", "lock", "service", "desktop"];

function looksLikeUrl(query) {
    if (/\s/.test(query))
        return false;
    if (SCHEME_RE.test(query))
        return true;
    if (/^localhost(?::\d+)?(?:[/?#]\S*)?$/.test(query))
        return true;
    if (!URL_RE.test(query))
        return false;

    const host = query.split(/[/?#:]/)[0];
    const tld = host.slice(host.lastIndexOf(".") + 1).toLowerCase();
    return NOT_A_TLD.indexOf(tld) === -1;
}

/// Returns `{ kind, name, hint, url }` for a query, or null when empty.
/// `kind` is "open" for something already addressable and "search" otherwise.
function actionFor(query, engineUrl, engineName) {
    const trimmed = String(query || "").trim();
    if (trimmed.length === 0)
        return null;

    if (looksLikeUrl(trimmed)) {
        return {
            kind: "open",
            name: trimmed,
            hint: "Open link",
            url: SCHEME_RE.test(trimmed) ? trimmed
                : (trimmed.startsWith("localhost") ? "http://" : "https://") + trimmed
        };
    }

    return {
        kind: "search",
        name: trimmed,
        hint: "Search " + engineName,
        url: String(engineUrl).replace("%s", encodeURIComponent(trimmed))
    };
}

pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// How often and how recently each app was launched, so the launcher can put
// the ones you use first. Saved as JSON in Quickshell's state directory:
// `{ "<desktop entry id>": { "count": 12, "last": <epoch ms> } }`.
Singleton {
    id: root

    property var entries: ({})

    // Frecency: launches weighted by how recent the last one was, so an app
    // you once lived in sinks back down after you stop using it.
    function score(id: string): real {
        const entry = root.entries[id];
        if (!entry)
            return 0;

        const days = (Date.now() - entry.last) / 86400000;
        const weight = days < 1 ? 4 : days < 7 ? 2 : days < 30 ? 1 : 0.25;
        return entry.count * weight;
    }

    function record(id: string): void {
        const entry = root.entries[id] ?? {
            count: 0,
            last: 0
        };
        root.entries = Object.assign({}, root.entries, {
            [id]: {
                count: entry.count + 1,
                last: Date.now()
            }
        });
        file.setText(JSON.stringify(root.entries));
    }

    FileView {
        id: file
        path: Quickshell.statePath("launcher-history.json")
        // Missing on first run, which just means no history yet.
        printErrors: false
        // A few hundred bytes, read once: loading it synchronously means the
        // launcher's first ranking already has the history.
        blockLoading: true

        onLoaded: root.load()
    }

    function load(): void {
        try {
            root.entries = JSON.parse(file.text() || "{}") ?? {};
        } catch (e) {
            root.entries = {};
        }
    }

    // A blocking load finishes while this object is still being built, before
    // onLoaded is connected, so read it once construction is done as well.
    Component.onCompleted: root.load()
}

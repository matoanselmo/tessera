pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Clipboard history, kept by cliphist. The shell runs the recorder itself
// (`wl-paste --watch cliphist store`), so history fills without anything in
// the compositor config. The launcher's `;` mode lists and restores entries.
Singleton {
    id: root

    // Newest first: `{ id, line, text, image }`, where `line` is cliphist's
    // raw list line (what `cliphist delete` wants back) and `text` a one-line
    // preview.
    property var entries: []

    function refresh(): void {
        lister.running = true;
    }

    // Puts an entry back on the clipboard, images included.
    function copy(entry: var): void {
        Quickshell.execDetached(["sh", "-c", 'cliphist decode "$1" | wl-copy', "sh", entry.id]);
    }

    function remove(entry: var): void {
        root.entries = root.entries.filter(e => e.id !== entry.id);
        Quickshell.execDetached(["sh", "-c", 'printf "%s\\n" "$1" | cliphist delete', "sh", entry.line]);
    }

    // Referenced from shell.qml so the recorder starts with the shell, not
    // the first time the launcher asks for history.
    function init(): void {}

    // `[[ binary data 1.2 MiB png 1920x1080 ]]` → "Image · PNG 1920×1080".
    function describe(preview: string): var {
        const image = /^\[\[ binary data .*? (\w+) (\d+)x(\d+) \]\]$/.exec(preview);
        if (image)
            return { text: `Image · ${image[1].toUpperCase()} ${image[2]}×${image[3]}`, image: true };
        return { text: preview, image: false };
    }

    Process {
        id: recorder
        running: true
        command: ["wl-paste", "--watch", "cliphist", "store"]

        // Exits if the compositor restarts its data device; start it again.
        onExited: restart.start()
    }

    Timer {
        id: restart
        interval: 2000
        onTriggered: recorder.running = true
    }

    Process {
        id: lister
        command: ["cliphist", "list"]

        stdout: StdioCollector {
            onStreamFinished: {
                root.entries = text.split("\n").filter(l => l.includes("\t")).map(line => {
                    const tab = line.indexOf("\t");
                    const preview = root.describe(line.slice(tab + 1));
                    return {
                        id: line.slice(0, tab),
                        line: line,
                        text: preview.text,
                        image: preview.image
                    };
                });
            }
        }
    }
}

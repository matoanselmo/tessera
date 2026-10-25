pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Clipboard history, kept by cliphist. The shell runs the recorder itself
// (`wl-paste --watch cliphist store`), so history fills without anything in
// the compositor config. The launcher's `;` mode lists and restores entries.
Singleton {
    id: root

    // Newest first: `{ id, line, text, image, format, size, width, height }`,
    // where `line` is cliphist's raw list line (what `cliphist delete` wants
    // back) and `text` a one-line preview. The last four are only set for
    // images.
    property var entries: []

    // Decoded images for the launcher's thumbnails and preview, by entry id:
    // file paths in Quickshell's cache folder. The newest `thumbLimit` images
    // are decoded once each; files for entries that left the history are
    // deleted.
    property var thumbs: ({})
    readonly property int thumbLimit: 60
    readonly property string cacheDir: String(Quickshell.cachePath("clipboard")).replace(/^file:\/\//, "")

    function refresh(): void {
        lister.running = true;
    }

    // Puts an entry back on the clipboard, images included.
    function copy(entry: var): void {
        Quickshell.execDetached(["sh", "-c", 'cliphist decode "$1" | wl-copy', "sh", entry.id]);
    }

    // Copies it, then presses Ctrl+V in whatever has focus once the launcher
    // has closed and focus has gone back there. Terminals that paste with
    // Ctrl+Shift+V get a literal ^V instead.
    function paste(entry: var): void {
        Quickshell.execDetached(["sh", "-c", 'cliphist decode "$1" | wl-copy; sleep 0.3; wtype -M ctrl -k v -m ctrl', "sh", entry.id]);
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
        const image = /^\[\[ binary data (.*?) (\w+) (\d+)x(\d+) \]\]$/.exec(preview);
        if (image)
            return {
                text: `Image · ${image[2].toUpperCase()} ${image[3]}×${image[4]}`,
                image: true,
                size: image[1],
                format: image[2].toLowerCase(),
                width: parseInt(image[3]),
                height: parseInt(image[4])
            };
        return { text: preview, image: false };
    }

    // `file://` URL of an entry's decoded image, or "" until it is ready.
    function thumbOf(entry: var): string {
        const path = root.thumbs[entry.id];
        return path ? `file://${path}` : "";
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
                    return Object.assign({
                        id: line.slice(0, tab),
                        line: line
                    }, root.describe(line.slice(tab + 1)));
                });

                const images = root.entries.filter(e => e.image).slice(0, root.thumbLimit);
                thumbnailer.command = ["sh", "-c", root.thumbScript, "sh", root.cacheDir].concat(images.map(e => `${e.id}.${e.format}`));
                thumbnailer.running = true;
            }
        }
    }

    // Decodes each image not cached yet, deletes cached ones no longer
    // wanted, and lists what is there. Arguments: the folder, then one
    // `<id>.<format>` per image to keep.
    readonly property string thumbScript: `
        dir=$1; shift
        mkdir -p "$dir" && cd "$dir" || exit 1
        for f in "$@"; do
            [ -s "$f" ] || cliphist decode "\${f%%.*}" > "$f" 2>/dev/null || rm -f "$f"
        done
        for f in *; do
            case " $* " in *" $f "*) ;; *) rm -f "$f" ;; esac
        done
        ls
    `

    Process {
        id: thumbnailer

        stdout: StdioCollector {
            onStreamFinished: {
                const map = {};
                for (const f of text.split("\n").filter(f => f !== ""))
                    map[f.slice(0, f.indexOf("."))] = `${root.cacheDir}/${f}`;
                root.thumbs = map;
            }
        }
    }
}

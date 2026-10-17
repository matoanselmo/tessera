pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs

// Files under your home folder for the launcher's `/` search, listed afresh
// each time file search opens; filtering then happens as you type. Hidden
// folders, node_modules and ShellGlobals.fileSearchSkip are left out.
Singleton {
    id: root

    readonly property string home: Quickshell.env("HOME")
    property var paths: []

    function refresh(): void {
        lister.running = true;
    }

    function open(path: string): void {
        Quickshell.execDetached(["xdg-open", path]);
    }

    // Opens the folder the file is in.
    function reveal(path: string): void {
        Quickshell.execDetached(["xdg-open", path.slice(0, path.lastIndexOf("/")) || "/"]);
    }

    // "/home/you/a/b/c.txt" → "~/a/b".
    function folderOf(path: string): string {
        const dir = path.slice(0, path.lastIndexOf("/"));
        return dir.startsWith(root.home) ? `~${dir.slice(root.home.length)}` : dir;
    }

    Process {
        id: lister
        // find, not rg: it is always installed. Each skipped folder is pruned
        // so find never descends into it.
        command: {
            const args = ["find", root.home];
            // A loop, not flatMap: a list read from a QML property lacks it.
            for (const path of ShellGlobals.fileSearchSkip)
                args.push("-path", path.replace(/^~/, root.home), "-prune", "-o");
            return args.concat(["-name", ".*", "-prune", "-o", "-name", "node_modules", "-prune", "-o", "-type", "f", "-print"]);
        }

        stdout: StdioCollector {
            onStreamFinished: root.paths = text.split("\n").filter(p => p !== "")
        }
    }
}

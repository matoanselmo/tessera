pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs

// Files under your home folder for the launcher's `/` search, listed afresh
// each time file search opens; filtering then happens as you type. Listed
// with ripgrep, which leaves out hidden and git-ignored files; node_modules
// and ShellGlobals.fileSearchSkip are skipped too.
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
        // Run from the home folder: ripgrep anchors a glob's leading "/" to
        // the working directory, so "!/config/" skips ~/config and nothing
        // else. Its output is relative to here as a result.
        workingDirectory: root.home
        command: {
            const args = ["rg", "--files", "--glob", "!node_modules/"];
            // A loop, not flatMap: a list read from a QML property lacks it.
            for (const path of ShellGlobals.fileSearchSkip)
                args.push("--glob", `!${path.replace(/^~/, "")}/`);
            return args;
        }

        stdout: StdioCollector {
            onStreamFinished: root.paths = text.split("\n").filter(p => p !== "").map(p => `${root.home}/${p}`)
        }
    }
}

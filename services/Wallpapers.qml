pragma Singleton

import QtQuick
import Qt.labs.folderlistmodel
import Quickshell
import Quickshell.Io
import qs

// The wallpaper: the images in ShellGlobals.wallpaperDir (watched, so new
// files appear at once), which one is chosen (remembered across restarts),
// and switching between them.
//
//     qs ipc call wallpaper next|previous|random
//     qs ipc call wallpaper set <path>
Singleton {
    id: root

    readonly property string folder: ShellGlobals.wallpaperDir.replace(/^~/, Quickshell.env("HOME"))

    // Absolute paths, sorted by file name.
    property var images: []

    // The chosen image's path, or "" for the default.
    property string current: ""

    // What to draw: the chosen image if it still exists, else the first in
    // the folder, else the one that ships with the shell.
    readonly property string path: root.images.includes(root.current) ? root.current : (root.images[0] ?? "")
    readonly property url source: root.path !== "" ? `file://${root.path}` : Qt.resolvedUrl("../wallpaper/Wallpaper.png")

    function set(path: string): void {
        root.current = path;
        saved.setText(JSON.stringify({
            path: path
        }));
    }

    function step(delta: int): void {
        if (root.images.length === 0)
            return;
        const i = root.images.indexOf(root.path);
        root.set(root.images[(i + delta + root.images.length) % root.images.length]);
    }

    function random(): void {
        const others = root.images.filter(p => p !== root.path);
        if (others.length > 0)
            root.set(others[Math.floor(Math.random() * others.length)]);
    }

    // "/…/backgrounds/forest-night.jpg" → "forest-night".
    function nameOf(path: string): string {
        const file = path.slice(path.lastIndexOf("/") + 1);
        const dot = file.lastIndexOf(".");
        return dot > 0 ? file.slice(0, dot) : file;
    }

    function openFolder(): void {
        Quickshell.execDetached(["xdg-open", root.folder]);
    }

    FolderListModel {
        id: listing
        folder: `file://${root.folder}`
        nameFilters: ["*.png", "*.jpg", "*.jpeg", "*.webp", "*.PNG", "*.JPG", "*.JPEG", "*.WEBP"]
        showDirs: false
        sortField: FolderListModel.Name

        onStatusChanged: root.reload()
        onCountChanged: root.reload()
    }

    function reload(): void {
        if (listing.status !== FolderListModel.Ready)
            return;
        const paths = [];
        for (let i = 0; i < listing.count; i++)
            paths.push(listing.get(i, "filePath"));
        root.images = paths;
    }

    // `{ "path": "…" }` in Quickshell's state directory.
    FileView {
        id: saved
        path: Quickshell.statePath("wallpaper.json")
        printErrors: false
        blockLoading: true
    }

    // A blocking load finishes before onLoaded is connected, so read it once
    // construction is done.
    Component.onCompleted: {
        try {
            root.current = JSON.parse(saved.text() || "{}").path ?? "";
        } catch (e) {
            root.current = "";
        }
    }

    IpcHandler {
        target: "wallpaper"

        function next(): void {
            root.step(1);
        }

        function previous(): void {
            root.step(-1);
        }

        function random(): void {
            root.random();
        }

        function set(path: string): void {
            root.set(path);
        }
    }
}

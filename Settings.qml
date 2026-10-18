pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// The settings `@config` in the launcher changes, kept in
// ~/.config/tessera/settings.json. The file is watched, so editing it by hand
// applies at once; a missing file or key falls back to the defaults here.
// ShellGlobals reads these, so the rest of the shell never refers to Settings.
Singleton {
    id: root

    readonly property string path: `${Quickshell.env("HOME")}/.config/tessera/settings.json`

    property bool burmeseNumerals: true
    property bool use24Hour: true
    property real motionScale: 1

    // What the launcher lists, in order. Enter moves to the next value.
    readonly property var options: [
        {
            key: "burmeseNumerals",
            name: "Burmese numerals",
            values: [
                {
                    value: true,
                    label: "On"
                },
                {
                    value: false,
                    label: "Off"
                }
            ]
        },
        {
            key: "use24Hour",
            name: "Clock",
            values: [
                {
                    value: true,
                    label: "24-hour"
                },
                {
                    value: false,
                    label: "12-hour"
                }
            ]
        },
        {
            key: "motionScale",
            name: "Animation speed",
            values: [
                {
                    value: 1,
                    label: "Normal"
                },
                {
                    value: 1.25,
                    label: "Calm"
                },
                {
                    value: 0,
                    label: "Off"
                },
                {
                    value: 0.75,
                    label: "Fast"
                }
            ]
        }
    ]

    // The current value's label, or the raw value when the file holds one
    // that is not in the list.
    function labelOf(key: string): string {
        const option = root.options.find(o => o.key === key);
        const match = option.values.find(v => v.value === root[key]);
        return match ? match.label : String(root[key]);
    }

    function next(key: string): void {
        const values = root.options.find(o => o.key === key).values;
        const i = values.findIndex(v => v.value === root[key]);
        root.set(key, values[(i + 1) % values.length].value);
    }

    function set(key: string, value: var): void {
        root[key] = value;
        const data = {};
        for (const o of root.options)
            data[o.key] = root[o.key];
        file.setText(JSON.stringify(data, null, 2) + "\n");
    }

    // Missing or mistyped keys keep their defaults rather than breaking the
    // bindings that read them.
    function load(): void {
        let data = {};
        try {
            data = JSON.parse(file.text() || "{}");
        } catch (e) {
            console.warn(`Settings: ${root.path} is not valid JSON, using defaults`);
        }
        for (const o of root.options) {
            const fallback = o.values[0].value;
            root[o.key] = typeof data[o.key] === typeof fallback ? data[o.key] : fallback;
        }
    }

    FileView {
        id: file
        path: root.path
        printErrors: false
        blockLoading: true
        watchChanges: true

        onFileChanged: reload()
        onLoaded: root.load()
        onLoadFailed: root.load()
    }

    // A blocking load finishes before onLoaded is connected, so read it once
    // construction is done.
    Component.onCompleted: root.load()
}

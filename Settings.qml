pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Everything the settings window (and `@config` in the launcher) changes,
// kept in ~/.config/tessera/settings.json. The file is watched, so editing it
// by hand applies at once; a missing file or key falls back to the defaults
// here. ShellGlobals reads these, so the rest of the shell rarely refers to
// Settings directly.
Singleton {
    id: root

    readonly property string path: `${Quickshell.env("HOME")}/.config/tessera/settings.json`

    property bool burmeseNumerals: true
    property bool use24Hour: true
    property bool showSeconds: false
    property real motionScale: 1
    property int barThickness: 28
    property string wallpaperTransition: "crossfade"
    property string searchEngine: "google"

    // `{ name, offsetMinutes }`, shown beside local time in the clock menu.
    property var worldClocks: root.defaultClocks
    readonly property var defaultClocks: [
        {
            name: "Brasília",
            offsetMinutes: -180
        }
    ]

    // The bar's right-hand widgets, left to right, as `{ id, shown }`.
    property var barWidgets: root.widgetCatalog.map(w => ({
                id: w.id,
                shown: true
            }))

    // Every widget the right side of the bar can hold. `fixed` ones cannot be
    // hidden, only moved; `note` says when one hides itself anyway.
    readonly property var widgetCatalog: [
        {
            id: "tray",
            name: "Tray",
            note: "only with tray apps"
        },
        {
            id: "mic",
            name: "Microphone",
            note: "only while in use"
        },
        {
            id: "volume",
            name: "Volume",
            note: ""
        },
        {
            id: "cpu",
            name: "CPU",
            note: ""
        },
        {
            id: "memory",
            name: "Memory",
            note: ""
        },
        {
            id: "dnd",
            name: "Do not disturb",
            note: ""
        },
        {
            id: "network",
            name: "Network",
            note: ""
        },
        {
            id: "bluetooth",
            name: "Bluetooth",
            note: ""
        },
        {
            id: "battery",
            name: "Battery",
            note: "laptop only"
        },
        {
            id: "power",
            name: "Power",
            note: "always shown",
            fixed: true
        }
    ]

    readonly property var searchEngines: [
        {
            value: "google",
            label: "Google",
            url: "https://www.google.com/search?q=%s"
        },
        {
            value: "duckduckgo",
            label: "DuckDuckGo",
            url: "https://duckduckgo.com/?q=%s"
        },
        {
            value: "brave",
            label: "Brave",
            url: "https://search.brave.com/search?q=%s"
        },
        {
            value: "startpage",
            label: "Startpage",
            url: "https://www.startpage.com/do/search?q=%s"
        }
    ]

    readonly property var engine: root.searchEngines.find(e => e.value === root.searchEngine) ?? root.searchEngines[0]

    // The single-value settings, in the order the launcher lists them. Each
    // names the settings window section it appears in. Enter in the launcher,
    // or h/l in the window, moves to the next value.
    readonly property var options: [
        {
            key: "use24Hour",
            section: "clock",
            name: "Format",
            description: "Every clock: bar, lock screen, world clocks",
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
            key: "burmeseNumerals",
            section: "clock",
            name: "Burmese numerals",
            description: "၁၄:၃၅ instead of 14:35",
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
            key: "showSeconds",
            section: "clock",
            name: "Seconds",
            description: "Show seconds in the bar clock",
            values: [
                {
                    value: false,
                    label: "Off"
                },
                {
                    value: true,
                    label: "On"
                }
            ]
        },
        {
            key: "barThickness",
            section: "bar",
            name: "Height",
            description: "Bar thickness in pixels",
            values: [
                {
                    value: 28,
                    label: "28"
                },
                {
                    value: 24,
                    label: "24"
                },
                {
                    value: 32,
                    label: "32"
                }
            ]
        },
        {
            key: "wallpaperTransition",
            section: "wallpaper",
            name: "Transition",
            description: "How a new wallpaper comes in",
            values: [
                {
                    value: "crossfade",
                    label: "Crossfade"
                },
                {
                    value: "none",
                    label: "None"
                }
            ]
        },
        {
            key: "motionScale",
            section: "motion",
            name: "Animation speed",
            description: "Scales every animation in the shell",
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
                    value: 0.75,
                    label: "Fast"
                },
                {
                    value: 0,
                    label: "Off"
                }
            ]
        },
        {
            key: "searchEngine",
            section: "launcher",
            name: "Web search",
            description: "Where the launcher sends a search",
            values: root.searchEngines.map(e => ({
                        value: e.value,
                        label: e.label
                    }))
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
        root.step(key, 1);
    }

    function step(key: string, delta: int): void {
        const values = root.options.find(o => o.key === key).values;
        const i = values.findIndex(v => v.value === root[key]);
        root.set(key, values[(i + delta + values.length) % values.length].value);
    }

    function set(key: string, value: var): void {
        root[key] = value;
        root.save();
    }

    function addClock(clock: var): void {
        root.set("worldClocks", root.worldClocks.concat([clock]));
    }

    function removeClock(index: int): void {
        root.set("worldClocks", root.worldClocks.filter((c, i) => i !== index));
    }

    function toggleWidget(index: int): void {
        const w = root.barWidgets[index];
        if (!w || root.widgetCatalog.find(c => c.id === w.id)?.fixed)
            return;
        root.set("barWidgets", root.barWidgets.map((x, i) => i === index ? {
                    id: x.id,
                    shown: !x.shown
                } : x));
    }

    // Swaps a widget with its neighbour; returns where it ended up.
    function moveWidget(index: int, delta: int): int {
        const to = index + delta;
        if (to < 0 || to >= root.barWidgets.length)
            return index;
        const list = root.barWidgets.slice();
        [list[index], list[to]] = [list[to], list[index]];
        root.set("barWidgets", list);
        return to;
    }

    function widgetShown(id: string): bool {
        return root.barWidgets.find(w => w.id === id)?.shown ?? true;
    }

    function save(): void {
        const data = {};
        for (const o of root.options)
            data[o.key] = root[o.key];
        data.worldClocks = root.worldClocks;
        data.barWidgets = root.barWidgets;
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

        root.worldClocks = Array.isArray(data.worldClocks) ? data.worldClocks.filter(c => typeof c?.name === "string" && typeof c?.offsetMinutes === "number") : root.defaultClocks;

        // Saved order first, unknown ids dropped; widgets the file has not
        // heard of yet (added in a newer Tessera) join at their default spot.
        const saved = Array.isArray(data.barWidgets) ? data.barWidgets.filter(w => root.widgetCatalog.some(c => c.id === w?.id)) : [];
        const widgets = saved.map(w => ({
                    id: w.id,
                    shown: w.shown !== false
                }));
        root.widgetCatalog.forEach((c, i) => {
            if (!widgets.some(w => w.id === c.id))
                widgets.splice(Math.min(i, widgets.length), 0, {
                    id: c.id,
                    shown: true
                });
        });
        root.barWidgets = widgets;
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

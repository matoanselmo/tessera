import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs
import qs.components
import qs.services
import qs.lock
import qs.terminal
import qs.settings as SettingsWindow
import "Calculator.js" as Calculator
import "WebSearch.js" as WebSearch
import "Fuzzy.js" as Fuzzy
import "Emoji.js" as Emoji

Item {
    id: root

    // Explicit outward signal. The old code assigned to `persist.launcherOpen`,
    // an id belonging to Controller.qml; that resolves only through QML's
    // context chain and is exactly what `ComponentBehavior: Bound` forbids.
    signal closeRequested

    readonly property string query: search.text.trim()

    // A leading character switches mode: `;` clipboard history, `:` emoji,
    // `/` files. The rest of the text searches within it. "" is the normal
    // app search (with maths and web rows).
    readonly property string mode: ({
            ";": "clip",
            ":": "emoji",
            "/": "files",
            "@": "command"
        })[search.text[0]] ?? ""
    readonly property string modeQuery: search.text.slice(1).trim().toLowerCase()

    // Clipboard mode only: Tab narrows the history to images.
    property bool imagesOnly: false
    readonly property bool clipMode: root.mode === "clip"
    readonly property var clipEntry: root.clipMode && list.currentItem?.modelData?.kind === "clip" ? list.currentItem.modelData.entry : null

    onModeChanged: {
        root.imagesOnly = false;
        if (root.mode === "clip")
            Clipboard.refresh();
        else if (root.mode === "files")
            Files.refresh();
    }

    // Non-application rows. Both return null when the query isn't theirs, so
    // they cost one regex test per keystroke on an ordinary app search.
    readonly property var calcResult: root.mode !== "" ? null : Calculator.evaluate(root.query)
    readonly property var webAction: root.mode !== "" ? null : WebSearch.actionFor(root.query, ShellGlobals.searchEngineUrl, ShellGlobals.searchEngineName)

    // Emoji whose name has every word typed, exact and prefix matches first.
    function emojiRows(q: string): var {
        const words = q.split(/\s+/).filter(w => w !== "");
        const rank = e => e[1] === q ? 0 : e[1].startsWith(q) ? 1 : 2;
        return Emoji.list.filter(e => words.every(w => e[1].includes(w))).sort((a, b) => (rank(a) - rank(b)) || (a[1].length - b[1].length)).slice(0, 60).map(e => ({
                    kind: "emoji",
                    name: e[1][0].toUpperCase() + e[1].slice(1),
                    glyph: e[0],
                    hint: "Copy",
                    emoji: e[0]
                }));
    }

    // Commands behind `@`. Typing `@` lists them; `@name` picks one. A command
    // with `list` shows its own rows, filtered by whatever follows its name
    // (`@config clock`); one with `run` runs on Enter.
    readonly property var commands: [
        {
            name: "settings",
            description: "Open the settings window",
            run: () => SettingsWindow.Controller.open()
        },
        {
            name: "config",
            description: "Change the wallpaper and settings",
            list: q => root.settingRows(q)
        },
        {
            name: "lock",
            description: "Lock the screen",
            run: () => LockState.lock()
        },
        {
            name: "dnd",
            description: "Toggle do not disturb",
            run: () => Notifications.setDnd(!Notifications.dnd)
        },
        {
            name: "terminal",
            description: "Open the popup terminal",
            run: () => PopupTerminal.open()
        }
    ]

    // "@config wallpaper forest" → { name: "config", rest: "wallpaper forest" }.
    readonly property var commandInput: {
        const m = /^@(\S*)\s*(.*)$/.exec(search.text) ?? [];
        return {
            name: (m[1] ?? "").toLowerCase(),
            rest: (m[2] ?? "").trim().toLowerCase()
        };
    }

    function commandRows(): var {
        const input = root.commandInput;
        const exact = root.commands.find(c => c.name === input.name);
        if (exact?.list)
            return exact.list(input.rest);

        return root.commands.filter(c => c.name.startsWith(input.name)).map(c => ({
                    kind: "command",
                    name: `@${c.name}`,
                    glyph: "@",
                    hint: c.description,
                    command: c
                }));
    }

    // Every wallpaper in the folder, current one marked, plus a way to add more.
    function wallpaperRows(q: string): var {
        const rows = Wallpapers.images.filter(p => Wallpapers.nameOf(p).toLowerCase().includes(q)).map(p => ({
                    kind: "wallpaper",
                    name: Wallpapers.nameOf(p),
                    thumb: `file://${p}`,
                    hint: p === Wallpapers.path ? "Current" : "Set",
                    path: p
                }));
        if (q === "")
            rows.push({
                kind: "command",
                name: "Open the backgrounds folder",
                glyph: "\u2197",
                hint: ShellGlobals.wallpaperDir,
                command: {
                    run: () => Wallpapers.openFolder()
                }
            });
        return rows;
    }

    // The wallpaper, which opens its own list (`@config wallpaper forest`),
    // each setting with its current value, and the file they are saved in.
    function settingRows(q: string): var {
        const wallpaper = /^wallpaper(?:\s+(.*))?$/.exec(q);
        if (wallpaper)
            return root.wallpaperRows(wallpaper[1] ?? "");

        const rows = "wallpaper".includes(q) ? [
            {
                kind: "page",
                name: "Wallpaper",
                glyph: "\u25a3",
                hint: Wallpapers.path !== "" ? Wallpapers.nameOf(Wallpapers.path) : "Default",
                query: "@config wallpaper "
            }
        ] : [];
        for (const o of Settings.options.filter(o => o.name.toLowerCase().includes(q)))
            rows.push({
                kind: "setting",
                name: o.name,
                glyph: "\u2699",
                hint: Settings.labelOf(o.key),
                key: o.key
            });
        if (q === "")
            rows.push({
                kind: "command",
                name: "Open settings.json",
                glyph: "\u2197",
                hint: "~/.config/tessera",
                command: {
                    run: () => Quickshell.execDetached(["xdg-open", Settings.path])
                }
            });
        return rows;
    }

    // Files ranked by how well their name (not their folder) matches.
    function fileRows(q: string): var {
        const name = p => p.slice(p.lastIndexOf("/") + 1);
        return Fuzzy.rank(q, Files.paths, name).slice(0, 50).map(p => ({
                    kind: "file",
                    name: name(p),
                    glyph: "\u25a4",
                    hint: Files.folderOf(p),
                    path: p
                }));
    }

    // Opened through the clipboard IPC target: start in clipboard mode.
    Component.onCompleted: {
        if (Controller.pendingQuery !== "") {
            search.text = Controller.pendingQuery;
            Controller.pendingQuery = "";
        }
    }

    Connections {
        target: Controller

        function onQueryRequested(text) {
            search.text = text;
            Controller.pendingQuery = "";
        }
    }

    function runEntry(entry: var): void {
        if (!entry)
            return;

        switch (entry.kind) {
        case "app":
            entry.entry.execute();
            History.record(entry.entry.id);
            break;
        case "calc":
            // `--` because a negative result is otherwise read as a flag.
            Quickshell.execDetached(["wl-copy", "--", entry.copy]);
            break;
        case "web":
            Quickshell.execDetached(["xdg-open", entry.url]);
            break;
        case "clip":
            Clipboard.copy(entry.entry);
            break;
        case "emoji":
            Quickshell.execDetached(["wl-copy", "--", entry.emoji]);
            break;
        case "file":
            Files.open(entry.path);
            break;
        case "command":
            // A command with its own list completes to it instead of running.
            if (entry.command.list) {
                search.text = `${entry.name} `;
                return;
            }
            entry.command.run();
            break;
        case "page":
            search.text = entry.query;
            return;
        case "wallpaper":
        case "setting":
            {
                // Both stay open, so you can try a few wallpapers or cycle to
                // the value you want. The changed rows are replaced, which
                // would push the selection on.
                const index = list.currentIndex;
                if (entry.kind === "wallpaper")
                    Wallpapers.set(entry.path);
                else
                    Settings.next(entry.key);
                list.currentIndex = index;
                return;
            }
        }

        root.closeRequested();
    }

    // The window is sized for the wider clipboard layout, so the card can
    // grow into it (and back) without the window itself resizing.
    height: 50 + searchContainer.implicitHeight + list.topMargin * 2 + list.delegateHeight * 10 + root.footerSpace
    width: root.clipWidth

    readonly property int normalWidth: 600
    readonly property int clipWidth: 840
    readonly property int footerSpace: 34

    Rectangle {
        id: content
        // Clipboard history keeps a steady height, so the preview beside it
        // does not jump as entries are filtered.
        height: 24 + searchContainer.implicitHeight + list.topMargin + list.bottomMargin + (root.clipMode ? list.delegateHeight * 10 + root.footerSpace : Math.min(list.contentHeight, list.delegateHeight * 10))
        Behavior on height {
            Anim {}
        }
        width: root.clipMode ? root.clipWidth : root.normalWidth
        Behavior on width {
            Anim {}
        }
        anchors.horizontalCenter: parent.horizontalCenter
        color: ShellGlobals.materialColors.tertiarycontainer
        radius: ShellGlobals.radius

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 16
            anchors.bottomMargin: 0
            spacing: 0

            Rectangle {
                id: searchContainer
                Layout.fillWidth: true
                implicitHeight: searchbox.implicitHeight + 10
                color: ShellGlobals.materialColors.secondarycontainer
                radius: ShellGlobals.radius

                RowLayout {
                    id: searchbox
                    anchors.fill: parent
                    anchors.margins: 5

                    TextInput {
                        id: search
                        Layout.fillWidth: true
                        Layout.leftMargin: 10
                        color: ShellGlobals.materialColors.onsecondarycontainer

                        font.family: ShellGlobals.fontFamily
                        font.pixelSize: 16
                        font.bold: true
                        font.letterSpacing: ShellGlobals.letterSpacing

                        focus: true
                        Keys.forwardTo: [list]
                        Keys.onEscapePressed: root.closeRequested()

                        Keys.onPressed: event => {
                            // Shift+Enter on a file opens the folder it is in.
                            if (root.mode === "files" && (event.key == Qt.Key_Return || event.key == Qt.Key_Enter) && (event.modifiers & Qt.ShiftModifier)) {
                                const row = list.currentItem?.modelData;
                                if (row?.kind === "file") {
                                    Files.reveal(row.path);
                                    root.closeRequested();
                                }
                                event.accepted = true;
                                return;
                            }

                            // In clipboard history, Tab shows only images and
                            // Shift+Enter pastes into the window underneath.
                            if (root.clipMode && event.key == Qt.Key_Tab) {
                                root.imagesOnly = !root.imagesOnly;
                                event.accepted = true;
                                return;
                            }
                            if (root.clipMode && (event.key == Qt.Key_Return || event.key == Qt.Key_Enter) && (event.modifiers & Qt.ShiftModifier)) {
                                if (root.clipEntry) {
                                    Clipboard.paste(root.clipEntry);
                                    root.closeRequested();
                                }
                                event.accepted = true;
                                return;
                            }

                            // Shift+Delete forgets the selected clipboard entry.
                            if (root.mode === "clip" && event.key == Qt.Key_Delete && (event.modifiers & Qt.ShiftModifier)) {
                                const row = list.currentItem?.modelData;
                                if (row?.kind === "clip")
                                    Clipboard.remove(row.entry);
                                event.accepted = true;
                                return;
                            }

                            if (event.modifiers & Qt.ControlModifier) {
                                if (event.key == Qt.Key_J) {
                                    list.currentIndex = list.currentIndex == list.count - 1 ? 0 : list.currentIndex + 1;
                                    event.accepted = true;
                                } else if (event.key == Qt.Key_K) {
                                    list.currentIndex = list.currentIndex == 0 ? list.count - 1 : list.currentIndex - 1;
                                    event.accepted = true;
                                }
                            }
                        }

                        onAccepted: {
                            if (list.currentItem) {
                                list.currentItem.activate();
                            }
                        }

                        onTextChanged: {
                            list.currentIndex = 0;
                        }

                        StyledText {
                            anchors.fill: parent
                            verticalAlignment: Text.AlignVCenter
                            visible: search.text === ""
                            text: "Apps  ·  = maths  ·  ; clipboard  ·  : emoji  ·  / files  ·  @ commands"
                            font: search.font
                            color: ShellGlobals.materialColors.onsecondarycontainer
                            opacity: 0.4
                        }
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 12

                ListView {
                    id: list
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    cacheBuffer: 0
                    model: ScriptModel {
                        // Searched on the trimmed query, like the calculator and web
                        // rows; apps you launch often win among equal matches.
                        readonly property var appRows: Fuzzy.rank(root.query, DesktopEntries.applications.values, app => app.name, app => History.score(app.id)).map(app => ({
                            kind: "app",
                            entry: app,
                            name: app.name,
                            icon: app.icon,
                            hint: ""
                        }))

                        values: {
                            // The prefixed modes show nothing else.
                            if (root.mode === "emoji")
                                return root.emojiRows(root.modeQuery);
                            if (root.mode === "files")
                                return root.fileRows(root.modeQuery);
                            if (root.mode === "command")
                                return root.commandRows();
                            if (root.mode === "clip") {
                                const q = root.modeQuery;
                                return Clipboard.entries.filter(e => (!root.imagesOnly || e.image) && (q === "" || e.text.toLowerCase().includes(q))).slice(0, 200).map(e => ({
                                    kind: "clip",
                                    name: e.text,
                                    // Images show their thumbnail once decoded,
                                    // and the glyph until then.
                                    glyph: e.image ? (Clipboard.thumbs[e.id] ? "" : "\u25a3") : "\u29c9",
                                    thumb: e.image ? Clipboard.thumbOf(e) : undefined,
                                    sub: e.image ? e.size : undefined,
                                    entry: e
                                }));
                            }

                            const calc = root.calcResult;
                            const web = root.webAction;

                            const calcRows = calc ? [{
                                kind: "calc",
                                name: calc.display,
                                glyph: "=",
                                hint: "Copy",
                                copy: calc.copy
                            }] : [];

                            const webRows = web ? [{
                                kind: "web",
                                name: web.name,
                                glyph: web.kind === "open" ? "\u2197" : "\u2315",
                                hint: web.hint,
                                url: web.url
                            }] : [];

                            // A bare address is almost certainly what you meant, so
                            // it outranks fuzzy app matches; a search term does not.
                            return web && web.kind === "open"
                                ? calcRows.concat(webRows, appRows)
                                : calcRows.concat(appRows, webRows);
                        }

                        // Typing already resets the selection. In command mode rows also
                        // change under you (the current wallpaper's marker moves), and
                        // the selection should stay where you left it, until you
                        // switch to another command or page (`@config wallpaper`).
                        property string shownCommand: ""
                        onValuesChanged: {
                            const command = root.mode === "command" ? `${root.commandInput.name} ${root.commandInput.rest.split(" ")[0]}` : "";
                            if (root.mode !== "command" || command !== shownCommand)
                                list.currentIndex = 0;
                            shownCommand = command;
                        }
                    }

                    topMargin: 7
                    bottomMargin: list.count == 0 ? 0 : 7

                    add: Transition {
                        Anim {
                            property: "opacity"
                            from: 0
                            to: 1
                            time: ShellGlobals.animFast
                        }
                    }

                    displaced: Transition {
                        Anim {
                            property: "y"
                        }
                        Anim {
                            property: "opacity"
                            to: 1
                            time: ShellGlobals.animFast
                        }
                    }

                    move: Transition {
                        Anim {
                            property: "y"
                        }
                        Anim {
                            property: "opacity"
                            to: 1
                            time: ShellGlobals.animFast
                        }
                    }

                    remove: Transition {
                        Anim {
                            property: "y"
                        }
                        Anim {
                            property: "opacity"
                            to: 0
                            time: ShellGlobals.animFast
                            curve: ShellGlobals.easeIn
                        }
                    }

                    highlight: Rectangle {
                        color: ShellGlobals.materialColors.tertiary
                        radius: ShellGlobals.radius
                    }

                    keyNavigationEnabled: true
                    keyNavigationWraps: true
                    highlightMoveVelocity: -1
                    highlightMoveDuration: 100
                    preferredHighlightBegin: list.topMargin
                    preferredHighlightEnd: list.height - list.bottomMargin
                    highlightRangeMode: ListView.ApplyRange
                    snapMode: ListView.SnapToItem

                    readonly property real delegateHeight: 36

                    delegate: MouseArea {
                        cursorShape: Qt.PointingHandCursor
                        required property var modelData

                        // Clipboard images get a second line, and room for a
                        // bigger thumbnail.
                        implicitHeight: modelData.sub !== undefined ? 52 : list.delegateHeight
                        implicitWidth: ListView.view.width

                        function activate(): void {
                            root.runEntry(modelData);
                        }

                        onClicked: activate()

                        RowLayout {
                            id: delegateLayout
                            spacing: 8
                            anchors {
                                verticalCenter: parent.verticalCenter
                                left: parent.left
                                right: parent.right
                                leftMargin: 16
                                rightMargin: 16
                            }

                            // Fixed slot so names stay aligned even when an entry has
                            // no usable icon. `check: true` yields "" for a name the
                            // theme lacks; without it the provider returns a magenta
                            // placeholder texture that renders as a broken tile.
                            Item {
                                Layout.alignment: Qt.AlignVCenter
                                // Wallpaper rows show a wider 16:9 thumbnail.
                                // Every clipboard row keeps the image width,
                                // so text and images line up.
                                Layout.preferredWidth: modelData.kind === "clip" ? 72 : modelData.thumb ? 56 : 32
                                Layout.preferredHeight: modelData.sub !== undefined ? 42 : 32

                                Image {
                                    anchors.fill: parent
                                    visible: !!modelData.thumb
                                    source: modelData.thumb ?? ""
                                    fillMode: Image.PreserveAspectCrop
                                    asynchronous: true
                                    sourceSize.width: 144
                                    sourceSize.height: 84
                                    opacity: status === Image.Ready ? 1 : 0

                                    Behavior on opacity {
                                        Anim {
                                            time: ShellGlobals.animFast
                                        }
                                    }
                                }

                                IconImage {
                                    id: entryIcon
                                    anchors.fill: parent
                                    asynchronous: true
                                    visible: entryIcon.source !== ""
                                    source: modelData.icon ? Quickshell.iconPath(modelData.icon, true) : ""
                                }

                                // The synthetic rows use a glyph rather than a theme
                                // icon: Quickshell resolves only hicolor application
                                // icons here, so `system-search` and friends come back
                                // empty and there is nothing to draw.
                                StyledText {
                                    anchors.centerIn: parent
                                    visible: text !== ""
                                    text: modelData.glyph ?? ""
                                    font.pixelSize: 19
                                    font.bold: true
                                }
                            }

                            ColumnLayout {
                                Layout.alignment: Qt.AlignVCenter
                                Layout.fillWidth: true
                                spacing: 0

                                StyledText {
                                    text: modelData.name
                                    font.pixelSize: 14
                                    font.bold: true
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }

                                StyledText {
                                    visible: modelData.sub !== undefined
                                    text: modelData.sub ?? ""
                                    font.pixelSize: 11
                                    opacity: 0.55
                                }
                            }

                            // Right-hand affordance telling you what Enter does on
                            // the non-application rows; blank for apps.
                            StyledText {
                                text: modelData.hint ?? ""
                                visible: text !== ""
                                color: ShellGlobals.materialColors.ontertiary
                                opacity: 0.6
                                Layout.alignment: Qt.AlignVCenter
                            }
                        }
                    }
                }

                ClipPreview {
                    Layout.preferredWidth: root.clipMode ? 360 : 0
                    Layout.fillHeight: true
                    Layout.topMargin: list.topMargin
                    Layout.bottomMargin: list.bottomMargin
                    entry: root.clipEntry
                    shown: root.clipMode
                }
            }

            TuiFooter {
                Layout.preferredHeight: root.clipMode ? root.footerSpace : 0
                opacity: root.clipMode ? 1 : 0
                visible: opacity > 0
                Behavior on opacity {
                    Anim {
                        time: ShellGlobals.animFast
                    }
                }
                hints: [
                    {
                        key: "↵",
                        label: "copy",
                        action: () => list.currentItem?.activate()
                    },
                    {
                        key: "⇧↵",
                        label: "copy & paste",
                        action: () => {
                            if (root.clipEntry) {
                                Clipboard.paste(root.clipEntry);
                                root.closeRequested();
                            }
                        }
                    },
                    {
                        key: "⇧del",
                        label: "forget",
                        action: () => root.clipEntry && Clipboard.remove(root.clipEntry)
                    },
                    {
                        key: "⇥",
                        label: root.imagesOnly ? "everything" : "images only",
                        action: () => root.imagesOnly = !root.imagesOnly
                    },
                    {
                        key: "esc",
                        label: "close",
                        action: () => root.closeRequested()
                    }
                ]
            }
        }
    }
}

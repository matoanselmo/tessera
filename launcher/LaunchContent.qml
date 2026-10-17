import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs
import qs.components
import qs.services
import "Calculator.js" as Calculator
import "WebSearch.js" as WebSearch
import "Fuzzy.js" as Fuzzy

Item {
    id: root

    // Explicit outward signal. The old code assigned to `persist.launcherOpen`,
    // an id belonging to Controller.qml; that resolves only through QML's
    // context chain and is exactly what `ComponentBehavior: Bound` forbids.
    signal closeRequested

    readonly property string query: search.text.trim()

    // A leading `;` switches to clipboard history; the rest filters it.
    readonly property bool clipMode: search.text.startsWith(";")
    readonly property string clipQuery: search.text.slice(1).trim().toLowerCase()

    onClipModeChanged: {
        if (root.clipMode)
            Clipboard.refresh();
    }

    // Non-application rows. Both return null when the query isn't theirs, so
    // they cost one regex test per keystroke on an ordinary app search.
    readonly property var calcResult: root.clipMode ? null : Calculator.evaluate(root.query)
    readonly property var webAction: root.clipMode ? null : WebSearch.actionFor(root.query, ShellGlobals.searchEngineUrl, ShellGlobals.searchEngineName)

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
        }

        root.closeRequested();
    }

    height: 50 + searchContainer.implicitHeight + list.topMargin * 2 + list.delegateHeight * 10
    width: 600

    Rectangle {
        id: content
        height: 24 + searchContainer.implicitHeight + list.topMargin + list.bottomMargin + Math.min(list.contentHeight, list.delegateHeight * 10)
        Behavior on height {
            Anim {}
        }
        width: parent.width
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
                            // Shift+Delete forgets the selected clipboard entry.
                            if (root.clipMode && event.key == Qt.Key_Delete && (event.modifiers & Qt.ShiftModifier)) {
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
                            text: "Search apps  ·  = maths  ·  ; clipboard"
                            font: search.font
                            color: ShellGlobals.materialColors.onsecondarycontainer
                            opacity: 0.4
                        }
                    }
                }
            }

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
                        // Clipboard mode shows nothing else.
                        if (root.clipMode) {
                            const q = root.clipQuery;
                            return Clipboard.entries.filter(e => q === "" || e.text.toLowerCase().includes(q)).slice(0, 200).map(e => ({
                                kind: "clip",
                                name: e.text,
                                glyph: e.image ? "\u25a3" : "\u29c9",
                                hint: "Copy",
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

                    onValuesChanged: list.currentIndex = 0
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

                    implicitHeight: list.delegateHeight
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
                            Layout.preferredWidth: 32
                            Layout.preferredHeight: 32

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

                        StyledText {
                            text: modelData.name
                            font.pixelSize: 14
                            font.bold: true
                            elide: Text.ElideRight
                            Layout.alignment: Qt.AlignVCenter
                            Layout.fillWidth: true
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
        }
    }
}

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import qs
import qs.components
import qs.services

import "clocks.js" as Clocks

// The settings window: sections on the left, the chosen section's settings on
// the right, in the same terminal style as the bar's panels. Tab moves
// between the two, j/k between rows, h/l changes the selected value, and the
// footer lists whatever else the selected row can do. Everything works with
// the mouse too.
//
// Every row of a section is an entry in `items`, so one cursor and one set of
// keys covers choices, world clocks, bar widgets and wallpapers alike.
Item {
    id: root

    signal closeRequested

    readonly property var sections: [
        {
            id: "clock",
            title: "Clock"
        },
        {
            id: "bar",
            title: "Bar"
        },
        {
            id: "wallpaper",
            title: "Wallpaper"
        },
        {
            id: "motion",
            title: "Motion"
        },
        {
            id: "launcher",
            title: "Launcher"
        },
        {
            id: "about",
            title: "About"
        }
    ]

    property int sectionIndex: 0
    readonly property string section: root.sections[root.sectionIndex].id

    // "sections" or "page": which side the keys drive.
    property string pane: "page"
    property int cursor: 0

    // The world clock being typed in, and what went wrong with the last try.
    property bool editing: false
    property string message: ""

    readonly property int wallpaperColumns: 3
    readonly property int pageMaxHeight: 440

    // The window keeps the tallest size so the card can grow and shrink
    // inside it between sections, the way the keybinds overlay does.
    width: 760
    height: 16 * 2 + header.implicitHeight + 10 + root.pageMaxHeight + 30 + 10 + footer.implicitHeight + 40

    readonly property var items: {
        const choices = Settings.options.filter(o => o.section === root.section).map(o => ({
                    kind: "choice",
                    option: o
                }));

        switch (root.section) {
        case "clock":
            return choices.concat([
                {
                    kind: "heading",
                    text: "World clocks"
                }
            ], Settings.worldClocks.map((c, i) => ({
                        kind: "clock",
                        index: i,
                        clock: c
                    })), [
                {
                    kind: "addclock"
                }
            ]);
        case "bar":
            return choices.concat([
                {
                    kind: "heading",
                    text: "Right side, left to right"
                }
            ], Settings.barWidgets.map((w, i) => ({
                        kind: "widget",
                        index: i,
                        widget: w,
                        info: Settings.widgetCatalog.find(c => c.id === w.id)
                    })));
        case "wallpaper":
            return [
                {
                    kind: "heading",
                    text: `${ShellGlobals.wallpaperDir} · ${Wallpapers.images.length} ${Wallpapers.images.length === 1 ? "image" : "images"}`
                }
            ].concat(Wallpapers.images.map(p => ({
                        kind: "wallpaper",
                        path: p
                    })), choices);
        case "about":
            return [
                {
                    kind: "info",
                    name: "Settings file",
                    value: "~/.config/tessera/settings.json",
                    run: () => Quickshell.execDetached(["xdg-open", Settings.path])
                },
                {
                    kind: "info",
                    name: "Wallpapers",
                    value: ShellGlobals.wallpaperDir,
                    run: () => Wallpapers.openFolder()
                },
                {
                    kind: "info",
                    name: "Source",
                    value: "github.com/matoanselmo/tessera",
                    run: () => Quickshell.execDetached(["xdg-open", "https://github.com/matoanselmo/tessera"])
                }
            ];
        default:
            return choices;
        }
    }

    readonly property var current: root.items[root.cursor] ?? null

    function selectable(item: var): bool {
        return item && item.kind !== "heading";
    }

    function firstSelectable(): int {
        const i = root.items.findIndex(root.selectable);
        return Math.max(0, i);
    }

    function selectSection(index: int): void {
        if (index === root.sectionIndex)
            return;
        root.sectionIndex = (index + root.sections.length) % root.sections.length;
        root.editing = false;
        root.message = "";
        root.cursor = root.firstSelectable();
        pageEnter.restart();
    }

    // Down or up one row; wallpapers are a grid, so they move a whole row of
    // thumbnails and only leave the grid from its first or last row.
    function moveCursor(delta: int): void {
        const item = root.current;
        let to = root.cursor;
        if (item?.kind === "wallpaper") {
            const jump = to + delta * root.wallpaperColumns;
            if (root.items[jump]?.kind === "wallpaper") {
                root.setCursor(jump);
                return;
            }
        }
        do {
            to += delta;
        } while (to >= 0 && to < root.items.length && !root.selectable(root.items[to]))
        if (to >= 0 && to < root.items.length)
            root.setCursor(to);
    }

    function setCursor(index: int): void {
        root.cursor = index;
        root.editing = false;
        root.message = "";
    }

    // h/l: change a choice, or step through the wallpaper grid.
    function sideways(delta: int): void {
        const item = root.current;
        if (item?.kind === "choice")
            Settings.step(item.option.key, delta);
        else if (item?.kind === "wallpaper" && root.items[root.cursor + delta]?.kind === "wallpaper")
            root.setCursor(root.cursor + delta);
    }

    function activate(): void {
        const item = root.current;
        switch (item?.kind) {
        case "choice":
            Settings.next(item.option.key);
            break;
        case "widget":
            Settings.toggleWidget(item.index);
            break;
        case "wallpaper":
            Wallpapers.set(item.path);
            break;
        case "addclock":
            root.startEditing();
            break;
        case "info":
            item.run();
            break;
        }
    }

    function moveWidget(delta: int): void {
        if (root.current?.kind !== "widget")
            return;
        const to = Settings.moveWidget(root.current.index, delta);
        root.cursor += to - root.current.index;
    }

    function removeClock(): void {
        if (root.current?.kind !== "clock")
            return;
        Settings.removeClock(root.current.index);
        root.cursor = Math.min(root.cursor, root.items.length - 1);
    }

    function startEditing(): void {
        root.cursor = root.items.findIndex(i => i.kind === "addclock");
        root.message = "";
        root.editing = true;
        if (root.clockInput) {
            root.clockInput.text = "";
            root.clockInput.forceActiveFocus();
        }
    }

    function stopEditing(): void {
        root.editing = false;
        keys.forceActiveFocus();
    }

    function submitClock(): void {
        const clock = Clocks.parse(root.clockInput?.text ?? "");
        if (!clock) {
            root.message = "Type a city and its UTC offset, e.g. Yangon +6:30";
            return;
        }
        Settings.addClock(clock);
        root.message = `Added ${clock.name}, ${Clocks.format(clock.offsetMinutes)}`;
        root.stopEditing();
        root.cursor = root.items.findIndex(i => i.kind === "addclock");
    }

    // "21:05" in a fixed offset from UTC, in the shell's clock format.
    function timeAt(offsetMinutes: int, now: date): string {
        const shifted = new Date(now.getTime() + (offsetMinutes + now.getTimezoneOffset()) * 60000);
        return ShellGlobals.localiseDigits(Qt.formatTime(shifted, ShellGlobals.timeFormat));
    }

    readonly property var hints: {
        const close = {
            key: "esc",
            label: "close",
            action: () => root.closeRequested()
        };
        const pane = {
            key: "⇥",
            label: root.pane === "page" ? "sections" : "settings",
            action: () => root.pane = root.pane === "page" ? "sections" : "page"
        };

        if (root.editing)
            return [
                {
                    key: "↵",
                    label: "add",
                    action: root.submitClock
                },
                {
                    key: "esc",
                    label: "cancel",
                    action: root.stopEditing
                }
            ];

        if (root.pane === "sections")
            return [
                {
                    key: "j/k",
                    label: "section",
                    action: () => root.selectSection(root.sectionIndex + 1)
                },
                pane,
                close
            ];

        const item = root.current;
        let rows = [];
        switch (item?.kind) {
        case "choice":
            rows = [
                {
                    key: "h/l",
                    label: "change",
                    action: () => root.sideways(1)
                }
            ];
            break;
        case "clock":
            rows = [
                {
                    key: "d",
                    label: "remove",
                    action: root.removeClock
                },
                {
                    key: "a",
                    label: "add clock",
                    action: root.startEditing
                }
            ];
            break;
        case "addclock":
            rows = [
                {
                    key: "↵",
                    label: "add clock",
                    action: root.startEditing
                }
            ];
            break;
        case "widget":
            rows = (item.info.fixed ? [] : [
                    {
                        key: "␣",
                        label: item.widget.shown ? "hide" : "show",
                        action: root.activate
                    }
                ]).concat([
                {
                    key: "J/K",
                    label: "move",
                    action: () => root.moveWidget(1)
                }
            ]);
            break;
        case "wallpaper":
            rows = [
                {
                    key: "↵",
                    label: "set",
                    action: root.activate
                },
                {
                    key: "r",
                    label: "random",
                    action: () => Wallpapers.random()
                },
                {
                    key: "o",
                    label: "open folder",
                    action: () => Wallpapers.openFolder()
                }
            ];
            break;
        case "info":
            rows = [
                {
                    key: "↵",
                    label: "open",
                    action: root.activate
                }
            ];
            break;
        }
        return rows.concat([pane, close]);
    }

    Component.onCompleted: root.cursor = root.firstSelectable()

    // Keeps the selected row in view as the cursor moves through a long page.
    onCursorChanged: Qt.callLater(() => {
        const row = rows.itemAt(root.cursor);
        if (!row)
            return;
        const top = row.y;
        const bottom = row.y + row.height;
        if (top < page.contentY)
            page.contentY = Math.max(0, top - 8);
        else if (bottom > page.contentY + page.height)
            page.contentY = bottom - page.height + 8;
    })

    Item {
        id: keys
        focus: true

        Keys.onPressed: event => {
            const shift = event.modifiers & Qt.ShiftModifier;

            if (event.key === Qt.Key_Escape) {
                root.closeRequested();
            } else if (event.key === Qt.Key_Tab || event.key === Qt.Key_Backtab) {
                root.pane = root.pane === "page" ? "sections" : "page";
            } else if (root.pane === "sections") {
                if (event.key === Qt.Key_J || event.key === Qt.Key_Down)
                    root.selectSection(root.sectionIndex + 1);
                else if (event.key === Qt.Key_K || event.key === Qt.Key_Up)
                    root.selectSection(root.sectionIndex - 1);
                else if (event.key === Qt.Key_L || event.key === Qt.Key_Right || event.key === Qt.Key_Return || event.key === Qt.Key_Enter)
                    root.pane = "page";
                else
                    return;
            } else if (shift && event.key === Qt.Key_J) {
                root.moveWidget(1);
            } else if (shift && event.key === Qt.Key_K) {
                root.moveWidget(-1);
            } else if (event.key === Qt.Key_J || event.key === Qt.Key_Down) {
                root.moveCursor(1);
            } else if (event.key === Qt.Key_K || event.key === Qt.Key_Up) {
                root.moveCursor(-1);
            } else if (event.key === Qt.Key_L || event.key === Qt.Key_Right) {
                root.sideways(1);
            } else if (event.key === Qt.Key_H || event.key === Qt.Key_Left) {
                root.sideways(-1);
            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
                root.activate();
            } else if (event.key === Qt.Key_D || event.key === Qt.Key_Delete) {
                root.removeClock();
            } else if (event.key === Qt.Key_A && root.section === "clock") {
                root.startEditing();
            } else if (event.key === Qt.Key_R && root.section === "wallpaper") {
                Wallpapers.random();
            } else if (event.key === Qt.Key_O && root.section === "wallpaper") {
                Wallpapers.openFolder();
            } else {
                return;
            }
            event.accepted = true;
        }
    }

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    Rectangle {
        id: card
        width: parent.width
        height: column.implicitHeight + 32
        color: ShellGlobals.materialColors.tertiarycontainer
        radius: ShellGlobals.radius
        clip: true

        // Morphs between sections of different heights, like the launcher
        // and keybinds overlays do as their lists change.
        Behavior on height {
            Anim {}
        }

        ColumnLayout {
            id: column
            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                margins: 16
            }
            spacing: 10

            RowLayout {
                id: header
                Layout.fillWidth: true

                StyledText {
                    text: "Settings"
                    font.bold: true
                    font.pixelSize: 15
                }

                Item {
                    Layout.fillWidth: true
                }

                StyledText {
                    text: "~/.config/tessera/settings.json"
                    font.family: ShellGlobals.monoFamily
                    font.pixelSize: 11
                    opacity: 0.5
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                TuiPane {
                    title: "Sections"
                    focused: root.pane === "sections"
                    Layout.fillWidth: false
                    Layout.preferredWidth: 170
                    Layout.fillHeight: true
                    onClicked: root.pane = "sections"

                    TuiTable {
                        columns: [
                            {
                                title: "",
                                width: 0
                            }
                        ]
                        rows: root.sections.map(s => [s.title])
                        currentIndex: root.sectionIndex
                        focused: root.pane === "sections"
                        onSelected: index => {
                            root.pane = "sections";
                            root.selectSection(index);
                        }
                    }
                }

                TuiPane {
                    title: root.sections[root.sectionIndex].title
                    focused: root.pane === "page"
                    Layout.alignment: Qt.AlignTop
                    onClicked: root.pane = "page"

                    Flickable {
                        id: page

                        Layout.fillWidth: true
                        Layout.preferredHeight: Math.min(flow.implicitHeight, root.pageMaxHeight)
                        contentHeight: flow.implicitHeight
                        clip: true
                        boundsBehavior: Flickable.StopAtBounds

                        Behavior on contentY {
                            Anim {}
                        }

                        // Every row, full width, except wallpapers, which sit
                        // three to a line. Fades and drifts in on a section
                        // change, the shell's usual entrance.
                        Flow {
                            id: flow
                            width: page.width
                            spacing: 2

                            transform: Translate {
                                id: drift
                            }

                            ParallelAnimation {
                                id: pageEnter
                                Anim {
                                    target: flow
                                    property: "opacity"
                                    from: 0
                                    to: 1
                                }
                                Anim {
                                    target: drift
                                    property: "y"
                                    from: 6
                                    to: 0
                                }
                            }

                            Repeater {
                                id: rows
                                model: root.items

                                Loader {
                                    id: row

                                    required property var modelData
                                    required property int index
                                    readonly property bool current: row.index === root.cursor && root.pane === "page"

                                    width: row.modelData.kind === "wallpaper" ? (flow.width - flow.spacing * (root.wallpaperColumns - 1)) / root.wallpaperColumns : flow.width
                                    sourceComponent: {
                                        switch (row.modelData.kind) {
                                        case "choice":
                                            return choiceRow;
                                        case "heading":
                                            return headingRow;
                                        case "clock":
                                            return clockRow;
                                        case "addclock":
                                            return addClockRow;
                                        case "widget":
                                            return widgetRow;
                                        case "wallpaper":
                                            return wallpaperTile;
                                        default:
                                            return infoRow;
                                        }
                                    }

                                    // Each row reaches its data and state
                                    // through these, set as it loads.
                                    onLoaded: {
                                        row.item.entry = Qt.binding(() => row.modelData);
                                        row.item.current = Qt.binding(() => row.current);
                                        row.item.index = Qt.binding(() => row.index);
                                    }
                                }
                            }
                        }
                    }
                }
            }

            StyledText {
                Layout.fillWidth: true
                Layout.leftMargin: 4
                visible: root.message !== ""
                text: root.message
                elide: Text.ElideRight
                font.family: ShellGlobals.monoFamily
                font.pixelSize: 11
                opacity: 0.7
            }

            TuiFooter {
                id: footer
                hints: root.hints
            }
        }
    }

    // The highlight every selectable row shares: a tint and an accent edge,
    // fading in and out as the cursor passes.
    component RowBase: Rectangle {
        id: base

        property var entry
        property bool current: false
        property int index: -1

        signal clicked

        implicitHeight: 34
        color: base.current ? Qt.alpha(ShellGlobals.materialColors.tertiary, 0.7) : hover.containsMouse ? Qt.alpha(ShellGlobals.materialColors.tertiary, 0.35) : "transparent"
        radius: ShellGlobals.radius

        Behavior on color {
            CAnim {}
        }

        Rectangle {
            width: 2
            height: parent.height
            color: ShellGlobals.materialColors.secondary
            opacity: base.current ? 1 : 0

            Behavior on opacity {
                Anim {
                    time: ShellGlobals.animFast
                }
            }
        }

        MouseArea {
            id: hover
            anchors.fill: parent
            hoverEnabled: true
            onClicked: {
                root.pane = "page";
                root.setCursor(base.index);
                base.clicked();
            }
        }
    }

    Component {
        id: choiceRow

        RowBase {
            id: r
            implicitHeight: 46

            ColumnLayout {
                anchors.left: parent.left
                anchors.leftMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                spacing: 1

                StyledText {
                    text: r.entry?.option.name ?? ""
                    font.bold: true
                    font.family: ShellGlobals.monoFamily
                    color: r.current ? ShellGlobals.materialColors.onprimarycontainer : ShellGlobals.materialColors.ontertiarycontainer
                }

                StyledText {
                    text: r.entry?.option.description ?? ""
                    font.pixelSize: 11
                    opacity: 0.6
                }
            }

            TuiChoice {
                anchors.right: parent.right
                anchors.rightMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                values: r.entry?.option.values ?? []
                current: r.entry ? Settings[r.entry.option.key] : undefined
                active: r.current
                onPicked: value => {
                    root.pane = "page";
                    root.setCursor(r.index);
                    Settings.set(r.entry.option.key, value);
                }
            }
        }
    }

    Component {
        id: headingRow

        Item {
            property var entry
            property bool current
            property int index

            implicitHeight: 30

            StyledText {
                anchors.left: parent.left
                anchors.leftMargin: 10
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 4
                text: parent.entry?.text ?? ""
                font.bold: true
                font.family: ShellGlobals.monoFamily
                opacity: 0.6
            }
        }
    }

    Component {
        id: clockRow

        RowBase {
            id: r

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 10
                spacing: 12

                StyledText {
                    Layout.fillWidth: true
                    text: r.entry?.clock.name ?? ""
                    elide: Text.ElideRight
                    font.family: ShellGlobals.monoFamily
                }

                StyledText {
                    Layout.preferredWidth: 90
                    text: r.entry ? Clocks.format(r.entry.clock.offsetMinutes) : ""
                    font.family: ShellGlobals.monoFamily
                    opacity: 0.7
                }

                StyledText {
                    Layout.preferredWidth: 70
                    horizontalAlignment: Text.AlignRight
                    text: r.entry ? root.timeAt(r.entry.clock.offsetMinutes, clock.date) : ""
                    font.family: ShellGlobals.monoFamily
                    font.bold: true
                }
            }
        }
    }

    Component {
        id: addClockRow

        RowBase {
            id: r
            onClicked: root.startEditing()

            StyledText {
                anchors.left: parent.left
                anchors.leftMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                visible: !root.editing
                text: "+ add a clock"
                font.family: ShellGlobals.monoFamily
                opacity: 0.6
            }

            Rectangle {
                anchors.fill: parent
                anchors.margins: 4
                anchors.leftMargin: 8
                visible: root.editing
                color: ShellGlobals.materialColors.secondarycontainer
                radius: ShellGlobals.radius

                // Lives in the row, but the root needs to reach it.
                Component.onCompleted: root.clockInput = input

                TextInput {
                    id: input
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    verticalAlignment: TextInput.AlignVCenter
                    color: ShellGlobals.materialColors.onsecondarycontainer
                    font.family: ShellGlobals.monoFamily
                    font.pixelSize: 12

                    Keys.onReturnPressed: root.submitClock()
                    Keys.onEnterPressed: root.submitClock()
                    Keys.onEscapePressed: root.stopEditing()

                    StyledText {
                        anchors.fill: parent
                        verticalAlignment: Text.AlignVCenter
                        visible: input.text === ""
                        text: "City and UTC offset, e.g. Yangon +6:30"
                        font: input.font
                        opacity: 0.4
                    }
                }
            }
        }
    }

    // The add-a-clock field, once its row exists.
    property Item clockInput: null

    Component {
        id: widgetRow

        RowBase {
            id: r

            readonly property bool fixed: r.entry?.info.fixed ?? false
            readonly property bool shown: r.entry?.widget.shown ?? true

            onClicked: Settings.toggleWidget(r.entry.index)

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 10
                spacing: 12

                StyledText {
                    Layout.preferredWidth: 28
                    text: r.fixed ? "[•]" : r.shown ? "[x]" : "[ ]"
                    font.family: ShellGlobals.monoFamily
                    color: r.shown ? ShellGlobals.materialColors.secondary : ShellGlobals.materialColors.ontertiarycontainer
                    opacity: r.fixed ? 0.5 : 1

                    Behavior on color {
                        CAnim {}
                    }
                }

                StyledText {
                    Layout.fillWidth: true
                    text: r.entry?.info.name ?? ""
                    font.family: ShellGlobals.monoFamily
                    opacity: r.shown ? 1 : 0.5

                    Behavior on opacity {
                        Anim {
                            time: ShellGlobals.animFast
                        }
                    }
                }

                StyledText {
                    text: r.entry?.info.note ?? ""
                    font.family: ShellGlobals.monoFamily
                    font.pixelSize: 11
                    opacity: 0.5
                }
            }
        }
    }

    Component {
        id: wallpaperTile

        RowBase {
            id: r

            readonly property bool chosen: r.entry?.path === Wallpapers.path

            implicitHeight: width * 9 / 16
            onClicked: Wallpapers.set(r.entry.path)

            Image {
                anchors.fill: parent
                anchors.margins: 4
                source: r.entry ? `file://${r.entry.path}` : ""
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                // Thumbnails, not wallpapers: decode small.
                sourceSize.width: 320
                opacity: status === Image.Ready ? 1 : 0

                Behavior on opacity {
                    Anim {}
                }
            }

            Rectangle {
                anchors.fill: parent
                color: "transparent"
                border.width: 2
                border.color: ShellGlobals.materialColors.secondary
                radius: ShellGlobals.radius
                opacity: r.chosen ? 1 : 0

                Behavior on opacity {
                    Anim {
                        time: ShellGlobals.animFast
                    }
                }
            }

            Rectangle {
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.margins: 8
                width: tag.implicitWidth + 10
                height: 18
                color: ShellGlobals.materialColors.secondary
                opacity: r.chosen ? 1 : 0

                Behavior on opacity {
                    Anim {
                        time: ShellGlobals.animFast
                    }
                }

                StyledText {
                    id: tag
                    anchors.centerIn: parent
                    text: "current"
                    font.pixelSize: 10
                    font.bold: true
                    color: ShellGlobals.materialColors.onsecondary
                }
            }
        }
    }

    Component {
        id: infoRow

        RowBase {
            id: r
            onClicked: r.entry.run()

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 10

                StyledText {
                    Layout.fillWidth: true
                    text: r.entry?.name ?? ""
                    font.bold: true
                    font.family: ShellGlobals.monoFamily
                }

                StyledText {
                    text: r.entry?.value ?? ""
                    font.family: ShellGlobals.monoFamily
                    opacity: 0.7
                }
            }
        }
    }
}

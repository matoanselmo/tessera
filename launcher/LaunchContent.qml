import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs
import qs.components
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

    // Non-application rows. Both return null when the query isn't theirs, so
    // they cost one regex test per keystroke on an ordinary app search.
    readonly property var calcResult: Calculator.evaluate(root.query)
    readonly property var webAction: WebSearch.actionFor(root.query, ShellGlobals.searchEngineUrl, ShellGlobals.searchEngineName)

    function runEntry(entry: var): void {
        if (!entry)
            return;

        switch (entry.kind) {
        case "app":
            entry.entry.execute();
            break;
        case "calc":
            // `--` because a negative result is otherwise read as a flag.
            Quickshell.execDetached(["wl-copy", "--", entry.copy]);
            break;
        case "web":
            Quickshell.execDetached(["xdg-open", entry.url]);
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
            NumberAnimation {
                duration: 200
                easing.type: Easing.OutCubic
            }
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
                    // Searched on the trimmed query, like the calculator and web rows.
                    readonly property var appRows: Fuzzy.rank(root.query, DesktopEntries.applications.values, app => app.name).map(app => ({
                        kind: "app",
                        entry: app,
                        name: app.name,
                        icon: app.icon,
                        hint: ""
                    }))

                    values: {
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
                    NumberAnimation {
                        property: "opacity"
                        from: 0
                        to: 1
                        duration: 100
                    }
                }

                displaced: Transition {
                    NumberAnimation {
                        property: "y"
                        duration: 200
                        easing.type: Easing.OutCubic
                    }
                    NumberAnimation {
                        property: "opacity"
                        to: 1
                        duration: 100
                    }
                }

                move: Transition {
                    NumberAnimation {
                        property: "y"
                        duration: 200
                        easing.type: Easing.OutCubic
                    }
                    NumberAnimation {
                        property: "opacity"
                        to: 1
                        duration: 100
                    }
                }

                remove: Transition {
                    NumberAnimation {
                        property: "y"
                        duration: 200
                        easing.type: Easing.OutCubic
                    }
                    NumberAnimation {
                        property: "opacity"
                        to: 0
                        duration: 100
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

import QtQuick
import QtQuick.Layouts
import Quickshell
import qs
import qs.components
import qs.services

import "../services/Procs.js" as Procs

// A pocket btop, in the same terminal style as the other panels: a CPU pane
// (a two-minute usage graph and a meter per core), a memory pane, and the
// busiest apps. j/k or the arrows move through the list, s switches it
// between CPU and memory order, g between apps and single processes, and x
// twice sends the selected one SIGTERM (an app's main process, so the whole
// app quits).
BarPanel {
    id: panel

    implicitWidth: 560
    contentHeight: column.implicitHeight + ShellGlobals.popupPadding * 2

    readonly property int processRows: 12

    readonly property var shown: Procs.top(SystemStats.groupByApp ? SystemStats.apps : SystemStats.processes, SystemStats.sortBy, panel.processRows)
    readonly property var selected: panel.shown[table.currentIndex] ?? null

    // The cursor follows a process rather than a row, so the list re-sorting
    // under it every couple of seconds does not move the selection.
    property int selectedPid: -1
    // The pid `x` was pressed on once; a second press on the same one kills it.
    property int armedPid: -1
    property string message: ""

    readonly property bool shouldShow: SystemStats.panelOpen

    onShouldShowChanged: panel.shouldShow ? panel.open() : panel.close()
    onOpened: {
        panel.selectedPid = -1;
        panel.armedPid = -1;
        panel.message = "";
        table.currentIndex = 0;
    }
    onHidden: SystemStats.panelOpen = false

    onShownChanged: {
        const i = panel.shown.findIndex(p => p.pid === panel.selectedPid);
        if (i >= 0)
            table.currentIndex = i;
    }

    function select(index: int): void {
        table.currentIndex = index;
        panel.selectedPid = panel.shown[index]?.pid ?? -1;
        panel.armedPid = -1;
    }

    function setSort(key: string): void {
        SystemStats.sortBy = key;
        panel.armedPid = -1;
    }

    function toggleGroup(): void {
        SystemStats.groupByApp = !SystemStats.groupByApp;
        panel.armedPid = -1;
    }

    function kill(): void {
        const p = panel.selected;
        if (!p)
            return;
        if (panel.armedPid !== p.pid) {
            panel.armedPid = p.pid;
            panel.message = `Press x again to end ${p.name} (${p.pid})`;
            return;
        }
        SystemStats.terminate(p.pid);
        panel.armedPid = -1;
        panel.message = `Sent SIGTERM to ${p.name} (${p.pid})`;
    }

    // `3 d 4 h`, `4 h 12 min` or `12 min`.
    function duration(seconds: real): string {
        const minutes = Math.floor(seconds / 60);
        const d = Math.floor(minutes / 1440);
        const h = Math.floor(minutes / 60) % 24;
        const m = minutes % 60;
        if (d > 0)
            return `${d} d ${h} h`;
        return h > 0 ? `${h} h ${m} min` : `${m} min`;
    }

    function gib(kib: real): string {
        return (kib / 1048576).toFixed(1);
    }

    function meter(name: string, used: real, total: real): string {
        const pct = total > 0 ? 100 * used / total : 0;
        return `${name.padEnd(6)}${Procs.bar(pct, 24)} ${panel.gib(used).padStart(5)} / ${panel.gib(total)} GiB ${`${Math.round(pct)}%`.padStart(4)}`;
    }

    readonly property var hints: {
        const rows = [
            { key: "s", label: SystemStats.sortBy === "cpu" ? "sort by mem" : "sort by cpu", action: () => panel.setSort(SystemStats.sortBy === "cpu" ? "mem" : "cpu") },
            { key: "g", label: SystemStats.groupByApp ? "processes" : "apps", action: panel.toggleGroup }
        ];
        if (panel.selected)
            rows.push({ key: "x", label: panel.armedPid === panel.selected.pid ? "confirm kill" : "kill", action: panel.kill });
        rows.push({ key: "esc", label: "close", action: panel.close });
        return rows;
    }

    Item {
        anchors.fill: parent
        focus: true

        Keys.onPressed: event => {
            if (event.key === Qt.Key_J || event.key === Qt.Key_Down) {
                panel.select(Math.min(panel.shown.length - 1, table.currentIndex + 1));
            } else if (event.key === Qt.Key_K || event.key === Qt.Key_Up) {
                panel.select(Math.max(0, table.currentIndex - 1));
            } else if (event.key === Qt.Key_S || event.key === Qt.Key_Tab) {
                panel.setSort(SystemStats.sortBy === "cpu" ? "mem" : "cpu");
            } else if (event.key === Qt.Key_G) {
                panel.toggleGroup();
            } else if (event.key === Qt.Key_C) {
                panel.setSort("cpu");
            } else if (event.key === Qt.Key_M) {
                panel.setSort("mem");
            } else if (event.key === Qt.Key_X || event.key === Qt.Key_Delete) {
                panel.kill();
            } else {
                return;
            }
            event.accepted = true;
        }
    }

    ColumnLayout {
        id: column
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            margins: ShellGlobals.popupPadding
        }
        spacing: 6

        TuiPane {
            title: "CPU"

            StyledText {
                Layout.fillWidth: true
                text: {
                    const load = SystemStats.loadAverage.map(v => v.toFixed(2)).join(" ");
                    return `${String(SystemStats.cpuPercent).padStart(3)}%   load ${load}   up ${panel.duration(SystemStats.uptime)}`;
                }
                font.family: ShellGlobals.monoFamily
                font.bold: true
            }

            // The last two minutes, one bar per reading, newest on the right.
            Item {
                id: graph

                Layout.fillWidth: true
                Layout.topMargin: 4
                Layout.bottomMargin: 6
                implicitHeight: 48

                readonly property real step: graph.width / SystemStats.historyLength

                Rectangle {
                    anchors.fill: parent
                    color: "transparent"
                    border.width: 1
                    border.color: Qt.alpha(ShellGlobals.materialColors.ontertiarycontainer, 0.15)
                }

                Repeater {
                    model: SystemStats.cpuHistory.length

                    Rectangle {
                        required property int index

                        readonly property int value: SystemStats.cpuHistory[index] ?? 0

                        x: graph.width - (SystemStats.cpuHistory.length - index) * graph.step
                        width: Math.max(1, graph.step - 1)
                        height: Math.max(1, graph.height * value / 100)
                        anchors.bottom: parent.bottom
                        color: value >= 90 ? ShellGlobals.materialColors.error : value >= 60 ? ShellGlobals.materialColors.tertiary : ShellGlobals.materialColors.secondary
                    }
                }
            }

            GridLayout {
                Layout.fillWidth: true
                columns: SystemStats.corePercents.length > 8 ? 4 : 2
                columnSpacing: 16
                rowSpacing: 0

                Repeater {
                    model: SystemStats.corePercents.length

                    StyledText {
                        required property int index

                        readonly property int value: SystemStats.corePercents[index] ?? 0

                        Layout.fillWidth: true
                        text: `C${String(index).padEnd(3)}${Procs.bar(value, 8)} ${String(value).padStart(3)}%`
                        font.family: ShellGlobals.monoFamily
                        font.pixelSize: 11
                        color: value >= 90 ? ShellGlobals.materialColors.error : ShellGlobals.materialColors.ontertiarycontainer
                    }
                }
            }
        }

        TuiPane {
            title: "Memory"

            Repeater {
                model: [
                    panel.meter("used", SystemStats.memUsed, SystemStats.memTotal),
                    panel.meter("cache", SystemStats.memCached, SystemStats.memTotal)
                ].concat(SystemStats.swapTotal > 0 ? [panel.meter("swap", SystemStats.swapUsed, SystemStats.swapTotal)] : [])

                StyledText {
                    required property string modelData

                    Layout.fillWidth: true
                    text: modelData
                    font.family: ShellGlobals.monoFamily
                    font.pixelSize: 11
                }
            }
        }

        TuiPane {
            title: `${SystemStats.groupByApp ? "Apps" : "Processes"} · by ${SystemStats.sortBy}`
            focused: true

            TuiTable {
                id: table
                focused: true
                columns: [
                    { title: "Pid", width: 56 },
                    { title: SystemStats.groupByApp ? "App" : "Program", width: 0 },
                    { title: "Mem", width: 52 },
                    { title: "Mem%", width: 48 },
                    { title: "Cpu%", width: 48 }
                ]
                // An app's helper processes show as a count after its name.
                rows: panel.shown.map(p => [String(p.pid), p.count > 1 ? `${p.name} ×${p.count}` : p.name, Procs.size(p.rss), p.mem.toFixed(1), p.cpu.toFixed(1)])
                emptyText: "Reading processes…"
                onSelected: index => panel.select(index)
                onScrolled: (index, delta) => panel.select(index)
            }
        }

        StyledText {
            Layout.fillWidth: true
            Layout.leftMargin: 4
            text: panel.message !== "" ? panel.message : `${SystemStats.apps.length} apps · ${SystemStats.processes.length} processes`
            elide: Text.ElideRight
            font.family: ShellGlobals.monoFamily
            font.pixelSize: 11
            opacity: 0.7
        }

        TuiFooter {
            hints: panel.hints
        }
    }
}

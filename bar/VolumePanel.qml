import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire
import qs
import qs.components
import qs.services

// Audio in the same terminal style as the network and bluetooth panels: a
// Devices pane (outputs and inputs, `*` on the defaults) and an Applications
// pane (one row per app playing sound). h/l or the arrows change the selected
// row's volume, m mutes it, Enter makes a device the default; scrolling over
// a row works too.
BarPanel {
    id: panel

    implicitWidth: 560
    implicitHeight: column.implicitHeight + ShellGlobals.popupPadding * 2

    property string pane: "devices"
    readonly property var panes: ["devices", "apps"]

    // Outputs first, then inputs.
    readonly property var devices: Audio.sinks.concat(Audio.sources)
    readonly property var device: panel.devices[deviceTable.currentIndex] ?? null
    readonly property var app: Audio.streams[appTable.currentIndex] ?? null
    readonly property var selected: panel.pane === "devices" ? panel.device : panel.app

    readonly property real step: 0.05

    readonly property bool shouldShow: Audio.panelOpen

    onShouldShowChanged: panel.shouldShow ? panel.open() : panel.close()
    onOpened: {
        panel.pane = "devices";
        deviceTable.currentIndex = Math.max(0, panel.devices.indexOf(Audio.sink));
    }
    onHidden: Audio.panelOpen = false

    // `██████░░░░  60%`, or `muted`.
    function level(node: var): string {
        if (!node?.audio)
            return "-";
        if (node.audio.muted)
            return "muted";
        const v = Math.max(0, Math.min(1, node.audio.volume));
        const filled = Math.round(v * 10);
        return `${"█".repeat(filled)}${"░".repeat(10 - filled)} ${String(Math.round(v * 100)).padStart(3)}%`;
    }

    function deviceName(node: var): string {
        return node.nickname || node.description || node.name;
    }

    function appName(node: var): string {
        const p = node.properties ?? {};
        const app = p["application.name"] || node.description || node.name;
        const media = p["media.name"];
        return media && media !== app ? `${app}: ${media}` : app;
    }

    function cyclePane(delta: int): void {
        const i = panel.panes.indexOf(panel.pane);
        panel.pane = panel.panes[(i + delta + panel.panes.length) % panel.panes.length];
    }

    readonly property var hints: {
        const node = panel.selected;
        const rows = node ? [
            { key: "h", label: "quieter", action: () => Audio.nudgeNode(node, -panel.step) },
            { key: "l", label: "louder", action: () => Audio.nudgeNode(node, panel.step) },
            { key: "m", label: node.audio?.muted ? "unmute" : "mute", action: () => Audio.toggleNodeMute(node) }
        ] : [];

        if (panel.pane === "devices" && node && node !== Audio.sink && node !== Audio.source)
            rows.push({ key: "↵", label: "make default", action: () => Audio.setDefault(node) });

        return rows.concat([
            { key: "⇥", label: "pane", action: () => panel.cyclePane(1) },
            { key: "esc", label: "close", action: panel.close }
        ]);
    }

    Item {
        anchors.fill: parent
        focus: true

        Keys.onPressed: event => {
            const table = panel.pane === "devices" ? deviceTable : appTable;

            if (event.key === Qt.Key_Tab || event.key === Qt.Key_Backtab) {
                panel.cyclePane(event.key === Qt.Key_Tab ? 1 : -1);
            } else if (event.key === Qt.Key_J || event.key === Qt.Key_Down) {
                table.move(1);
            } else if (event.key === Qt.Key_K || event.key === Qt.Key_Up) {
                table.move(-1);
            } else if (event.key === Qt.Key_L || event.key === Qt.Key_Right) {
                Audio.nudgeNode(panel.selected, panel.step);
            } else if (event.key === Qt.Key_H || event.key === Qt.Key_Left) {
                Audio.nudgeNode(panel.selected, -panel.step);
            } else if (event.key === Qt.Key_M) {
                Audio.toggleNodeMute(panel.selected);
            } else if ((event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) && panel.pane === "devices" && panel.device) {
                Audio.setDefault(panel.device);
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
            title: "Devices"
            focused: panel.pane === "devices"
            onClicked: panel.pane = "devices"

            TuiTable {
                id: deviceTable
                focused: panel.pane === "devices"
                columns: [
                    { title: "", width: 12 },
                    { title: "Type", width: 40 },
                    { title: "Name", width: 0 },
                    { title: "Volume", width: 136 }
                ]
                rows: panel.devices.map(n => [n === Audio.sink || n === Audio.source ? "*" : "", n.isSink ? "out" : "in", panel.deviceName(n), panel.level(n)])
                emptyText: "No audio devices"
                onSelected: panel.pane = "devices"
                onActivated: index => Audio.setDefault(panel.devices[index])
                onScrolled: (index, delta) => {
                    panel.pane = "devices";
                    Audio.nudgeNode(panel.devices[index], delta > 0 ? panel.step : -panel.step);
                }
            }
        }

        TuiPane {
            title: "Applications"
            focused: panel.pane === "apps"
            onClicked: panel.pane = "apps"

            TuiTable {
                id: appTable
                focused: panel.pane === "apps"
                columns: [
                    { title: "Name", width: 0 },
                    { title: "Volume", width: 136 }
                ]
                rows: Audio.streams.map(n => [panel.appName(n), panel.level(n)])
                emptyText: "Nothing is playing"
                onSelected: panel.pane = "apps"
                onScrolled: (index, delta) => {
                    panel.pane = "apps";
                    Audio.nudgeNode(Audio.streams[index], delta > 0 ? panel.step : -panel.step);
                }
            }
        }

        TuiFooter {
            hints: panel.hints
        }
    }
}

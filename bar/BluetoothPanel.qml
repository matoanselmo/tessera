import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth
import qs
import qs.components
import qs.services

// Bluetooth, laid out after bluetui: the adapter, paired devices, and devices
// found by a scan, each in its own pane, with bluetui's keys. Tab moves
// between panes, j/k or the arrows between rows, and the footer lists what
// the focused pane can do (each hint is clickable too).
BarPanel {
    id: panel

    implicitWidth: 540
    contentHeight: column.implicitHeight + ShellGlobals.popupPadding * 2

    readonly property var adapter: BluetoothState.adapter

    // Panes, top to bottom; "new" only once a scan has found something.
    property string pane: "paired"
    readonly property var panes: ["adapter", "paired"].concat(BluetoothState.scanning || BluetoothState.unpaired.length > 0 ? ["new"] : [])

    readonly property var pairedDevice: BluetoothState.paired[pairedTable.currentIndex] ?? null
    readonly property var newDevice: BluetoothState.unpaired[newTable.currentIndex] ?? null

    // A scan started from here stops when the panel closes.
    property bool startedScan: false

    readonly property bool shouldShow: BluetoothState.panelOpen

    onShouldShowChanged: panel.shouldShow ? panel.open() : panel.close()
    onOpened: panel.pane = BluetoothState.paired.length > 0 ? "paired" : "adapter"
    onHidden: {
        BluetoothState.panelOpen = false;
        if (panel.startedScan) {
            BluetoothState.setScanning(false);
            panel.startedScan = false;
        }
    }

    // A pane that disappears (scan results cleared) hands focus back.
    onPanesChanged: {
        if (!panel.panes.includes(panel.pane))
            panel.pane = "paired";
    }

    function yesNo(value: bool): string {
        return value ? "yes" : "no";
    }

    function cyclePane(delta: int): void {
        const i = panel.panes.indexOf(panel.pane);
        panel.pane = panel.panes[(i + delta + panel.panes.length) % panel.panes.length];
    }

    function toggleScan(): void {
        const on = !BluetoothState.scanning;
        BluetoothState.setScanning(on);
        panel.startedScan = on;
    }

    function toggleConnection(device: var): void {
        if (!device)
            return;
        if (device.connected)
            device.disconnect();
        else
            device.connect();
    }

    function pair(device: var): void {
        if (device && !device.pairing)
            device.pair();
    }

    readonly property var hints: {
        const common = [
            { key: "⇥", label: "pane", action: () => panel.cyclePane(1) },
            { key: "s", label: BluetoothState.scanning ? "stop scan" : "scan", action: panel.toggleScan },
            { key: "esc", label: "close", action: panel.close }
        ];

        if (panel.pane === "adapter" && panel.adapter) {
            return [
                { key: "o", label: BluetoothState.powered ? "power off" : "power on", action: () => BluetoothState.setPowered(!BluetoothState.powered) },
                { key: "p", label: panel.adapter.pairable ? "not pairable" : "pairable", action: () => panel.adapter.pairable = !panel.adapter.pairable },
                { key: "d", label: panel.adapter.discoverable ? "hide" : "discoverable", action: () => panel.adapter.discoverable = !panel.adapter.discoverable }
            ].concat(common);
        }

        if (panel.pane === "paired" && panel.pairedDevice) {
            const d = panel.pairedDevice;
            return [
                { key: "␣", label: d.connected ? "disconnect" : "connect", action: () => panel.toggleConnection(d) },
                { key: "t", label: d.trusted ? "untrust" : "trust", action: () => d.trusted = !d.trusted },
                { key: "u", label: "unpair", action: () => d.forget() }
            ].concat(common);
        }

        if (panel.pane === "new" && panel.newDevice)
            return [{ key: "p", label: "pair", action: () => panel.pair(panel.newDevice) }].concat(common);

        return common;
    }

    // Keys mirror the footer, so a key does exactly what its hint says.
    function runKey(key: string): bool {
        const hint = panel.hints.find(h => h.key === key);
        if (!hint)
            return false;
        hint.action();
        return true;
    }

    Item {
        anchors.fill: parent
        focus: true

        Keys.onPressed: event => {
            const table = panel.pane === "paired" ? pairedTable : panel.pane === "new" ? newTable : null;

            if (event.key === Qt.Key_Tab || event.key === Qt.Key_Backtab) {
                panel.cyclePane(event.key === Qt.Key_Tab ? 1 : -1);
            } else if (event.key === Qt.Key_J || event.key === Qt.Key_Down) {
                table?.move(1);
            } else if (event.key === Qt.Key_K || event.key === Qt.Key_Up) {
                table?.move(-1);
            } else if (event.key === Qt.Key_Space || event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                if (panel.pane === "paired")
                    panel.toggleConnection(panel.pairedDevice);
                else if (panel.pane === "new")
                    panel.pair(panel.newDevice);
            } else if (!panel.runKey(event.text.toLowerCase())) {
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
            title: "Adapter"
            focused: panel.pane === "adapter"
            onClicked: panel.pane = "adapter"

            TuiTable {
                focused: panel.pane === "adapter"
                columns: [
                    { title: "Name", width: 0 },
                    { title: "Powered", width: 64 },
                    { title: "Pairable", width: 72 },
                    { title: "Discoverable", width: 104 },
                    { title: "Scanning", width: 72 }
                ]
                rows: panel.adapter ? [[panel.adapter.name, panel.yesNo(panel.adapter.enabled), panel.yesNo(panel.adapter.pairable), panel.yesNo(panel.adapter.discoverable), panel.yesNo(panel.adapter.discovering)]] : []
                emptyText: "No Bluetooth adapter"
                onSelected: panel.pane = "adapter"
            }
        }

        TuiPane {
            title: "Paired Devices"
            focused: panel.pane === "paired"
            onClicked: panel.pane = "paired"

            TuiTable {
                id: pairedTable
                focused: panel.pane === "paired"
                columns: [
                    { title: "Name", width: 0 },
                    { title: "Trusted", width: 64 },
                    { title: "Connected", width: 80 },
                    { title: "Battery", width: 64 }
                ]
                rows: BluetoothState.paired.map(d => [
                    d.name,
                    panel.yesNo(d.trusted),
                    d.state === BluetoothDeviceState.Connecting ? "…" : d.state === BluetoothDeviceState.Disconnecting ? "…" : panel.yesNo(d.connected),
                    d.batteryAvailable ? `${Math.round(d.battery * 100)}%` : "-"
                ])
                emptyText: "No paired devices"
                onSelected: panel.pane = "paired"
                onActivated: index => panel.toggleConnection(BluetoothState.paired[index])
            }
        }

        TuiPane {
            visible: panel.panes.includes("new")
            title: BluetoothState.scanning ? "New Devices (scanning…)" : "New Devices"
            focused: panel.pane === "new"
            onClicked: panel.pane = "new"

            TuiTable {
                id: newTable
                focused: panel.pane === "new"
                columns: [
                    { title: "Address", width: 136 },
                    { title: "Name", width: 0 }
                ]
                // Scans turn up dozens of nameless beacons; named devices sort
                // first, so the first few are the ones worth pairing.
                rows: BluetoothState.unpaired.slice(0, 8).map(d => [d.address, d.pairing ? `${d.deviceName || "-"} (pairing…)` : d.deviceName || "-"])
                emptyText: "Nothing found yet"
                onSelected: panel.pane = "new"
                onActivated: index => panel.pair(BluetoothState.unpaired[index])
            }
        }

        TuiFooter {
            hints: panel.hints
        }
    }
}

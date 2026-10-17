pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Bluetooth

// The default Bluetooth adapter and its devices, split the way bluetui shows
// them, plus the open state of the bluetooth panel. The panel is created per
// screen, so its state and the IPC target live here to register once.
//
//     qs ipc call bluetooth toggle|open|close
Singleton {
    id: root

    property bool panelOpen: false

    readonly property BluetoothAdapter adapter: Bluetooth.defaultAdapter
    readonly property bool powered: root.adapter?.enabled ?? false
    readonly property bool scanning: root.adapter?.discovering ?? false

    readonly property var devices: root.adapter ? [...root.adapter.devices.values] : []
    readonly property var paired: root.devices.filter(d => d.paired).sort((a, b) => a.name.localeCompare(b.name))
    readonly property var connected: root.paired.filter(d => d.connected)

    // Found by a scan. Named devices first: the nameless ones are mostly
    // beacons and neighbours' gadgets.
    readonly property var unpaired: root.devices.filter(d => !d.paired).sort((a, b) => (b.deviceName !== "") - (a.deviceName !== "") || a.name.localeCompare(b.name))

    // Icon file name in bar/icons.
    readonly property string icon: {
        if (!root.powered)
            return "bluetooth-off.svg";
        return root.connected.length > 0 ? "bluetooth.svg" : "bluetooth-idle.svg";
    }

    readonly property string summary: {
        if (!root.adapter)
            return "No Bluetooth adapter";
        if (!root.powered)
            return "Bluetooth off";
        if (root.connected.length === 0)
            return "Bluetooth on, nothing connected";
        return `Connected: ${root.connected.map(d => d.name).join(", ")}`;
    }

    function setPowered(on: bool): void {
        if (root.adapter)
            root.adapter.enabled = on;
    }

    function setScanning(on: bool): void {
        if (root.adapter)
            root.adapter.discovering = on;
    }

    IpcHandler {
        target: "bluetooth"

        function toggle(): void {
            root.panelOpen = !root.panelOpen;
        }

        function open(): void {
            root.panelOpen = true;
        }

        function close(): void {
            root.panelOpen = false;
        }
    }
}

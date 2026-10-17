pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Networking

import "Nmcli.js" as Nmcli

// Wired and Wi-Fi state for the bar, and the network list for the network
// panel, whose open state and IPC target live here to register once.
//
// Quickshell's Networking module only covers Wi-Fi, so device and connection
// state comes from nmcli instead, re-read whenever `nmcli monitor` reports a
// change. The list of Wi-Fi networks comes from Networking, which only fills
// it while the scanner runs, so it scans just while the panel is open.
//
//     qs ipc call network toggle|open|close
Singleton {
    id: root

    property bool panelOpen: false

    // `{ device, type, state, connection }` per nmcli device, e.g.
    // `{ device: "enp7s0", type: "ethernet", state: "connected", ... }`.
    property var devices: []

    readonly property var wired: root.devices.find(d => d.type === "ethernet") ?? null
    readonly property var wifiDevice: root.devices.find(d => d.type === "wifi") ?? null
    readonly property bool wiredUp: root.wired?.state === "connected"
    readonly property bool wifiUp: root.wifiDevice?.state === "connected"

    // IPv4 address with prefix of whichever connection is up, e.g. "192.168.1.20/24".
    property string address: ""
    // Signal of the connected Wi-Fi network, 0-100.
    property int wifiSignal: 0

    readonly property bool wifiEnabled: Networking.wifiEnabled
    readonly property var wifi: Networking.devices.values.find(d => d.networks !== undefined) ?? null

    readonly property var networks: root.wifi ? [...root.wifi.networks.values] : []
    // Strongest first, the connected network always on top.
    readonly property var knownNetworks: root.networks.filter(n => n.known).sort((a, b) => (b.connected - a.connected) || (b.signalStrength - a.signalStrength))
    readonly property var newNetworks: root.networks.filter(n => !n.known && n.name !== "").sort((a, b) => b.signalStrength - a.signalStrength)

    // NetworkManager's connectivity check, in its own order: unknown, none,
    // captive portal, limited, full.
    readonly property string connectivity: ["unknown", "none", "captive portal", "limited", "full"][Networking.connectivity] ?? "unknown"

    // Icon file name in bar/icons.
    readonly property string icon: {
        if (root.wiredUp)
            return "wired.svg";
        if (root.wifiUp) {
            if (root.wifiSignal >= 75)
                return "wifi-excellent.svg";
            if (root.wifiSignal >= 50)
                return "wifi-good.svg";
            if (root.wifiSignal >= 25)
                return "wifi-ok.svg";
            return "wifi-weak.svg";
        }
        return root.wifiEnabled || root.wired ? "offline.svg" : "wifi-off.svg";
    }

    readonly property string summary: {
        if (root.wiredUp)
            return `Wired: ${root.wired.connection}`;
        if (root.wifiUp)
            return `Wi-Fi: ${root.wifiDevice.connection} (${root.wifiSignal}%)`;
        return "Offline";
    }

    function setWifiEnabled(on: bool): void {
        Networking.wifiEnabled = on;
    }

    function refresh(): void {
        deviceQuery.running = true;
    }

    Binding {
        when: root.wifi !== null
        target: root.wifi
        property: "scannerEnabled"
        value: root.panelOpen
    }

    Process {
        id: deviceQuery
        command: ["nmcli", "-t", "-f", "DEVICE,TYPE,STATE,CONNECTION", "device"]

        stdout: StdioCollector {
            onStreamFinished: {
                root.devices = text.split("\n").filter(l => l !== "").map(l => {
                    const [device, type, state, connection] = Nmcli.splitTerse(l);
                    return { device, type, state, connection };
                }).filter(d => d.type === "ethernet" || d.type === "wifi");

                const up = root.wiredUp ? root.wired : root.wifiUp ? root.wifiDevice : null;
                if (up) {
                    addressQuery.command = ["nmcli", "-g", "IP4.ADDRESS", "device", "show", up.device];
                    addressQuery.running = true;
                } else {
                    root.address = "";
                }

                if (root.wifiUp)
                    signalQuery.running = true;
            }
        }
    }

    Process {
        id: addressQuery

        stdout: StdioCollector {
            onStreamFinished: root.address = text.split("\n")[0].split(" | ")[0].trim()
        }
    }

    Process {
        id: signalQuery
        command: ["nmcli", "-t", "-f", "IN-USE,SIGNAL", "device", "wifi", "list", "--rescan", "no"]

        stdout: StdioCollector {
            onStreamFinished: {
                const active = text.split("\n").find(l => l.startsWith("*"));
                root.wifiSignal = active ? parseInt(Nmcli.splitTerse(active)[1]) || 0 : 0;
            }
        }
    }

    // One line per change; bursts are common, so coalesce them.
    Process {
        id: monitor
        running: true
        command: ["nmcli", "monitor"]

        stdout: SplitParser {
            onRead: settle.restart()
        }

        onExited: reconnect.start()
    }

    Timer {
        id: settle
        interval: 300
        onTriggered: root.refresh()
    }

    Timer {
        id: reconnect
        interval: 2000
        onTriggered: {
            monitor.running = true;
            root.refresh();
        }
    }

    // Signal strength drifts without NetworkManager saying so.
    Timer {
        running: root.wifiUp
        interval: 30000
        repeat: true
        onTriggered: signalQuery.running = true
    }

    Component.onCompleted: root.refresh()

    IpcHandler {
        target: "network"

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

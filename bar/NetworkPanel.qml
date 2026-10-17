import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Networking
import qs
import qs.components
import qs.services

// Wired and Wi-Fi, laid out after impala (bluetui's Wi-Fi sibling): devices,
// known networks and new networks in their own panes, a password pane when a
// secured network needs one, and a key-hint footer. Tab moves between panes,
// j/k or the arrows between rows; every hint is clickable too.
BarPanel {
    id: panel

    implicitWidth: 560
    implicitHeight: column.implicitHeight + ShellGlobals.popupPadding * 2

    property string pane: "known"
    readonly property var panes: ["devices", "known", "new"]

    readonly property var knownNetwork: Internet.knownNetworks[knownTable.currentIndex] ?? null
    readonly property var newNetwork: Internet.newNetworks[newTable.currentIndex] ?? null

    // The network waiting on a password, and the last thing worth saying
    // (connecting, failures) for the status line.
    property var prompting: null
    property var pending: null
    property string message: ""

    readonly property bool shouldShow: Internet.panelOpen

    onShouldShowChanged: panel.shouldShow ? panel.open() : panel.close()
    onOpened: {
        panel.pane = "known";
        panel.message = "";
    }
    onHidden: {
        Internet.panelOpen = false;
        panel.cancelPrompt();
    }

    function strength(n: var): string {
        return `${Math.round(n.signalStrength * 100)}%`;
    }

    function security(n: var): string {
        return n.security === WifiSecurityType.Open ? "open" : WifiSecurityType.toString(n.security);
    }

    function cyclePane(delta: int): void {
        const i = panel.panes.indexOf(panel.pane);
        panel.pane = panel.panes[(i + delta + panel.panes.length) % panel.panes.length];
    }

    // Known and open networks connect straight away; anything else asks for
    // a password first.
    function connect(n: var): void {
        if (!n)
            return;
        if (n.connected) {
            n.disconnect();
            return;
        }
        if (n.known || n.security === WifiSecurityType.Open) {
            panel.pending = n;
            panel.message = `Connecting to ${n.name}…`;
            n.connect();
            return;
        }
        panel.prompting = n;
        password.text = "";
        password.forceActiveFocus();
    }

    function submitPassword(): void {
        const n = panel.prompting;
        if (!n || password.text === "")
            return;
        panel.pending = n;
        panel.message = `Connecting to ${n.name}…`;
        n.connectWithPsk(password.text);
        panel.cancelPrompt();
    }

    function cancelPrompt(): void {
        panel.prompting = null;
        password.text = "";
        keys.forceActiveFocus();
    }

    readonly property var hints: {
        const common = [
            { key: "⇥", label: "pane", action: () => panel.cyclePane(1) },
            { key: "w", label: Internet.wifiEnabled ? "wifi off" : "wifi on", action: () => Internet.setWifiEnabled(!Internet.wifiEnabled) },
            { key: "esc", label: "close", action: panel.close }
        ];

        if (panel.prompting) {
            return [
                { key: "↵", label: "connect", action: panel.submitPassword },
                { key: "esc", label: "cancel", action: panel.cancelPrompt }
            ];
        }

        if (panel.pane === "known" && panel.knownNetwork) {
            const n = panel.knownNetwork;
            return [
                { key: "␣", label: n.connected ? "disconnect" : "connect", action: () => panel.connect(n) },
                { key: "d", label: "forget", action: () => n.forget() }
            ].concat(common);
        }

        if (panel.pane === "new" && panel.newNetwork)
            return [{ key: "␣", label: "connect", action: () => panel.connect(panel.newNetwork) }].concat(common);

        return common;
    }

    function runKey(key: string): bool {
        const hint = panel.hints.find(h => h.key === key);
        if (!hint)
            return false;
        hint.action();
        return true;
    }

    Connections {
        target: panel.pending

        function onConnectedChanged() {
            if (panel.pending?.connected) {
                panel.message = `Connected to ${panel.pending.name}`;
                panel.pending = null;
            }
        }

        function onConnectionFailed(reason) {
            panel.message = `Could not connect to ${panel.pending?.name}: ${ConnectionFailReason.toString(reason)}`;
            panel.pending = null;
        }
    }

    Item {
        id: keys
        anchors.fill: parent
        focus: true

        Keys.onPressed: event => {
            const table = panel.pane === "known" ? knownTable : panel.pane === "new" ? newTable : null;

            if (event.key === Qt.Key_Tab || event.key === Qt.Key_Backtab) {
                panel.cyclePane(event.key === Qt.Key_Tab ? 1 : -1);
            } else if (event.key === Qt.Key_J || event.key === Qt.Key_Down) {
                table?.move(1);
            } else if (event.key === Qt.Key_K || event.key === Qt.Key_Up) {
                table?.move(-1);
            } else if (event.key === Qt.Key_Space || event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                panel.connect(panel.pane === "known" ? panel.knownNetwork : panel.pane === "new" ? panel.newNetwork : null);
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
            title: "Devices"
            focused: panel.pane === "devices"
            onClicked: panel.pane = "devices"

            TuiTable {
                focused: panel.pane === "devices"
                columns: [
                    { title: "Device", width: 72 },
                    { title: "Type", width: 72 },
                    { title: "State", width: 96 },
                    { title: "Connection", width: 0 }
                ]
                rows: Internet.devices.map(d => [d.device, d.type, d.state, d.connection || "-"])
                emptyText: "No network devices"
                onSelected: panel.pane = "devices"
            }
        }

        TuiPane {
            title: "Known Networks"
            focused: panel.pane === "known"
            onClicked: panel.pane = "known"

            TuiTable {
                id: knownTable
                focused: panel.pane === "known"
                columns: [
                    { title: "", width: 12 },
                    { title: "Name", width: 0 },
                    { title: "Security", width: 72 },
                    { title: "Signal", width: 56 }
                ]
                rows: Internet.knownNetworks.map(n => [n.connected ? "*" : n.stateChanging ? "…" : "", n.name, panel.security(n), panel.strength(n)])
                emptyText: Internet.wifiEnabled ? "No saved networks in range" : "Wi-Fi is off"
                onSelected: panel.pane = "known"
                onActivated: index => panel.connect(Internet.knownNetworks[index])
            }
        }

        TuiPane {
            title: "New Networks"
            focused: panel.pane === "new"
            onClicked: panel.pane = "new"

            TuiTable {
                id: newTable
                focused: panel.pane === "new"
                columns: [
                    { title: "Name", width: 0 },
                    { title: "Security", width: 72 },
                    { title: "Signal", width: 56 }
                ]
                // Long lists scroll in a terminal; here the strongest few will do.
                rows: Internet.newNetworks.slice(0, 8).map(n => [n.name, panel.security(n), panel.strength(n)])
                emptyText: Internet.wifiEnabled ? "Scanning…" : "Wi-Fi is off"
                onSelected: panel.pane = "new"
                onActivated: index => panel.connect(Internet.newNetworks[index])
            }
        }

        TuiPane {
            visible: panel.prompting !== null
            title: `Password for ${panel.prompting?.name ?? ""}`
            focused: true

            Item {
                Layout.fillWidth: true
                implicitHeight: password.implicitHeight + 8

                TextInput {
                    id: password
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.leftMargin: 6
                    echoMode: TextInput.Password
                    color: ShellGlobals.materialColors.ontertiarycontainer
                    font.family: ShellGlobals.monoFamily
                    font.pixelSize: 13

                    Keys.onReturnPressed: panel.submitPassword()
                    Keys.onEnterPressed: panel.submitPassword()
                    Keys.onEscapePressed: panel.cancelPrompt()
                }
            }
        }

        StyledText {
            Layout.fillWidth: true
            Layout.leftMargin: 4
            text: panel.message !== "" ? panel.message : `Connectivity: ${Internet.connectivity}${Internet.address ? ` · ${Internet.address}` : ""}`
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

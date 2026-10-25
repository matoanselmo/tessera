import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.UPower
import qs
import qs.components
import qs.services
import qs.lock
import qs.settings as SettingsWindow

// The control center, after macOS's: the everyday toggles and sliders as
// tiles in one dropdown. Network, Bluetooth and sound also open their full
// panels from here (the chevrons), in their place under the bar.
//
// Keyboard: j/k (or the arrows, or Tab) move a focus ring through the tiles,
// Enter or Space works the focused one, and h/l moves a focused slider.
// The ring only appears once a key is pressed, so mouse users never see it.
BarPanel {
    id: panel

    implicitWidth: 380
    contentHeight: column.implicitHeight + ShellGlobals.popupPadding * 2

    readonly property bool shouldShow: ControlCenter.panelOpen

    onShouldShowChanged: panel.shouldShow ? panel.open() : panel.close()
    onOpened: panel.focusedCell = ""
    onHidden: ControlCenter.panelOpen = false

    readonly property color tileColor: ShellGlobals.materialColors.primarycontainer
    readonly property color strong: ShellGlobals.materialColors.onprimarycontainer

    // Swaps this panel for one of the detailed ones.
    function openDetail(open: var): void {
        ControlCenter.panelOpen = false;
        open();
    }

    // ---- Keyboard focus ------------------------------------------------

    property string focusedCell: ""

    // In reading order; tiles that are hidden at the moment drop out.
    readonly property var cells: [
        {
            id: "network",
            run: () => networkRow.activate()
        },
        {
            id: "bluetooth",
            run: () => bluetoothRow.activate()
        },
        {
            id: "mic",
            run: () => Audio.toggleMicMute()
        },
        {
            id: "dnd",
            run: () => Notifications.setDnd(!Notifications.dnd)
        },
        {
            id: "side",
            run: () => sideToggle.activate()
        },
        {
            id: "display",
            when: Brightness.available,
            adjust: d => Brightness.nudge(d * Brightness.step),
            run: () => Brightness.set(Brightness.level < 1 ? 1 : 0.5)
        },
        {
            id: "sound",
            adjust: d => Audio.nudge(d * 0.05),
            run: () => Audio.toggleMute()
        },
        {
            id: "media",
            when: Media.player !== null,
            adjust: d => d > 0 ? Media.player.next() : Media.player.previous(),
            run: () => Media.player.togglePlaying()
        },
        {
            id: "lock",
            run: () => {
                ControlCenter.panelOpen = false;
                LockState.lock();
            }
        },
        {
            id: "awake",
            when: ControlCenter.laptop,
            run: () => ControlCenter.keepAwake = !ControlCenter.keepAwake
        },
        {
            id: "screenshot",
            run: () => ControlCenter.screenshot()
        },
        {
            id: "settings",
            run: () => {
                ControlCenter.panelOpen = false;
                SettingsWindow.Controller.open();
            }
        }
    ].filter(c => c.when ?? true)

    function moveFocus(delta: int): void {
        const ids = panel.cells.map(c => c.id);
        const i = ids.indexOf(panel.focusedCell);
        // The first press only shows the ring, on the first tile.
        if (i < 0) {
            panel.focusedCell = ids[0];
            return;
        }
        panel.focusedCell = ids[(i + delta + ids.length) % ids.length];
    }

    Item {
        anchors.fill: parent
        focus: true

        Keys.onPressed: event => {
            const cell = panel.cells.find(c => c.id === panel.focusedCell);

            if (event.key === Qt.Key_J || event.key === Qt.Key_Down || event.key === Qt.Key_Tab) {
                panel.moveFocus(1);
            } else if (event.key === Qt.Key_K || event.key === Qt.Key_Up || event.key === Qt.Key_Backtab) {
                panel.moveFocus(-1);
            } else if (event.key === Qt.Key_L || event.key === Qt.Key_Right) {
                if (cell?.adjust)
                    cell.adjust(1);
                else
                    panel.moveFocus(1);
            } else if (event.key === Qt.Key_H || event.key === Qt.Key_Left) {
                if (cell?.adjust)
                    cell.adjust(-1);
                else
                    panel.moveFocus(-1);
            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
                if (cell)
                    cell.run();
                else
                    panel.moveFocus(1);
            } else {
                return;
            }
            event.accepted = true;
        }
    }

    // ---- Building blocks -----------------------------------------------

    // A tile's background, with the keyboard focus ring drawn over it.
    component Tile: Rectangle {
        id: tile

        property string cell: ""
        default property alias body: inner.data
        property int pad: 10

        readonly property bool focused: tile.cell !== "" && panel.focusedCell === tile.cell

        Layout.fillWidth: true
        implicitHeight: inner.implicitHeight + tile.pad * 2
        color: panel.tileColor
        radius: ShellGlobals.radius

        ColumnLayout {
            id: inner
            anchors {
                left: parent.left
                right: parent.right
                verticalCenter: parent.verticalCenter
                margins: tile.pad
            }
            spacing: 8
        }

        FocusRing {
            shown: tile.focused
        }
    }

    component FocusRing: Rectangle {
        property bool shown: false

        anchors.fill: parent
        color: "transparent"
        border.width: 2
        border.color: ShellGlobals.materialColors.secondary
        radius: ShellGlobals.radius
        opacity: shown ? 1 : 0

        Behavior on opacity {
            Anim {
                time: ShellGlobals.animFast
            }
        }
    }

    // A square icon button, filled with the accent while on.
    component Toggle: Rectangle {
        id: toggle

        property url icon
        property bool on: false
        property bool alert: false
        property int size: 30

        signal clicked

        implicitWidth: toggle.size
        implicitHeight: toggle.size
        radius: ShellGlobals.radius
        color: toggle.alert ? ShellGlobals.materialColors.errorcontainer : toggle.on ? ShellGlobals.materialColors.secondary : hover.containsMouse ? ShellGlobals.materialColors.surfacebright : ShellGlobals.materialColors.tertiary

        Behavior on color {
            CAnim {}
        }

        TintedIcon {
            anchors.centerIn: parent
            size: toggle.size > 30 ? ShellGlobals.iconSize : 16
            source: toggle.icon
            color: toggle.alert ? ShellGlobals.materialColors.onerrorcontainer : toggle.on ? ShellGlobals.materialColors.onsecondary : ShellGlobals.materialColors.ontertiarycontainer

            Behavior on color {
                CAnim {}
            }
        }

        MouseArea {
            id: hover
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: toggle.clicked()
        }
    }

    // A toggle with a title and a status line, and optionally a chevron
    // that opens the full panel. Clicking the text does what the chevron
    // does, or toggles when there is none.
    component ToggleRow: Item {
        id: row

        property string cell
        property url icon
        property bool on
        property bool alert: false
        property string title
        property string status
        property bool chevron: true

        signal toggled
        signal detailed

        function activate(): void {
            row.toggled();
        }

        Layout.fillWidth: true
        implicitHeight: 34

        FocusRing {
            anchors.margins: -4
            shown: panel.focusedCell === row.cell
        }

        RowLayout {
            anchors.fill: parent
            spacing: 10

            Toggle {
                icon: row.icon
                on: row.on
                alert: row.alert
                onClicked: row.toggled()
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                StyledText {
                    Layout.fillWidth: true
                    text: row.title
                    font.bold: true
                    color: panel.strong
                    elide: Text.ElideRight
                }

                StyledText {
                    Layout.fillWidth: true
                    text: row.status
                    font.pixelSize: 11
                    opacity: 0.6
                    elide: Text.ElideRight
                }
            }

            TintedIcon {
                visible: row.chevron
                size: 14
                source: Qt.resolvedUrl("icons/chevron-right.svg")
                opacity: 0.5
            }
        }

        // Behind the toggle, so the toggle keeps its own clicks.
        MouseArea {
            z: -1
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: row.chevron ? row.detailed() : row.toggled()
        }
    }

    // A half-height tile with one big toggle, centred both ways.
    component BigToggle: Rectangle {
        id: big

        property string cell
        property url icon
        property bool on
        property string title
        property string status

        signal toggled

        function activate(): void {
            big.toggled();
        }

        Layout.fillWidth: true
        Layout.preferredHeight: (connections.implicitHeight - 8) / 2
        color: panel.tileColor
        radius: ShellGlobals.radius

        RowLayout {
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: 12
            anchors.rightMargin: 10
            spacing: 10

            Toggle {
                size: 34
                icon: big.icon
                on: big.on
                onClicked: big.toggled()
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1

                StyledText {
                    Layout.fillWidth: true
                    text: big.title
                    font.bold: true
                    color: panel.strong
                    wrapMode: Text.WordWrap
                    lineHeight: 0.9
                }

                StyledText {
                    Layout.fillWidth: true
                    text: big.status
                    font.pixelSize: 11
                    opacity: 0.6
                    elide: Text.ElideRight
                }
            }
        }

        MouseArea {
            z: -1
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: big.toggled()
        }

        FocusRing {
            shown: panel.focusedCell === big.cell
        }
    }

    // A labelled slider. The icon toggles (mute), the right-hand label can
    // open a panel.
    component SliderTile: Tile {
        id: slider

        property string title
        property string side
        property bool sideOpens: false
        property url icon
        property real value
        property string valueText

        signal moved(real value)
        signal iconClicked
        signal sideClicked

        RowLayout {
            Layout.fillWidth: true

            StyledText {
                text: slider.title
                font.bold: true
                color: panel.strong
            }

            Item {
                Layout.fillWidth: true
            }

            StyledText {
                Layout.maximumWidth: 220
                text: slider.side + (slider.sideOpens ? " ›" : "")
                elide: Text.ElideRight
                font.pixelSize: 11
                opacity: sideHover.containsMouse ? 0.9 : 0.6

                Behavior on opacity {
                    Anim {
                        time: ShellGlobals.animFast
                    }
                }

                MouseArea {
                    id: sideHover
                    anchors.fill: parent
                    enabled: slider.sideOpens
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: slider.sideClicked()
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            TintedIcon {
                source: slider.icon

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: slider.iconClicked()
                }
            }

            Track {
                Layout.fillWidth: true
                thickness: 6
                interactive: true
                value: slider.value
                onMoved: value => slider.moved(value)
            }

            StyledText {
                Layout.preferredWidth: 36
                horizontalAlignment: Text.AlignRight
                text: slider.valueText
                font.bold: true
            }
        }
    }

    component SmallTile: Rectangle {
        id: small

        property string cell
        property url icon
        property string label
        property bool on: false

        signal clicked

        Layout.fillWidth: true
        implicitHeight: 62
        radius: ShellGlobals.radius
        color: small.on ? ShellGlobals.materialColors.secondary : hover.containsMouse ? ShellGlobals.materialColors.surfacebright : panel.tileColor

        Behavior on color {
            CAnim {}
        }

        ColumnLayout {
            anchors.centerIn: parent
            spacing: 5

            TintedIcon {
                Layout.alignment: Qt.AlignHCenter
                size: 16
                source: small.icon
                color: small.on ? ShellGlobals.materialColors.onsecondary : ShellGlobals.materialColors.ontertiarycontainer

                Behavior on color {
                    CAnim {}
                }
            }

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: small.label
                font.pixelSize: 10
                font.bold: true
                color: small.on ? ShellGlobals.materialColors.onsecondary : ShellGlobals.materialColors.ontertiarycontainer

                Behavior on color {
                    CAnim {}
                }
            }
        }

        MouseArea {
            id: hover
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: small.clicked()
        }

        FocusRing {
            shown: panel.focusedCell === small.cell
        }
    }

    // ---- Layout ----------------------------------------------------------

    ColumnLayout {
        id: column
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            margins: ShellGlobals.popupPadding
        }
        spacing: 8

        // Connections, and the two big toggles beside it, each exactly half
        // its height so the columns line up top and bottom.
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Tile {
                id: connections
                Layout.fillWidth: false
                Layout.preferredWidth: 200

                ToggleRow {
                    id: networkRow
                    cell: "network"
                    icon: Qt.resolvedUrl(`icons/${Internet.icon}`)
                    on: Internet.wiredUp || Internet.wifiUp
                    title: Internet.wiredUp ? "Network" : "Wi-Fi"
                    status: {
                        if (Internet.wiredUp)
                            return `Wired · ${Internet.wired.connection}`;
                        if (Internet.wifiUp)
                            return Internet.wifiDevice.connection;
                        return Internet.wifiEnabled ? "Not connected" : "Off";
                    }
                    // Wired has nothing to switch, so the toggle opens the
                    // panel; otherwise it is the Wi-Fi radio.
                    onToggled: Internet.wiredUp || !Internet.wifi ? detailed() : Internet.setWifiEnabled(!Internet.wifiEnabled)
                    onDetailed: panel.openDetail(() => Internet.panelOpen = true)
                }

                ToggleRow {
                    id: bluetoothRow
                    cell: "bluetooth"
                    icon: Qt.resolvedUrl(`icons/${BluetoothState.icon}`)
                    on: BluetoothState.powered
                    title: "Bluetooth"
                    status: {
                        if (!BluetoothState.adapter)
                            return "No adapter";
                        if (BluetoothState.connected.length > 0)
                            return BluetoothState.connected.map(d => d.name).join(", ");
                        return BluetoothState.powered ? "On" : "Off";
                    }
                    onToggled: BluetoothState.adapter && BluetoothState.setPowered(!BluetoothState.powered)
                    onDetailed: panel.openDetail(() => BluetoothState.panelOpen = true)
                }

                ToggleRow {
                    cell: "mic"
                    icon: Qt.resolvedUrl(Audio.micMuted ? "icons/mic-muted.svg" : "icons/mic.svg")
                    on: Audio.micInUse && !Audio.micMuted
                    alert: Audio.micMuted
                    chevron: false
                    title: "Microphone"
                    status: {
                        if (!Audio.source)
                            return "None";
                        if (Audio.micMuted)
                            return "Muted";
                        const apps = [...new Set(Audio.recorders.map(n => n.properties?.["application.name"] || n.name))];
                        return apps.length > 0 ? `In use · ${apps.join(", ")}` : "On · not in use";
                    }
                    onToggled: Audio.toggleMicMute()
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 8

                BigToggle {
                    cell: "dnd"
                    icon: Qt.resolvedUrl("icons/moon.svg")
                    on: Notifications.dnd
                    title: "Do not disturb"
                    status: Notifications.dnd ? "On" : "Off"
                    onToggled: Notifications.setDnd(!Notifications.dnd)
                }

                // The power profile on a laptop, keep awake on a desktop.
                BigToggle {
                    id: sideToggle
                    cell: "side"
                    icon: Qt.resolvedUrl(ControlCenter.laptop ? "icons/gauge.svg" : "icons/coffee.svg")
                    on: ControlCenter.laptop ? PowerProfiles.profile !== PowerProfile.Balanced : ControlCenter.keepAwake
                    title: ControlCenter.laptop ? ControlCenter.profileName : "Keep awake"
                    status: ControlCenter.laptop ? "Power mode" : ControlCenter.keepAwake ? "On" : "Off"
                    onToggled: ControlCenter.laptop ? ControlCenter.cycleProfile() : ControlCenter.keepAwake = !ControlCenter.keepAwake
                }
            }
        }

        SliderTile {
            visible: Brightness.available
            cell: "display"
            title: "Display"
            side: Brightness.device
            icon: Qt.resolvedUrl("icons/brightness.svg")
            value: Brightness.level
            valueText: `${Brightness.percent}%`
            onMoved: value => Brightness.set(value)
        }

        SliderTile {
            cell: "sound"
            title: "Sound"
            side: Audio.sink?.description ?? "No output"
            sideOpens: true
            icon: Qt.resolvedUrl(`icons/${Audio.icon}`)
            value: Audio.muted ? 0 : Audio.volume
            valueText: Audio.muted ? "off" : `${Audio.percent}%`
            onMoved: value => Audio.setVolume(value)
            onIconClicked: Audio.toggleMute()
            onSideClicked: panel.openDetail(() => Audio.panelOpen = true)
        }

        // Now playing; gone while nothing is.
        Tile {
            cell: "media"
            visible: Media.player !== null

            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Rectangle {
                    implicitWidth: 44
                    implicitHeight: 44
                    color: ShellGlobals.materialColors.tertiary
                    radius: ShellGlobals.radius
                    clip: true

                    TintedIcon {
                        anchors.centerIn: parent
                        visible: art.status !== Image.Ready
                        source: Qt.resolvedUrl("icons/music.svg")
                    }

                    Image {
                        id: art
                        anchors.fill: parent
                        source: Media.player?.trackArtUrl ?? ""
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        sourceSize.width: 88
                        opacity: art.status === Image.Ready ? 1 : 0

                        Behavior on opacity {
                            Anim {}
                        }
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 1

                    StyledText {
                        Layout.fillWidth: true
                        text: Media.player?.trackTitle || Media.player?.identity || ""
                        font.bold: true
                        color: panel.strong
                        elide: Text.ElideRight
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: [Media.player?.trackArtist, Media.player?.identity].filter(t => t).join(" · ")
                        font.pixelSize: 11
                        opacity: 0.6
                        elide: Text.ElideRight
                    }

                    Track {
                        Layout.fillWidth: true
                        Layout.topMargin: 4
                        visible: Media.hasTimeline
                        thickness: 3
                        value: Media.progress
                        continuous: Media.playing
                    }
                }

                Repeater {
                    model: [
                        {
                            icon: "media-previous.svg",
                            run: () => Media.player.previous()
                        },
                        {
                            icon: Media.playing ? "media-pause.svg" : "media-play.svg",
                            run: () => Media.player.togglePlaying(),
                            main: true
                        },
                        {
                            icon: "media-next.svg",
                            run: () => Media.player.next()
                        }
                    ]

                    Rectangle {
                        id: mediaButton
                        required property var modelData

                        implicitWidth: 28
                        implicitHeight: 28
                        radius: ShellGlobals.radius
                        color: mediaHover.containsMouse ? ShellGlobals.materialColors.surfacebright : mediaButton.modelData.main ? ShellGlobals.materialColors.tertiary : "transparent"

                        Behavior on color {
                            CAnim {}
                        }

                        TintedIcon {
                            anchors.centerIn: parent
                            size: 16
                            source: Qt.resolvedUrl(`icons/${mediaButton.modelData.icon}`)
                        }

                        MouseArea {
                            id: mediaHover
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: mediaButton.modelData.run()
                        }
                    }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            SmallTile {
                cell: "lock"
                icon: Qt.resolvedUrl("icons/lock.svg")
                label: "Lock"
                onClicked: {
                    ControlCenter.panelOpen = false;
                    LockState.lock();
                }
            }

            // On a desktop, keep awake already has the big tile.
            SmallTile {
                visible: ControlCenter.laptop
                cell: "awake"
                icon: Qt.resolvedUrl("icons/coffee.svg")
                label: "Keep awake"
                on: ControlCenter.keepAwake
                onClicked: ControlCenter.keepAwake = !ControlCenter.keepAwake
            }

            SmallTile {
                cell: "screenshot"
                icon: Qt.resolvedUrl("icons/camera.svg")
                label: "Screenshot"
                onClicked: ControlCenter.screenshot()
            }

            SmallTile {
                cell: "settings"
                icon: Qt.resolvedUrl("icons/gear.svg")
                label: "Settings"
                onClicked: {
                    ControlCenter.panelOpen = false;
                    SettingsWindow.Controller.open();
                }
            }
        }
    }
}

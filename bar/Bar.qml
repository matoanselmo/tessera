import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import qs
import qs.components
import qs.services
import qs.logout
import "notification"

// One bar per connected screen.
Variants {
    id: root
    model: Quickshell.screens

    PanelWindow {
        id: bar
        required property var modelData
        screen: modelData

        WlrLayershell.namespace: "tessera:bar"

        anchors {
            top: true
            left: true
            right: true
        }

        implicitHeight: ShellGlobals.barThickness + ShellGlobals.barGap * 2
        color: ShellGlobals.materialColors.background

        // Every menu and panel that drops from this bar (BarPopup or BarPanel).
        // Listing one here is all it takes for outside clicks to dismiss it.
        readonly property var popups: [menu, volumePanel, clockMenu, powerMenu, trayMenu, networkPanel, bluetoothPanel, systemPanel]

        Menu {
            id: menu
            bar: bar
        }

        NotificationPopup {
            id: notificationPopup
            bar: bar
        }

        VolumePanel {
            id: volumePanel
            bar: bar
            anchorItem: bar.slots.volume ?? null
        }

        ClockMenu {
            id: clockMenu
            bar: bar
            anchorItem: clock
        }

        TrayMenu {
            id: trayMenu
            bar: bar
        }

        NetworkPanel {
            id: networkPanel
            bar: bar
            anchorItem: bar.slots.network ?? null
        }

        BluetoothPanel {
            id: bluetoothPanel
            bar: bar
            anchorItem: bar.slots.bluetooth ?? null
        }

        SystemPanel {
            id: systemPanel
            bar: bar
            anchorItem: bar.slots.memory ?? null
        }

        PowerMenu {
            id: powerMenu
            bar: bar
            anchorItem: bar.slots.power ?? null
        }


        DismissLayer {
            screen: bar.screen
            active: bar.popups.some(p => p.visible)
            onDismissed: bar.popups.forEach(p => p.close())
        }

        Item {
            anchors.fill: parent
            anchors.margins: ShellGlobals.barGap

            RowLayout {
                id: leftRow
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                spacing: ShellGlobals.barGap

                Workspaces {
                    id: workspaces
                    screen: bar.screen
                }

                ActiveWindow {
                    screen: bar.screen

                    // Stop before the clock rather than growing under it. The
                    // clock is centred off the bar alone, so this cannot loop.
                    maximumWidth: Math.max(0, clock.x - workspaces.width - ShellGlobals.barGap * 4)
                }
            }

            // Anchored to the bar rather than placed between two spacers, so the
            // clock stays centred no matter how wide the side groups get.
            Time {
                id: clock
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter
                onToggleRequested: clockMenu.toggle()
            }

            RowLayout {
                id: rightRow
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: ShellGlobals.barGap

                // In the order the settings window keeps. Keyed by id, so
                // moving one moves its slot rather than rebuilding the row.
                Repeater {
                    id: rightWidgets
                    model: ScriptModel {
                        values: Settings.barWidgets.map(w => w.id)
                    }

                    // Grows out of nothing and fades in when its widget is
                    // switched on or has something to show (the battery on a
                    // laptop, the microphone while in use), and shrinks away
                    // again, so its neighbours slide over instead of jumping.
                    Item {
                        id: slot

                        required property string modelData
                        readonly property string widgetId: slot.modelData
                        readonly property bool wanted: Settings.widgetShown(slot.widgetId) && (loader.item?.present ?? false)

                        property real reveal: slot.wanted ? 1 : 0

                        Behavior on reveal {
                            Anim {}
                        }

                        implicitWidth: loader.implicitWidth * slot.reveal
                        implicitHeight: loader.implicitHeight
                        opacity: slot.reveal
                        visible: slot.reveal > 0
                        clip: slot.reveal < 1
                        Layout.alignment: Qt.AlignVCenter

                        Loader {
                            id: loader
                            sourceComponent: bar.widgets[slot.widgetId] ?? null
                        }
                    }
                }
            }
        }

        // Each right-side widget's slot by id, for panels to open under.
        // Rebuilt as slots are created or moved.
        readonly property var slots: {
            const map = {};
            Settings.barWidgets;
            for (let i = 0; i < rightWidgets.count; i++) {
                const item = rightWidgets.itemAt(i);
                if (item)
                    map[item.widgetId] = item;
            }
            return map;
        }

        readonly property var widgets: ({
                tray: trayWidget,
                mic: micWidget,
                volume: volumeWidget,
                cpu: cpuWidget,
                memory: memoryWidget,
                dnd: dndWidget,
                network: networkWidget,
                bluetooth: bluetoothWidget,
                battery: batteryWidget,
                power: powerWidget
            })

        Component {
            id: trayWidget
            Tray {
                menu: trayMenu
            }
        }

        Component {
            id: micWidget
            MicIndicator {}
        }

        Component {
            id: volumeWidget
            VolumeControl {
                onToggleRequested: Audio.panelOpen = !volumePanel.visible
            }
        }

        // CPU and memory both open the system monitor, sorted by what was
        // clicked. Same visibility check as the notification toggle, so a
        // click that dismisses the open panel does not reopen it.
        Component {
            id: cpuWidget
            CpuUsage {
                onClicked: {
                    SystemStats.sortBy = "cpu";
                    SystemStats.panelOpen = !systemPanel.visible;
                }
            }
        }

        Component {
            id: memoryWidget
            MemUsage {
                onClicked: {
                    SystemStats.sortBy = "mem";
                    SystemStats.panelOpen = !systemPanel.visible;
                }
            }
        }

        // Left click toggles do-not-disturb, right click opens the list.
        // Decided off the popup's own visibility: a click that dismisses the
        // menu through the DismissLayer lands here while it is still fading,
        // and should not bounce it back open.
        Component {
            id: dndWidget
            Dnd {
                onRightClicked: Notifications.menuOpen = !menu.visible
            }
        }

        // Same visibility check as the notification toggle, so a click that
        // dismisses an open panel does not reopen it.
        Component {
            id: networkWidget
            NetworkWidget {
                onToggleRequested: Internet.panelOpen = !networkPanel.visible
            }
        }

        Component {
            id: bluetoothWidget
            BluetoothWidget {
                onToggleRequested: BluetoothState.panelOpen = !bluetoothPanel.visible
            }
        }

        // Hides itself without a laptop battery; a click cycles the power
        // profile.
        Component {
            id: batteryWidget
            BatteryWidget {}
        }

        Component {
            id: powerWidget
            PowerButton {
                active: powerMenu.visible
                onClicked: LogoutState.menuOpen = !powerMenu.visible
            }
        }
    }
}

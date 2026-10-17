import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import qs
import qs.components
import qs.services
import "notification"

// One bar per connected screen.
Variants {
    id: root
    model: Quickshell.screens

    PanelWindow {
        id: bar
        required property var modelData
        screen: modelData

        WlrLayershell.namespace: "shell:bar"

        anchors {
            top: true
            left: true
            right: true
        }

        implicitHeight: ShellGlobals.barThickness + ShellGlobals.barGap * 2
        color: ShellGlobals.materialColors.background

        // Every menu that drops from this bar. Listing one here is all it
        // takes for outside clicks to dismiss it.
        readonly property list<BarPopup> popups: [menu, volumeMenu, clockMenu]

        Menu {
            id: menu
            bar: bar
        }

        NotificationPopup {
            id: notificationPopup
            bar: bar
            menu: menu
        }

        VolumeMenu {
            id: volumeMenu
            bar: bar
            anchorItem: volumeControl
        }

        ClockMenu {
            id: clockMenu
            bar: bar
            anchorItem: clock
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

                VolumeControl {
                    id: volumeControl
                    onToggleRequested: volumeMenu.toggle()
                }

                CpuUsage {}
                MemUsage {}
                // Left click toggles do-not-disturb, right click opens the list.
                // Decided off the popup's own visibility: a click that dismisses
                // the menu through the DismissLayer lands here while it is still
                // fading, and should not bounce it back open.
                Dnd {
                    onRightClicked: Notifications.menuOpen = !menu.visible
                }
                PowerButton {}
            }
        }
    }
}

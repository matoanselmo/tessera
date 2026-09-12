import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import qs
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
                Dnd {}
                PowerButton {}
            }
        }
    }
}

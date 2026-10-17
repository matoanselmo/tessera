import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs
import qs.components
import qs.services

// Volume level shown near the bottom of the focused output whenever the
// default sink changes level or mute, then faded out once it goes quiet.
// Clicks pass straight through it.
Scope {
    id: root

    // `shown` is the request; `alive` keeps the window up through the fade-out.
    property bool shown: false
    property bool alive: false

    readonly property int hideAfter: 1500

    Connections {
        target: Audio

        function onAdjusted() {
            // The volume panel already shows the level, right under the bar.
            if (Audio.panelOpen)
                return;

            root.alive = true;
            root.shown = true;
            hide.restart();
        }
    }

    Timer {
        id: hide
        interval: root.hideAfter
        onTriggered: root.shown = false
    }

    LazyLoader {
        active: root.alive

        PanelWindow {
            id: osdWindow
            screen: Quickshell.screens.find(s => s.name === Niri.focusedOutput) ?? Quickshell.screens[0]

            // The window is `rise` taller than the card so the card can rise
            // into place inside it; the margin is lowered to match, so the card
            // settles where it always did.
            readonly property int rise: 12

            anchors.bottom: true
            margins.bottom: 96 - rise
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "shell:osd"

            // An empty input region, so the OSD never eats a click.
            mask: Region {}

            implicitWidth: 280
            implicitHeight: ShellGlobals.barThickness + ShellGlobals.barGap * 4 + rise
            color: "transparent"

            Reveal {
                width: parent.width
                height: parent.height - osdWindow.rise
                shown: root.shown
                fromY: osdWindow.rise
                onExited: root.alive = false

                Rectangle {
                    id: card
                    anchors.fill: parent
                    color: ShellGlobals.materialColors.tertiarycontainer
                    radius: ShellGlobals.radius

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: ShellGlobals.popupPadding
                        anchors.rightMargin: ShellGlobals.popupPadding
                        spacing: 10

                        TintedIcon {
                            source: Qt.resolvedUrl(`../bar/icons/${Audio.icon}`)
                            color: Audio.muted ? ShellGlobals.materialColors.error : ShellGlobals.materialColors.ontertiarycontainer
                        }

                        Track {
                            Layout.fillWidth: true
                            thickness: 6
                            value: Audio.muted ? 0 : Audio.volume
                        }

                        StyledText {
                            Layout.preferredWidth: 38
                            horizontalAlignment: Text.AlignRight
                            text: Audio.muted ? "off" : `${Audio.percent}%`
                            font.bold: true
                            font.pixelSize: ShellGlobals.fontSize + 1
                        }
                    }
                }
            }
        }
    }
}

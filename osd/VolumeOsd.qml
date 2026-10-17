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
            screen: Quickshell.screens.find(s => s.name === Niri.focusedOutput) ?? Quickshell.screens[0]

            anchors.bottom: true
            margins.bottom: 96
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "shell:osd"

            // An empty input region, so the OSD never eats a click.
            mask: Region {}

            implicitWidth: 280
            implicitHeight: ShellGlobals.barThickness + ShellGlobals.barGap * 4
            color: "transparent"

            Rectangle {
                id: card
                anchors.fill: parent
                color: ShellGlobals.materialColors.tertiarycontainer
                radius: ShellGlobals.radius

                // Starts hidden and binds once created, so it fades in too.
                opacity: 0
                Component.onCompleted: card.opacity = Qt.binding(() => root.shown ? 1 : 0)

                Behavior on opacity {
                    Anim {}
                }

                onOpacityChanged: {
                    if (card.opacity === 0 && !root.shown)
                        root.alive = false;
                }

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

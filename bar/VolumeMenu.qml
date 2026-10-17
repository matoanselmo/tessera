import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire
import qs
import qs.components

BarPopup {
    id: menu

    required property PanelWindow bar
    required property Item anchorItem

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property real volume: menu.sink?.audio?.volume ?? 0
    readonly property bool muted: menu.sink?.audio?.muted ?? false

    readonly property var sinks: [...Pipewire.nodes.values].filter(n => n.isSink && !n.isStream)

    anchor.item: menu.anchorItem
    anchor.edges: Edges.Bottom | Edges.Right
    anchor.gravity: Edges.Bottom | Edges.Left
    anchor.margins.top: ShellGlobals.barGap

    implicitWidth: 300
    implicitHeight: column.implicitHeight + ShellGlobals.popupPadding * 2

    // Descriptions and volumes only stay current while the nodes are bound.
    PwObjectTracker {
        objects: menu.sinks
    }

    function setVolume(fraction: real): void {
        if (!menu.sink?.audio)
            return;

        menu.sink.audio.muted = false;
        menu.sink.audio.volume = Math.max(0, Math.min(1, fraction));
    }

    ColumnLayout {
        id: column
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            margins: ShellGlobals.popupPadding
        }
        spacing: ShellGlobals.popupSpacing

        StyledText {
            Layout.fillWidth: true
            text: menu.sink?.description ?? "No output device"
            elide: Text.ElideRight
            font.bold: true
            font.pixelSize: 14
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            BarWidget {
                icon: menu.muted ? "volume-muted.svg" : "volume-high.svg"
                color: menu.muted ? ShellGlobals.materialColors.errorcontainer : ShellGlobals.materialColors.tertiary
                foreground: menu.muted ? ShellGlobals.materialColors.onerrorcontainer : ShellGlobals.materialColors.ontertiary
                implicitHeight: 30
                Layout.preferredHeight: 30

                interactive: true
                onClicked: {
                    if (menu.sink?.audio)
                        menu.sink.audio.muted = !menu.muted;
                }
            }

            Track {
                id: slider
                Layout.fillWidth: true
                interactive: true
                thickness: 6
                value: menu.muted ? 0 : menu.volume
                onMoved: value => menu.setVolume(value)
            }

            StyledText {
                Layout.preferredWidth: 38
                horizontalAlignment: Text.AlignRight
                text: `${Math.round(slider.fraction * 100)}%`
                font.bold: true
                font.pixelSize: ShellGlobals.fontSize + 1
            }
        }

        Divider {
            visible: menu.sinks.length > 1
        }

        Repeater {
            model: menu.sinks.length > 1 ? menu.sinks : []

            delegate: Rectangle {
                id: device
                required property PwNode modelData

                readonly property bool isCurrent: device.modelData === menu.sink

                Layout.fillWidth: true
                Layout.preferredHeight: 28
                radius: ShellGlobals.radius
                color: device.isCurrent ? ShellGlobals.materialColors.tertiary : "transparent"

                StyledText {
                    anchors {
                        left: parent.left
                        right: parent.right
                        verticalCenter: parent.verticalCenter
                        leftMargin: 8
                        rightMargin: 8
                    }
                    text: device.modelData.description
                    elide: Text.ElideRight
                    opacity: device.isCurrent ? 1 : 0.7
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: Pipewire.preferredDefaultAudioSink = device.modelData
                }
            }
        }
    }
}

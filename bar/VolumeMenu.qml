import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire
import qs

PopupWindow {
    id: menu

    required property PanelWindow bar
    required property Item anchorItem

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property real volume: menu.sink?.audio?.volume ?? 0
    readonly property bool muted: menu.sink?.audio?.muted ?? false

    readonly property var sinks: [...Pipewire.nodes.values].filter(n => n.isSink && !n.isStream)

    color: "transparent"
    visible: false

    anchor.item: menu.anchorItem
    anchor.edges: Edges.Bottom | Edges.Right
    anchor.gravity: Edges.Bottom | Edges.Left
    anchor.margins.top: ShellGlobals.barGap

    implicitWidth: 300
    implicitHeight: column.implicitHeight + 24

    // Descriptions and volumes only stay current while the nodes are bound.
    PwObjectTracker {
        objects: menu.sinks
    }

    function toggle(): void {
        if (menu.visible) {
            card.state = "Closed";
        } else {
            menu.visible = true;
            card.state = "Open";
        }
    }

    function setVolume(fraction: real): void {
        if (!menu.sink?.audio)
            return;

        menu.sink.audio.muted = false;
        menu.sink.audio.volume = Math.max(0, Math.min(1, fraction));
    }

    Rectangle {
        anchors.fill: parent
        color: ShellGlobals.materialColors.tertiarycontainer
        opacity: card.opacity
        radius: ShellGlobals.radius
    }

    Item {
        id: card
        anchors.fill: parent

        state: "Closed"
        states: [
            State {
                name: "Open"
                PropertyChanges {
                    card.opacity: 1
                }
            },
            State {
                name: "Closed"
                PropertyChanges {
                    card.opacity: 0
                }
            }
        ]

        onOpacityChanged: {
            if (card.opacity == 0)
                menu.visible = false;
        }

        Behavior on opacity {
            NumberAnimation {
                duration: 160
            }
        }

        ColumnLayout {
            id: column
            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                margins: 12
            }
            spacing: 10

            Text {
                Layout.fillWidth: true
                text: menu.sink?.description ?? "No output device"
                elide: Text.ElideRight
                font.bold: true
                font.pixelSize: 14
                font.family: ShellGlobals.fontFamily
                font.letterSpacing: ShellGlobals.letterSpacing
                color: ShellGlobals.materialColors.ontertiarycontainer
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

                // Hand-rolled so the control matches the rest of the shell rather
                // than pulling in a Controls style.
                Item {
                    id: slider
                    Layout.fillWidth: true
                    implicitHeight: 24

                    readonly property real fraction: menu.muted ? 0 : Math.max(0, Math.min(1, menu.volume))

                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width
                        height: 6
                        radius: ShellGlobals.radius
                        color: ShellGlobals.materialColors.surfacecontainerhighest

                        Rectangle {
                            width: parent.width * slider.fraction
                            height: parent.height
                            radius: ShellGlobals.radius
                            color: ShellGlobals.materialColors.secondary
                        }
                    }

                    Rectangle {
                        x: (parent.width - width) * slider.fraction
                        anchors.verticalCenter: parent.verticalCenter
                        width: 10
                        height: 22
                        radius: ShellGlobals.radius
                        color: ShellGlobals.materialColors.secondary
                    }

                    MouseArea {
                        anchors.fill: parent
                        preventStealing: true

                        onPressed: event => menu.setVolume(event.x / slider.width)
                        onPositionChanged: event => {
                            if (pressed)
                                menu.setVolume(event.x / slider.width);
                        }
                        onWheel: event => menu.setVolume(slider.fraction + (event.angleDelta.y > 0 ? 0.05 : -0.05))
                    }
                }

                Text {
                    Layout.preferredWidth: 38
                    horizontalAlignment: Text.AlignRight
                    text: `${Math.round(slider.fraction * 100)}%`
                    font.bold: true
                    font.pixelSize: ShellGlobals.fontSize + 1
                    font.family: ShellGlobals.fontFamily
                    color: ShellGlobals.materialColors.ontertiarycontainer
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                visible: menu.sinks.length > 1
                color: ShellGlobals.materialColors.ontertiarycontainer
                opacity: 0.15
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

                    Text {
                        anchors {
                            left: parent.left
                            right: parent.right
                            verticalCenter: parent.verticalCenter
                            leftMargin: 8
                            rightMargin: 8
                        }
                        text: device.modelData.description
                        elide: Text.ElideRight
                        font.pixelSize: 12
                        font.family: ShellGlobals.fontFamily
                        color: ShellGlobals.materialColors.ontertiarycontainer
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
}

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire
import qs
import qs.components
import qs.services

BarPopup {
    id: menu

    required property PanelWindow bar
    required property Item anchorItem

    anchor.item: menu.anchorItem
    anchor.edges: Edges.Bottom | Edges.Right
    anchor.gravity: Edges.Bottom | Edges.Left
    anchor.margins.top: ShellGlobals.barGap

    implicitWidth: 300
    implicitHeight: column.implicitHeight + ShellGlobals.popupPadding * 2

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
            text: Audio.sink?.description ?? "No output device"
            elide: Text.ElideRight
            font.bold: true
            font.pixelSize: 14
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            BarWidget {
                icon: Audio.muted ? "volume-muted.svg" : "volume-high.svg"
                color: Audio.muted ? ShellGlobals.materialColors.errorcontainer : ShellGlobals.materialColors.tertiary
                foreground: Audio.muted ? ShellGlobals.materialColors.onerrorcontainer : ShellGlobals.materialColors.ontertiary
                implicitHeight: 30
                Layout.preferredHeight: 30

                interactive: true
                onClicked: Audio.toggleMute()
            }

            Track {
                id: slider
                Layout.fillWidth: true
                interactive: true
                thickness: 6
                value: Audio.muted ? 0 : Audio.volume
                onMoved: value => Audio.setVolume(value)
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
            visible: Audio.sinks.length > 1
        }

        Repeater {
            model: Audio.sinks.length > 1 ? Audio.sinks : []

            delegate: Rectangle {
                id: device
                required property PwNode modelData

                readonly property bool isCurrent: device.modelData === Audio.sink

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
                    onClicked: Audio.setDefaultSink(device.modelData)
                }
            }
        }
    }
}

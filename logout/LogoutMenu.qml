import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Qt5Compat.GraphicalEffects

import qs

Variants {
    id: root

    property color backgroundColor: ShellGlobals.materialColors.background
    property real backgroundOpacity: 0.5
    property color buttonColor: ShellGlobals.materialColors.tertiarycontainer
    property color buttonHoverColor: ShellGlobals.materialColors.tertiary
    default property list<LogoutButton> buttons

    model: Quickshell.screens

    PanelWindow {
        id: w
        required property var modelData
        screen: modelData

        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
        WlrLayershell.namespace: "shell:logout"

        color: "transparent"
        visible: LogoutState.menuOpen

        contentItem {
            focus: true
            Keys.onPressed: event => {
                if (event.key == Qt.Key_Escape) {
                    LogoutState.menuOpen = false;
                    event.accepted = true;
                    return;
                }

                for (let i = 0; i < root.buttons.length; i++) {
                    const button = root.buttons[i];
                    if (event.key == button.keybind) {
                        button.exec();
                        LogoutState.menuOpen = false;
                        event.accepted = true;
                        return;
                    }
                }
            }
        }

        anchors {
            top: true
            left: true
            bottom: true
            right: true
        }

        Rectangle {
            // Alpha on the colour, not `opacity`: opacity is inherited by
            // children and would wash out the tiles along with the backdrop.
            color: Qt.rgba(root.backgroundColor.r, root.backgroundColor.g, root.backgroundColor.b, root.backgroundOpacity)
            anchors.fill: parent

            MouseArea {
                anchors.fill: parent
                onClicked: LogoutState.menuOpen = false

                GridLayout {
                    id: grid
                    anchors.centerIn: parent

                    readonly property int gap: 8

                    // At most five per row, then rows are balanced rather than
                    // left ragged: six buttons give 3x2, not 5 and a lone one.
                    readonly property int tileRows: Math.max(1, Math.ceil(root.buttons.length / 5))
                    readonly property int cols: Math.max(1, Math.ceil(root.buttons.length / grid.tileRows))

                    // Largest square that keeps the whole grid inside 80% of the
                    // screen in both directions.
                    readonly property real tile: Math.min((w.width * 0.8 - grid.gap * (grid.cols - 1)) / grid.cols, (w.height * 0.8 - grid.gap * (grid.tileRows - 1)) / grid.tileRows)

                    columns: grid.cols
                    columnSpacing: grid.gap
                    rowSpacing: grid.gap

                    Repeater {
                        model: root.buttons

                        delegate: Rectangle {
                            required property LogoutButton modelData

                            Layout.preferredWidth: grid.tile
                            Layout.preferredHeight: grid.tile

                            color: ma.containsMouse ? root.buttonHoverColor : root.buttonColor
                            radius: ShellGlobals.radius

                            MouseArea {
                                id: ma
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: {
                                    modelData.exec();
                                    LogoutState.menuOpen = false;
                                }
                            }

                            ColumnLayout {
                                anchors.centerIn: parent
                                spacing: 18

                                Item {
                                    Layout.alignment: Qt.AlignHCenter
                                    implicitWidth: grid.tile * 0.3
                                    implicitHeight: implicitWidth

                                    Image {
                                        id: image
                                        anchors.fill: parent
                                        source: `icons/${modelData.icon}.png`
                                        smooth: true
                                        mipmap: true
                                        visible: false
                                    }

                                    ColorOverlay {
                                        anchors.fill: parent
                                        source: image
                                        color: ShellGlobals.materialColors.ontertiary
                                    }
                                }

                                Text {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: modelData.text
                                    font.pointSize: 12
                                    color: ShellGlobals.materialColors.ontertiary
                                    font.bold: true
                                    font.family: ShellGlobals.fontFamily
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

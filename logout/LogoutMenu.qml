import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Qt5Compat.GraphicalEffects

import qs

Variants {
    id: root

    property color backgroundColor: ShellGlobals.materialColors.background
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
            color: root.backgroundColor
            anchors.fill: parent

            MouseArea {
                anchors.fill: parent
                onClicked: LogoutState.menuOpen = false

                GridLayout {
                    anchors.centerIn: parent

                    width: parent.width * 0.75
                    height: parent.height * 0.75

                    columns: 3
                    columnSpacing: 8
                    rowSpacing: 8

                    Repeater {
                        model: root.buttons

                        delegate: Rectangle {
                            required property LogoutButton modelData

                            Layout.fillWidth: true
                            Layout.fillHeight: true

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

                            Item {
                                id: icon
                                anchors.centerIn: parent
                                width: parent.width * 0.25
                                height: width

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
                                anchors {
                                    top: icon.bottom
                                    topMargin: 20
                                    horizontalCenter: parent.horizontalCenter
                                }

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

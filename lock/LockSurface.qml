import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import qs
import qs.components
import "../wallpaper"

// The lock screen itself, shared by the real session lock and its preview:
// the wallpaper blurred and dimmed, a large clock and date, and a password
// field that shakes when the password is wrong.
FocusScope {
    id: root

    // Escape: the preview closes on it, the real lock ignores it.
    signal escapePressed

    focus: true

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    BackgroundImage {
        id: wallpaper
        anchors.fill: parent
        visible: false
    }

    FastBlur {
        anchors.fill: parent
        source: wallpaper
        radius: 64
    }

    Rectangle {
        anchors.fill: parent
        color: ShellGlobals.materialColors.background
        opacity: 0.55
    }

    Reveal {
        anchors.centerIn: parent
        width: column.implicitWidth
        height: column.implicitHeight
        shown: LockState.contentShown
        fromScale: 0.98
        focus: true

        ColumnLayout {
            id: column
            spacing: 0

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: Qt.formatDateTime(clock.date, "HH:mm")
                font.pixelSize: 96
                font.bold: true
                color: ShellGlobals.materialColors.onprimarycontainer
            }

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: Qt.formatDateTime(clock.date, "dddd, d MMMM")
                font.pixelSize: 18
                opacity: 0.8
            }

            Item {
                Layout.preferredHeight: 40
            }

            Rectangle {
                id: field
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: 320
                Layout.preferredHeight: 44
                radius: ShellGlobals.radius
                color: ShellGlobals.materialColors.surfacecontainerhighest
                border.width: 1
                border.color: input.activeFocus ? ShellGlobals.materialColors.secondary : "transparent"

                transform: Translate {
                    id: shake
                }

                Behavior on border.color {
                    CAnim {}
                }

                TextInput {
                    id: input
                    anchors.fill: parent
                    anchors.leftMargin: 14
                    anchors.rightMargin: 14
                    verticalAlignment: TextInput.AlignVCenter
                    echoMode: TextInput.Password
                    passwordCharacter: "•"
                    color: ShellGlobals.materialColors.onprimarycontainer
                    font.family: ShellGlobals.fontFamily
                    font.pixelSize: 18
                    focus: true
                    // Typing ahead while PAM checks would be lost, so wait.
                    readOnly: LockState.checking

                    onAccepted: {
                        LockState.submit(input.text);
                        input.text = "";
                    }

                    Keys.onEscapePressed: root.escapePressed()
                }

                StyledText {
                    anchors.fill: input
                    verticalAlignment: Text.AlignVCenter
                    visible: input.text === ""
                    text: LockState.checking ? "" : `Password for ${Quickshell.env("USER")}`
                    font.pixelSize: 15
                    opacity: 0.45
                }
            }

            // Fixed height, so a status appearing does not nudge the layout.
            StyledText {
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 12
                Layout.preferredHeight: 18
                text: LockState.status
                font.pixelSize: 13
                color: LockState.status !== "" && LockState.status !== "Checking…" ? ShellGlobals.materialColors.error : ShellGlobals.materialColors.ontertiarycontainer

                Behavior on color {
                    CAnim {}
                }
            }
        }
    }

    Connections {
        target: LockState

        function onFailuresChanged() {
            shakeAnim.restart();
        }
    }

    // A short, damped side-to-side shake, like a head saying no.
    SequentialAnimation {
        id: shakeAnim

        Anim {
            target: shake
            property: "x"
            to: -12
            time: 45
        }
        Anim {
            target: shake
            property: "x"
            to: 10
            time: 70
        }
        Anim {
            target: shake
            property: "x"
            to: -6
            time: 60
        }
        Anim {
            target: shake
            property: "x"
            to: 3
            time: 50
        }
        Anim {
            target: shake
            property: "x"
            to: 0
            time: 40
        }
    }
}

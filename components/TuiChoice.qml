import QtQuick
import QtQuick.Layouts
import qs

// A row of values with the current one filled in the accent colour, like a
// segmented control in a terminal UI. Clicking a value picks it.
//
// `values` is a list of `{ value, label }`; `current` is the chosen value.
RowLayout {
    id: choice

    property var values: []
    property var current
    // Brighter while the row it sits in is selected.
    property bool active: false

    signal picked(var value)

    spacing: 4

    Repeater {
        model: choice.values

        Rectangle {
            id: chip

            required property var modelData
            readonly property bool chosen: chip.modelData.value === choice.current

            implicitWidth: label.implicitWidth + 16
            implicitHeight: 22
            radius: ShellGlobals.radius
            color: chip.chosen ? ShellGlobals.materialColors.secondary : hover.containsMouse ? ShellGlobals.materialColors.surfacebright : Qt.alpha(ShellGlobals.materialColors.tertiary, choice.active ? 1 : 0.6)

            Behavior on color {
                CAnim {}
            }

            StyledText {
                id: label
                anchors.centerIn: parent
                text: chip.modelData.label
                font.family: ShellGlobals.monoFamily
                font.pixelSize: 11
                font.bold: chip.chosen
                color: chip.chosen ? ShellGlobals.materialColors.onsecondary : ShellGlobals.materialColors.ontertiarycontainer

                Behavior on color {
                    CAnim {}
                }
            }

            MouseArea {
                id: hover
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: choice.picked(chip.modelData.value)
            }
        }
    }
}

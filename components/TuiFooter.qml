import QtQuick
import QtQuick.Layouts
import qs

// The key-hint line under a terminal-styled panel, e.g. "s Scan · ⇥ Pane".
// Each hint is also a button, so everything works with the mouse too.
//
// `hints` is a list of `{ key, label, action }`; `action` is called on click.
Flow {
    id: footer

    property var hints: []

    Layout.fillWidth: true
    spacing: 4

    Repeater {
        model: footer.hints

        Rectangle {
            id: hint
            required property var modelData
            required property int index

            implicitWidth: label.implicitWidth + 10
            implicitHeight: label.implicitHeight + 4
            radius: ShellGlobals.radius
            color: hover.containsMouse ? ShellGlobals.materialColors.tertiary : "transparent"

            StyledText {
                id: label
                anchors.centerIn: parent
                textFormat: Text.StyledText
                text: `<b><font color="${ShellGlobals.materialColors.secondary}">${hint.modelData.key}</font></b> ${hint.modelData.label}`
                font.family: ShellGlobals.monoFamily
                font.pixelSize: 11
            }

            MouseArea {
                id: hover
                anchors.fill: parent
                hoverEnabled: true
                onClicked: hint.modelData.action?.()
            }
        }
    }
}

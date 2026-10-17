import QtQuick
import QtQuick.Layouts
import qs

// Hairline between sections of a popup. Meant to sit in a ColumnLayout.
Rectangle {
    Layout.fillWidth: true
    Layout.preferredHeight: 1
    color: ShellGlobals.materialColors.ontertiarycontainer
    opacity: 0.15
}

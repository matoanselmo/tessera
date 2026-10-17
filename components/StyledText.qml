import QtQuick
import qs

// Text in the shell's face, coloured for a popup card. Call sites only state
// what differs: size, weight, a different role colour.
Text {
    font.family: ShellGlobals.fontFamily
    font.letterSpacing: ShellGlobals.letterSpacing
    font.pixelSize: 12
    color: ShellGlobals.materialColors.ontertiarycontainer
}

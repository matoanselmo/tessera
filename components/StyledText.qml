import QtQuick
import qs

// Text in the shell's face, coloured for a popup card. Call sites only state
// what differs: size, weight, a different role colour.
Text {
    font.family: ShellGlobals.fontFamily
    font.letterSpacing: ShellGlobals.letterSpacing
    font.pixelSize: 12
    // Tabular figures: every digit the same width, so clocks, percentages and
    // counters tick over without the text around them shuffling.
    font.features: {
        "tnum": 1
    }
    color: ShellGlobals.materialColors.ontertiarycontainer
}

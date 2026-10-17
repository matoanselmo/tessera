import QtQuick
import qs

// ColorAnimation on the shell's motion tokens, for hover and state colours.
// Set `time` (not `duration`) and `curve` to change them.
ColorAnimation {
    property real time: ShellGlobals.animFast
    property var curve: ShellGlobals.easeInOut

    duration: time * ShellGlobals.motionScale
    easing.type: Easing.BezierSpline
    easing.bezierCurve: curve
}

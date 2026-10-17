import QtQuick
import qs

// NumberAnimation on the shell's motion tokens. Set `time` (not `duration`)
// and `curve` to change them, so motionScale still applies.
NumberAnimation {
    property real time: ShellGlobals.animNormal
    property var curve: ShellGlobals.easeOut

    duration: time * ShellGlobals.motionScale
    easing.type: Easing.BezierSpline
    easing.bezierCurve: curve
}

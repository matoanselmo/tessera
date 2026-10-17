import QtQuick
import qs

// Horizontal bar filled to `value` (0..1). With `interactive` it becomes a
// slider: a handle appears, and press, drag and wheel report the value asked
// for through `moved`, unclamped, leaving the owner to apply it.
//
// Hand-rolled so it matches the rest of the shell rather than pulling in a
// Controls style.
Item {
    id: root

    property real value: 0
    property int thickness: 4
    property bool interactive: false
    property real wheelStep: 0.05

    readonly property real fraction: Math.max(0, Math.min(1, root.value))

    // For values that advance steadily between updates (media position): set
    // `continuous` and `step` to the update interval, and small forward steps
    // glide linearly across it, so the bar moves continuously instead of
    // ticking. Jumps (seeking, a new track) still ease quickly.
    property bool continuous: false
    property int step: 1000

    // What is drawn: follows `fraction` with an animation.
    property real displayed: 0

    Component.onCompleted: root.displayed = root.fraction

    onFractionChanged: {
        const delta = root.fraction - root.displayed;
        const steady = root.continuous && delta > 0 && delta < 0.05;
        follow.stop();
        follow.to = root.fraction;
        follow.time = steady ? root.step : ShellGlobals.animFast;
        follow.easing.type = steady ? Easing.Linear : Easing.BezierSpline;
        follow.start();
    }

    Anim {
        id: follow
        target: root
        property: "displayed"
    }

    signal moved(real value)

    implicitHeight: root.interactive ? 24 : 12

    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        height: root.thickness
        radius: ShellGlobals.radius
        color: ShellGlobals.materialColors.surfacecontainerhighest

        Rectangle {
            width: parent.width * root.displayed
            height: parent.height
            radius: ShellGlobals.radius
            color: ShellGlobals.materialColors.secondary
        }
    }

    Rectangle {
        visible: root.interactive
        x: (parent.width - width) * root.displayed
        anchors.verticalCenter: parent.verticalCenter
        width: 10
        height: 22
        radius: ShellGlobals.radius
        color: ShellGlobals.materialColors.secondary
    }

    MouseArea {
        anchors.fill: parent
        enabled: root.interactive
        preventStealing: true

        onPressed: event => root.moved(event.x / root.width)
        onPositionChanged: event => {
            if (pressed)
                root.moved(event.x / root.width);
        }
        onWheel: event => root.moved(root.fraction + (event.angleDelta.y > 0 ? root.wheelStep : -root.wheelStep))
    }
}

import QtQuick
import qs

// Shows its children with the shell's entrance motion and hides them with the
// exit motion: a fade, plus an optional scale (`fromScale`) and drift
// (`fromX`, `fromY`) it settles out of. Entering decelerates in; leaving is
// quicker and accelerates away.
//
// It starts hidden even when created with `shown` already true, so content
// that is built on demand (a lazily loaded window) still animates in.
// `exited` fires once it is fully hidden, so a window can unmap only after
// its exit animation has played.
FocusScope {
    id: reveal

    property bool shown: false
    property real fromScale: 1
    property real fromX: 0
    property real fromY: 0
    // Entrance duration; the exit takes 70% of it.
    property real time: ShellGlobals.animNormal

    signal exited

    // Not "shown" until construction is done, so the first appearance is a
    // state change that animates rather than an initial value.
    property bool ready: false
    Component.onCompleted: reveal.ready = true

    opacity: 0
    scale: reveal.fromScale
    transform: Translate {
        id: drift
        x: reveal.fromX
        y: reveal.fromY
    }

    states: State {
        name: "shown"
        when: reveal.shown && reveal.ready

        PropertyChanges {
            reveal.opacity: 1
            reveal.scale: 1
            drift.x: 0
            drift.y: 0
        }
    }

    transitions: [
        Transition {
            from: ""
            to: "shown"

            Anim {
                target: reveal
                properties: "opacity,scale"
                time: reveal.time
            }
            Anim {
                target: drift
                properties: "x,y"
                time: reveal.time
            }
        },
        Transition {
            from: "shown"
            to: ""

            SequentialAnimation {
                ParallelAnimation {
                    Anim {
                        target: reveal
                        properties: "opacity,scale"
                        time: reveal.time * 0.7
                        curve: ShellGlobals.easeIn
                    }
                    Anim {
                        target: drift
                        properties: "x,y"
                        time: reveal.time * 0.7
                        curve: ShellGlobals.easeIn
                    }
                }
                ScriptAction {
                    script: reveal.exited()
                }
            }
        }
    ]
}

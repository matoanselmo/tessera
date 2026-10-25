import QtQuick
import Quickshell
import qs

// A small label that appears beside `target` after the pointer has rested on
// it for `delay` ms. The caller binds `hovered`; the popup window itself is
// only created while showing, so idle tooltips cost nothing.
Scope {
    id: root

    required property Item target
    property string text: ""
    property bool hovered: false
    // Monospace, for tooltips laid out in columns.
    property bool mono: false

    // Which side of the target to open on: Edges.Bottom (default) for the bar,
    // Edges.Left for things already hanging off its right edge.
    property int edge: Edges.Bottom
    property int delay: 500

    property bool shown: false
    // Keeps the popup around while it fades out.
    property bool alive: false

    onHoveredChanged: {
        if (!root.hovered)
            root.shown = false;
    }

    onShownChanged: {
        if (root.shown)
            root.alive = true;
    }

    Timer {
        running: root.hovered && !root.shown && root.text !== ""
        interval: root.delay
        onTriggered: root.shown = true
    }

    LazyLoader {
        active: root.alive

        PopupWindow {
            anchor.item: root.target
            anchor.edges: root.edge
            anchor.gravity: root.edge
            anchor.margins.top: root.edge === Edges.Bottom ? ShellGlobals.barGap : 0
            anchor.margins.left: root.edge === Edges.Left ? -ShellGlobals.barGap : 0

            implicitWidth: label.implicitWidth + 16
            implicitHeight: label.implicitHeight + 10
            color: "transparent"
            visible: true

            // Drifts a few pixels out from the target as it fades in.
            Reveal {
                anchors.fill: parent
                shown: root.shown
                time: 120
                fromX: root.edge === Edges.Left ? 4 : 0
                fromY: root.edge === Edges.Bottom ? -4 : 0
                onExited: root.alive = false

                Rectangle {
                    anchors.fill: parent
                    color: ShellGlobals.materialColors.surfacecontainerhighest
                    radius: ShellGlobals.radius

                    StyledText {
                        id: label
                        anchors.centerIn: parent
                        text: root.text
                        font.bold: true
                        font.family: root.mono ? ShellGlobals.monoFamily : ShellGlobals.fontFamily
                        color: ShellGlobals.materialColors.onprimarycontainer
                    }
                }
            }
        }
    }
}

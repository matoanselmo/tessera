import QtQuick
import Qt5Compat.GraphicalEffects
import qs

// A monochrome icon recoloured to `color`. This is the only ColorOverlay in the
// shell, so moving off Qt5Compat later is a one-file change.
//
// When `source` changes (volume level, Wi-Fi strength, play/pause) the new
// icon crossfades over the old one instead of swapping in a single frame.
//
// Pass an absolute URL, e.g. `Qt.resolvedUrl("icons/close.png")` from the
// caller's own file: Qt 6 resolves a relative path against the file that uses
// it, which would be this one.
Item {
    id: root

    property url source
    property color color: ShellGlobals.materialColors.ontertiarycontainer
    property int size: ShellGlobals.iconSize

    implicitWidth: root.size
    implicitHeight: root.size

    // `front` always shows the current icon; `back` holds the one it replaced
    // while the front fades in over it.
    onSourceChanged: {
        back.source = front.source;
        back.opacity = 1;
        front.source = root.source;
        crossfade.restart();
    }

    component Layer: Item {
        id: layer

        property url source

        anchors.fill: parent

        Image {
            id: image
            anchors.fill: parent
            source: layer.source
            smooth: true
            mipmap: true
            visible: false
        }

        ColorOverlay {
            anchors.fill: parent
            source: image
            color: root.color
        }
    }

    Layer {
        id: back
        opacity: 0
    }

    // Set only here and in onSourceChanged, never bound: a binding could
    // update before the handler runs and hand `back` the new icon.
    Layer {
        id: front
    }

    Component.onCompleted: front.source = root.source

    ParallelAnimation {
        id: crossfade

        Anim {
            target: front
            property: "opacity"
            from: 0
            to: 1
            time: ShellGlobals.animFast
        }
        Anim {
            target: back
            property: "opacity"
            to: 0
            time: ShellGlobals.animFast
            curve: ShellGlobals.easeIn
        }
    }
}

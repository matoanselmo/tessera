import QtQuick
import qs
import qs.components
import qs.services

// The current wallpaper (Wallpapers.source), cropped to fill its area at any
// resolution. Switching crossfades: the new image loads underneath, fades in
// over the old one once it is ready, then takes its place, so there is never
// a blank frame.
Item {
    id: root

    readonly property url source: Wallpapers.source

    clip: true

    component Layer: Image {
        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        smooth: true
        mipmap: true
        // Decoded at the size it is shown, not the file's: wallpapers are
        // often 5K or more.
        sourceSize.width: root.width
        sourceSize.height: root.height
    }

    Layer {
        id: base

        // Once the incoming image has become the base, drop the duplicate.
        onStatusChanged: {
            if (base.status === Image.Ready && base.source === incoming.source) {
                incoming.opacity = 0;
                incoming.source = "";
            }
        }
    }

    Layer {
        id: incoming
        opacity: 0

        onStatusChanged: {
            if (incoming.status === Image.Ready && incoming.source !== "")
                fadeIn.restart();
        }
    }

    Anim {
        id: fadeIn
        target: incoming
        property: "opacity"
        from: 0
        to: 1
        time: ShellGlobals.animSlow
        onFinished: base.source = incoming.source
    }

    // The first image appears directly; only changes crossfade.
    Component.onCompleted: base.source = root.source

    onSourceChanged: {
        if (root.source === base.source)
            return;
        fadeIn.stop();
        incoming.opacity = 0;
        incoming.source = root.source;
    }
}

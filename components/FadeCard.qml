import QtQuick
import qs

// The card inside BarPopup and BarPanel: the popup background, faded in and
// out as `shown` changes. `fadedOut` fires once it is fully transparent, so
// the window around it can unmap only after the animation. A focus scope, so
// a BarPanel's keyboard handling can live inside it.
FocusScope {
    id: card

    property bool shown: false

    signal fadedOut

    opacity: card.shown ? 1 : 0

    Behavior on opacity {
        Anim {}
    }

    onOpacityChanged: {
        if (card.opacity === 0 && !card.shown)
            card.fadedOut();
    }

    // Declared first, so whatever the popup puts in the card draws above it.
    Rectangle {
        anchors.fill: parent
        color: ShellGlobals.materialColors.tertiarycontainer
        radius: ShellGlobals.radius
    }
}

import QtQuick
import qs

// The card inside BarPopup and BarPanel: the popup background, which grows
// out of the bar as it fades in (scaling from its top edge) and shrinks back
// as it fades out, then emits `exited` so the window can unmap.
//
// When the content's height changes while open, the card morphs to the new
// height instead of jumping. Content is laid out at `contentHeight` straight
// away and revealed or clipped by the animated card around it.
Reveal {
    id: card

    // The height the content needs; the card follows it smoothly.
    property real contentHeight: 0
    // The card's current height, mid-animation included. The window should be
    // at least this tall so a shrinking card is not cut off.
    readonly property real animatedHeight: shape.height

    default property alias contentData: inner.data

    fromScale: 0.96
    transformOrigin: Item.Top

    Item {
        id: shape
        width: parent.width
        height: card.contentHeight
        clip: true

        Behavior on height {
            // Only while showing: opening at a new size should not animate.
            enabled: card.shown
            Anim {}
        }

        Rectangle {
            anchors.fill: parent
            color: ShellGlobals.materialColors.tertiarycontainer
            radius: ShellGlobals.radius
        }

        Item {
            id: inner
            width: parent.width
            height: card.contentHeight
        }
    }
}

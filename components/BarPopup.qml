import QtQuick
import Quickshell
import qs

// Base for the menus that drop from the bar: a card that fades in on open()
// and out on close(), only unmapping once the fade has finished. Subclasses
// set the anchor and size and lay their content out inside.
//
// grabFocus stays on for compositors that honour a layer-shell popup grab;
// niri does not, so outside clicks are actually caught by the bar's
// DismissLayer, which calls close() on every registered popup.
PopupWindow {
    id: popup

    default property alias content: card.data

    // Fired once the popup has unmapped, however that came about.
    signal hidden
    signal opened

    color: "transparent"
    visible: false
    grabFocus: true

    function open(): void {
        popup.visible = true;
        card.state = "Open";
        popup.opened();
    }

    // Starts the fade; `card.onOpacityChanged` clears `visible` at the end.
    function close(): void {
        if (popup.visible)
            card.state = "Closed";
    }

    // Decided off visibility, not the card state: a popup still fading out
    // counts as open, so a toggle that lands mid-fade does not bounce it back.
    function toggle(): void {
        if (popup.visible)
            popup.close();
        else
            popup.open();
    }

    // Resetting the card means the next open fades in again, even when the
    // compositor rather than close() took the popup down.
    onVisibleChanged: {
        if (!popup.visible) {
            card.state = "Closed";
            popup.hidden();
        }
    }

    Rectangle {
        anchors.fill: parent
        color: ShellGlobals.materialColors.tertiarycontainer
        opacity: card.opacity
        radius: ShellGlobals.radius
    }

    Item {
        id: card
        anchors.fill: parent

        state: "Closed"
        states: [
            State {
                name: "Open"
                PropertyChanges {
                    card.opacity: 1
                }
            },
            State {
                name: "Closed"
                PropertyChanges {
                    card.opacity: 0
                }
            }
        ]

        onOpacityChanged: {
            if (card.opacity == 0)
                popup.visible = false;
        }

        Behavior on opacity {
            NumberAnimation {
                duration: ShellGlobals.animFade
            }
        }
    }
}

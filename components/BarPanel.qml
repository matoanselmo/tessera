import QtQuick
import Quickshell
import Quickshell.Wayland
import qs

// A dropdown like BarPopup, but a layer-shell surface rather than an
// xdg-popup, because niri never gives a popup the keyboard. It opens below
// the bar with its right edge under `anchorItem`'s, holds the keyboard while
// open, and closes on Escape.
//
// It sits on the overlay layer, above the bar's DismissLayer, so outside
// clicks still dismiss it through the bar's popups list.
PanelWindow {
    id: panel

    required property PanelWindow bar
    required property Item anchorItem

    // Laid out inside a focus scope that holds the keyboard while open.
    default property alias content: card.data

    signal opened
    signal hidden

    // Distance from the screen's right edge, measured each time it opens.
    property real rightInset: 0

    screen: panel.bar.screen
    anchors {
        top: true
        right: true
    }
    margins.top: ShellGlobals.barGap
    margins.right: panel.rightInset

    exclusionMode: ExclusionMode.Normal
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "shell:panel"
    WlrLayershell.keyboardFocus: panel.visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    color: "transparent"
    visible: false

    function open(): void {
        const edge = panel.anchorItem.mapToItem(null, panel.anchorItem.width, 0).x;
        panel.rightInset = Math.max(0, panel.bar.width - edge);
        panel.visible = true;
        card.state = "Open";
        card.forceActiveFocus();
        panel.opened();
    }

    // Starts the fade; `card.onOpacityChanged` clears `visible` at the end.
    function close(): void {
        if (panel.visible)
            card.state = "Closed";
    }

    function toggle(): void {
        if (panel.visible)
            panel.close();
        else
            panel.open();
    }

    onVisibleChanged: {
        if (!panel.visible) {
            card.state = "Closed";
            panel.hidden();
        }
    }

    Rectangle {
        anchors.fill: parent
        color: ShellGlobals.materialColors.tertiarycontainer
        opacity: card.opacity
        radius: ShellGlobals.radius
    }

    FocusScope {
        id: card
        anchors.fill: parent
        focus: true

        Keys.onEscapePressed: panel.close()

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
                panel.visible = false;
        }

        Behavior on opacity {
            NumberAnimation {
                duration: ShellGlobals.animFade
            }
        }
    }
}

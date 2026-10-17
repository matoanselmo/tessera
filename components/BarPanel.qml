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
    default property alias content: card.contentData

    // How tall the content is. Set this rather than implicitHeight: the window
    // follows the card as it morphs between heights.
    property real contentHeight: 0

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

    implicitHeight: Math.max(panel.contentHeight, card.animatedHeight)

    function open(): void {
        const edge = panel.anchorItem.mapToItem(null, panel.anchorItem.width, 0).x;
        panel.rightInset = Math.max(0, panel.bar.width - edge);
        panel.visible = true;
        card.shown = true;
        card.forceActiveFocus();
        panel.opened();
    }

    // Starts the fade; the card unmaps the panel once it has faded out.
    function close(): void {
        if (panel.visible)
            card.shown = false;
    }

    function toggle(): void {
        if (panel.visible)
            panel.close();
        else
            panel.open();
    }

    onVisibleChanged: {
        if (!panel.visible) {
            card.shown = false;
            panel.hidden();
        }
    }

    FadeCard {
        id: card
        width: parent.width
        contentHeight: panel.contentHeight
        focus: true

        Keys.onEscapePressed: panel.close()
        onExited: panel.visible = false
    }
}

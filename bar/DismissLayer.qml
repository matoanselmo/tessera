import Quickshell
import Quickshell.Wayland
import QtQuick

// Full-screen click catcher that sits behind whichever bar menu is open.
//
// PopupWindow.grabFocus would be the idiomatic way to dismiss these, but niri
// only honours an xdg_popup grab when the parent layer surface can take
// keyboard focus, and giving the bar focus would make it steal input from the
// focused window on hover, since focus-follows-mouse is on.
//
// This window is mapped after the bar, so it stacks above the bar while still
// sitting below the menu's own popup surface: a press anywhere except inside
// the menu lands here.
Scope {
    id: root

    required property ShellScreen screen

    property bool active: false

    signal dismissed

    LazyLoader {
        active: root.active

        PanelWindow {
            screen: root.screen

            anchors {
                top: true
                left: true
                right: true
                bottom: true
            }

            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Top
            WlrLayershell.namespace: "tessera:dismiss"
            color: "transparent"

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton

                // On press rather than click, so the menu goes away on the way
                // down like every other menu in the shell.
                onPressed: root.dismissed()
            }
        }
    }
}

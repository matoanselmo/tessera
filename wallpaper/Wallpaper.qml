import Quickshell
import Quickshell.Wayland
import QtQuick

// One background layer per screen; previously a single window, so a second
// monitor got no wallpaper.
Variants {
    model: Quickshell.screens

    PanelWindow {
        id: window
        required property var modelData
        screen: modelData

        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Background
        WlrLayershell.namespace: "tessera:background"

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        BackgroundImage {
            anchors.fill: parent
        }
    }
}

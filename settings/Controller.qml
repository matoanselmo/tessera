pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.components

// The settings window: qs ipc call settings toggle|open|close
Singleton {
    id: controller

    function open(): void {
        overlay.open();
    }

    OverlayController {
        id: overlay
        ipcTarget: "settings"
        namespace: "tessera:settings"
        layer: WlrLayer.Overlay
        exclusionMode: ExclusionMode.Ignore
        content: Component {
            SettingsContent {}
        }
    }

    // Referenced from shell.qml purely to force the singleton to instantiate,
    // which is what registers the IPC handler above.
    function init(): void {}
}

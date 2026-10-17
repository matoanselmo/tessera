pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.components

Singleton {
    OverlayController {
        ipcTarget: "launcher"
        namespace: "shell:launcher"
        content: Component {
            LaunchContent {}
        }
    }

    // Referenced from shell.qml purely to force the singleton to instantiate,
    // which is what registers the IPC handler above.
    function init(): void {}
}

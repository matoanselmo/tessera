pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs.components

Singleton {
    id: controller

    // Text to start the launcher with, picked up as it opens; and the same
    // for a launcher that is already open.
    property string pendingQuery: ""
    signal queryRequested(string text)

    function openWith(text: string): void {
        controller.pendingQuery = text;
        controller.queryRequested(text);
        overlay.open();
    }

    // Straight into clipboard history: qs ipc call clipboard toggle|open
    IpcHandler {
        target: "clipboard"

        function toggle(): void {
            if (overlay.isOpen)
                overlay.close();
            else
                controller.openWith(";");
        }

        function open(): void {
            controller.openWith(";");
        }
    }

    OverlayController {
        id: overlay
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

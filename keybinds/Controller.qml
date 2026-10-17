pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import qs.components

import "parse.js" as Parse

Singleton {
    id: controller

    // Rows parsed from the niri config, refreshed whenever the file changes.
    property var binds: []

    FileView {
        id: configFile

        // Same lookup order niri uses for its own config.
        path: Quickshell.env("NIRI_CONFIG") || `${Quickshell.env("XDG_CONFIG_HOME") || Quickshell.env("HOME") + "/.config"}/niri/config.kdl`
        watchChanges: true

        onFileChanged: configFile.reload()
        onLoaded: controller.binds = Parse.parseBinds(configFile.text())
        onLoadFailed: controller.binds = []
    }

    OverlayController {
        ipcTarget: "keybinds"
        namespace: "tessera:keybinds"
        layer: WlrLayer.Overlay
        exclusionMode: ExclusionMode.Ignore
        content: Component {
            KeybindsContent {
                binds: controller.binds
            }
        }
    }

    // Referenced from shell.qml purely to force the singleton to instantiate,
    // which is what registers the IPC handler above.
    function init(): void {}
}

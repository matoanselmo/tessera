import Quickshell
import QtQuick

import "bar"
import "wallpaper"
import "osd"
import "launcher" as Launcher
import "keybinds" as Keybinds
import qs.services

Scope {
    // Touching the singletons is what instantiates them and registers their IPC targets.
    Component.onCompleted: {
        Launcher.Controller.init();
        Keybinds.Controller.init();
        Clipboard.init();
    }

    Bar {}
    Wallpaper {}
    VolumeOsd {}
}

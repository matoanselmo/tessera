import Quickshell
import QtQuick

import "bar"
import "wallpaper"
import "launcher" as Launcher
import "keybinds" as Keybinds

Scope {
    // Touching the singletons is what instantiates them and registers their IPC targets.
    Component.onCompleted: {
        Launcher.Controller.init();
        Keybinds.Controller.init();
    }

    Bar {}
    Wallpaper {}
}

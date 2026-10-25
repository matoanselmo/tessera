import Quickshell
import QtQuick

import "bar"
import "wallpaper"
import "osd"
import "lock"
import "launcher" as Launcher
import "keybinds" as Keybinds
import "terminal" as Terminal
import "settings" as SettingsWindow
import qs.services

Scope {
    // Touching the singletons is what instantiates them and registers their IPC targets.
    Component.onCompleted: {
        Launcher.Controller.init();
        Keybinds.Controller.init();
        Clipboard.init();
        Terminal.PopupTerminal.init();
        SettingsWindow.Controller.init();
    }

    Bar {}
    Wallpaper {}
    VolumeOsd {}
    Lock {}
}

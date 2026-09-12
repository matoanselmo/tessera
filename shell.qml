import Quickshell
import QtQuick

import "bar"
import "wallpaper"
import "logout"
import "launcher" as Launcher

Scope {
    // Touching the singleton is what instantiates it and registers its IPC target.
    Component.onCompleted: Launcher.Controller.init()

    Bar {}
    Wallpaper {}
    Logout {}
}

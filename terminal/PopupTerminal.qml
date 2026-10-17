pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.services

// A one-off floating terminal: a fresh foot that pops up over everything and
// closes itself as soon as focus leaves it, taking its shell with it.
//
//     qs ipc call terminal toggle|open|close
//
// The niri config has a window rule that floats and centres windows with the
// `shell-popup` app id.
Singleton {
    id: root

    readonly property string appId: "shell-popup"
    readonly property var window: Niri.windows.find(w => w.app_id === root.appId) ?? null
    readonly property bool isOpen: root.window !== null

    // Whether the popup had focus at the last focus change; losing it after
    // having it is what closes the popup.
    property bool hadFocus: false

    function open(): void {
        if (!root.isOpen)
            Quickshell.execDetached(["foot", "--app-id", root.appId, "--title", "Popup terminal"]);
    }

    function close(): void {
        if (root.window)
            Niri.action({
                CloseWindow: {
                    id: root.window.id
                }
            });
    }

    function toggle(): void {
        if (root.isOpen)
            root.close();
        else
            root.open();
    }

    Connections {
        target: Niri

        function onFocusedWindowIdChanged() {
            const focused = root.window !== null && Niri.focusedWindowId === root.window.id;
            if (root.hadFocus && !focused)
                root.close();
            root.hadFocus = focused;
        }
    }

    IpcHandler {
        target: "terminal"

        function toggle(): void {
            root.toggle();
        }

        function open(): void {
            root.open();
        }

        function close(): void {
            root.close();
        }
    }

    // Referenced from shell.qml so the IPC target exists from the start.
    function init(): void {}
}

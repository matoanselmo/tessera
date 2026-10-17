pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// The power actions, plus the open state of the menu that lists them. The
// menu drops from the power button on every bar, so its state and the IPC
// target live here to be registered exactly once.
//
//     qs ipc call logout toggle|open|close
Singleton {
    id: state

    property bool menuOpen: false

    // Ordered least to most disruptive.
    readonly property list<LogoutButton> actions: [
        LogoutButton {
            // swaylock is the installed locker; the lock signal is the fallback and
            // is inert unless something is listening for it.
            command: "command -v swaylock >/dev/null 2>&1 && swaylock -f || loginctl lock-session"
            text: "Lock"
            icon: "lock"
        },
        LogoutButton {
            command: "systemctl suspend"
            text: "Suspend"
            icon: "suspend"
        },
        LogoutButton {
            // The menu is its own confirmation, so skip niri's prompt.
            command: "niri msg action quit --skip-confirmation"
            text: "Log out"
            icon: "logout"
        },
        LogoutButton {
            command: "systemctl reboot"
            text: "Reboot"
            icon: "reboot"
        },
        LogoutButton {
            command: "systemctl poweroff"
            text: "Shutdown"
            icon: "shutdown"
        }
    ]

    IpcHandler {
        target: "logout"

        function toggle(): void {
            state.menuOpen = !state.menuOpen;
        }

        function open(): void {
            state.menuOpen = true;
        }

        function close(): void {
            state.menuOpen = false;
        }
    }
}

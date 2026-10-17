import QtQuick
import Quickshell

// Scope, not ShellRoot: this is nested inside shell.qml's root, and ShellRoot is
// meant to be the root of the shell itself.
Scope {
	LogoutMenu {
		// Ordered least to most disruptive.
		LogoutButton {
			// swaylock is the installed locker; the lock signal is the fallback and
			// is inert unless something is listening for it.
			command: "command -v swaylock >/dev/null 2>&1 && swaylock -f || loginctl lock-session"
			keybind: Qt.Key_L
			text: "Lock"
			icon: "lock"
		}

		LogoutButton {
			command: "systemctl suspend"
			keybind: Qt.Key_S
			text: "Suspend"
			icon: "suspend"
		}

		LogoutButton {
			// The menu is its own confirmation, so skip niri's prompt.
			command: "niri msg action quit --skip-confirmation"
			keybind: Qt.Key_E
			text: "Log out"
			icon: "logout"
		}

		LogoutButton {
			command: "systemctl reboot"
			keybind: Qt.Key_R
			text: "Reboot"
			icon: "reboot"
		}

		LogoutButton {
			command: "systemctl poweroff"
			keybind: Qt.Key_P
			text: "Shutdown"
			icon: "shutdown"
		}
	}
}

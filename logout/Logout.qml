import QtQuick
import Quickshell

// Scope, not ShellRoot: this is nested inside shell.qml's root, and ShellRoot is
// meant to be the root of the shell itself.
Scope {
	LogoutMenu {
		// Ordered least to most disruptive.
		LogoutButton {
			// Emits the standard lock signal. Inert until a locker is running to
			// answer it; on Hyprland that is normally hyprlock.
			command: "command -v hyprlock >/dev/null 2>&1 && hyprlock || loginctl lock-session"
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
			// This session is uwsm-managed, so stopping the unit is the clean
			// exit; the dispatch is the fallback for a bare Hyprland session.
			command: "command -v uwsm >/dev/null 2>&1 && uwsm stop || hyprctl dispatch 'hl.dsp.exit()'"
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

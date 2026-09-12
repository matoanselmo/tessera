import QtQuick
import Quickshell

// Scope, not ShellRoot: this is nested inside shell.qml's root, and ShellRoot is
// meant to be the root of the shell itself.
Scope {
	LogoutMenu {
		LogoutButton {
			command: "systemctl suspend"
			keybind: Qt.Key_S
			text: "Suspend"
			icon: "suspend"
		}

		LogoutButton {
			command: "systemctl poweroff"
			keybind: Qt.Key_P
			text: "Shutdown"
			icon: "shutdown"
		}

		LogoutButton {
			command: "systemctl reboot"
			keybind: Qt.Key_R
			text: "Reboot"
			icon: "reboot"
		}
	}
}

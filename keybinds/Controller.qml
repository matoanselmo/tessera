pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Io

import "parse.js" as Parse

Singleton {
	id: controller

	// Rows parsed from the niri config, refreshed whenever the file changes.
	property var binds: []

	PersistentProperties {
		id: persist
		property bool keybindsOpen: false;
	}

	IpcHandler {
		target: "keybinds"

		function toggle(): void {
			persist.keybindsOpen = !persist.keybindsOpen;
		}

		function open(): void {
			persist.keybindsOpen = true;
		}

		function close(): void {
			persist.keybindsOpen = false;
		}
	}

	FileView {
		id: configFile

		// Same lookup order niri uses for its own config.
		path: Quickshell.env("NIRI_CONFIG") || `${Quickshell.env("XDG_CONFIG_HOME") || Quickshell.env("HOME") + "/.config"}/niri/config.kdl`
		watchChanges: true

		onFileChanged: configFile.reload()
		onLoaded: controller.binds = Parse.parseBinds(configFile.text())
		onLoadFailed: controller.binds = []
	}

	LazyLoader {
		id: loader
		activeAsync: persist.keybindsOpen

		PanelWindow {
			id: keybindsWindow
			color: "transparent"
			implicitWidth: content.width
			implicitHeight: content.height
			exclusionMode: ExclusionMode.Ignore
			WlrLayershell.layer: WlrLayer.Overlay
			WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
			WlrLayershell.namespace: "shell:keybinds"

			MouseArea {
				anchors.fill: parent

				onPressed: persist.keybindsOpen = false

				MouseArea {
					anchors.centerIn: parent
					width: content.width
					height: content.height

					KeybindsContent {
						id: content
						binds: controller.binds
						onCloseRequested: persist.keybindsOpen = false
					}
				}
			}
		}
	}

	// Referenced from shell.qml purely to force the singleton to instantiate,
	// which is what registers the IPC handler above.
	function init(): void {}
}

pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Io

Singleton {
	id: controller

	PersistentProperties {
		id: persist
		property bool launcherOpen: false;
	}

	IpcHandler {
		target: "launcher"

		function toggle(): void {
			persist.launcherOpen = !persist.launcherOpen;
		}

		function open(): void {
			persist.launcherOpen = true;
		}

		function close(): void {
			persist.launcherOpen = false;
		}
	}

	LazyLoader {
		id: loader
		activeAsync: persist.launcherOpen

		PanelWindow {
			id: launcherWindow
			color: "transparent"
			implicitWidth: content.width
			implicitHeight: content.height
			WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
			WlrLayershell.namespace: "shell:launcher"

			MouseArea {
				anchors.fill: parent

				onPressed: persist.launcherOpen = false

				MouseArea {
					anchors.centerIn: parent
					width: content.width
					height: content.height

					LaunchContent {
						id: content
						onCloseRequested: persist.launcherOpen = false
					}
				}
			}
		}
	}

	// Referenced from shell.qml purely to force the singleton to instantiate,
	// which is what registers the IPC handler above.
	function init(): void {}
}

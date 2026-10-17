pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Io

// A keyboard-grabbing overlay driven over IPC:
//
//     qs ipc call <ipcTarget> toggle|open|close
//
// The window only exists while open. `content` is instantiated inside it and
// closes the overlay by emitting `closeRequested`. A press on the window
// outside the content's visible card also closes it.
//
// Instantiate this once, from a singleton, so the IPC target is registered
// exactly once rather than once per screen.
Scope {
    id: root

    required property string ipcTarget
    required property string namespace
    required property Component content

    property int layer: WlrLayer.Top
    property int exclusionMode: ExclusionMode.Auto

    readonly property bool isOpen: persist.isOpen

    function open(): void {
        persist.isOpen = true;
    }

    function close(): void {
        persist.isOpen = false;
    }

    function toggle(): void {
        persist.isOpen = !persist.isOpen;
    }

    // Survives a config reload, so editing the shell does not slam the
    // overlay shut while you are looking at it.
    PersistentProperties {
        id: persist
        reloadableId: `overlay:${root.ipcTarget}`
        property bool isOpen: false
    }

    IpcHandler {
        target: root.ipcTarget

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

    LazyLoader {
        activeAsync: persist.isOpen

        PanelWindow {
            color: "transparent"
            implicitWidth: loader.width
            implicitHeight: loader.height
            exclusionMode: root.exclusionMode
            WlrLayershell.layer: root.layer
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
            WlrLayershell.namespace: root.namespace

            MouseArea {
                anchors.fill: parent

                onPressed: root.close()

                // Swallows presses on the content so they do not close it.
                MouseArea {
                    anchors.centerIn: parent
                    width: loader.width
                    height: loader.height

                    // A Loader is a focus scope: without `focus` here the
                    // content's own focused field never gets the keyboard.
                    Loader {
                        id: loader
                        focus: true
                        sourceComponent: root.content
                    }

                    Connections {
                        target: loader.item
                        ignoreUnknownSignals: true

                        function onCloseRequested() {
                            root.close();
                        }
                    }
                }
            }
        }
    }
}

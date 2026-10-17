import QtQuick
import Quickshell
import Quickshell.Wayland
import qs

// The session lock (one lock surface per screen) and its preview.
//
// If the shell ever dies while locked, niri keeps the session locked on a
// blank screen until a lock client unlocks it: from a TTY, run
// `WAYLAND_DISPLAY=wayland-1 swaylock` and unlock with your password.
Scope {
    WlSessionLock {
        locked: LockState.locked

        WlSessionLockSurface {
            color: ShellGlobals.materialColors.background

            LockSurface {
                anchors.fill: parent
            }
        }
    }

    // The same screen in an ordinary overlay window, which locks nothing.
    LazyLoader {
        active: LockState.previewing

        PanelWindow {
            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }

            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
            WlrLayershell.namespace: "shell:lockpreview"
            color: ShellGlobals.materialColors.background

            LockSurface {
                anchors.fill: parent
                onEscapePressed: LockState.closePreview()
            }
        }
    }
}

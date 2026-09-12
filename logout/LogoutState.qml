pragma Singleton

import Quickshell
import Quickshell.Io

// Visibility state and the IPC target live here so that the handler is
// registered exactly once. It used to sit inside the per-screen window, which
// would have registered the same target once per monitor.
Singleton {
    id: state

    property bool menuOpen: false

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

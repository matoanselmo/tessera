pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Mirror of niri's workspaces and windows, fed by its JSON event stream.
// Quickshell ships no niri module, so this stands in for Quickshell.Hyprland.
// Entries are the plain objects niri sends and are replaced, never mutated,
// so bindings that read them re-evaluate.
Singleton {
    id: root

    property var workspaces: []
    property var windows: []
    property var focusedWindowId: null

    readonly property var focusedWindow: root.windows.find(w => w.id === root.focusedWindowId) ?? null

    function workspaceById(id: var): var {
        return root.workspaces.find(ws => ws.id === id) ?? null;
    }

    // niri addresses workspaces by index within the focused output, so focus
    // the workspace's output first.
    function focusWorkspace(ws: var): void {
        Quickshell.execDetached(["sh", "-c", 'niri msg action focus-monitor "$1" && niri msg action focus-workspace "$2"', "sh", ws.output, String(ws.idx)]);
    }

    function toggleOverview(): void {
        Quickshell.execDetached(["niri", "msg", "action", "toggle-overview"]);
    }

    function handle(line: string): void {
        let event;
        try {
            event = JSON.parse(line);
        } catch (e) {
            return;
        }

        if (event.WorkspacesChanged) {
            root.workspaces = event.WorkspacesChanged.workspaces;
        } else if (event.WorkspaceActivated) {
            // The activated workspace becomes active on its output; if it also
            // took focus, it is now the only focused workspace anywhere.
            const { id, focused } = event.WorkspaceActivated;
            const output = root.workspaceById(id)?.output;
            root.workspaces = root.workspaces.map(ws => Object.assign({}, ws, {
                is_active: ws.output === output ? ws.id === id : ws.is_active,
                is_focused: focused ? ws.id === id : ws.is_focused
            }));
        } else if (event.WorkspaceUrgencyChanged) {
            const { id, urgent } = event.WorkspaceUrgencyChanged;
            root.workspaces = root.workspaces.map(ws => ws.id === id ? Object.assign({}, ws, { is_urgent: urgent }) : ws);
        } else if (event.WorkspaceActiveWindowChanged) {
            const { workspace_id, active_window_id } = event.WorkspaceActiveWindowChanged;
            root.workspaces = root.workspaces.map(ws => ws.id === workspace_id ? Object.assign({}, ws, { active_window_id }) : ws);
        } else if (event.WindowsChanged) {
            root.windows = event.WindowsChanged.windows;
            root.focusedWindowId = root.windows.find(w => w.is_focused)?.id ?? null;
        } else if (event.WindowOpenedOrChanged) {
            const win = event.WindowOpenedOrChanged.window;
            const rest = root.windows.filter(w => w.id !== win.id);
            root.windows = [...rest, win];
            if (win.is_focused)
                root.focusedWindowId = win.id;
        } else if (event.WindowClosed) {
            const id = event.WindowClosed.id;
            root.windows = root.windows.filter(w => w.id !== id);
            if (root.focusedWindowId === id)
                root.focusedWindowId = null;
        } else if (event.WindowFocusChanged) {
            root.focusedWindowId = event.WindowFocusChanged.id;
        }
    }

    Process {
        id: stream
        running: true
        command: ["niri", "msg", "--json", "event-stream"]

        stdout: SplitParser {
            onRead: line => root.handle(line)
        }

        // The stream ends if niri reloads its socket or is not up yet; the
        // first event on reconnect is a full snapshot, so nothing goes stale.
        onExited: reconnect.start()
    }

    Timer {
        id: reconnect
        interval: 1000
        onTriggered: stream.running = true
    }
}

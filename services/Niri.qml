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

    // Name of the output holding keyboard focus, e.g. "HDMI-A-2".
    readonly property string focusedOutput: root.workspaces.find(ws => ws.is_focused)?.output ?? ""

    function workspaceById(id: var): var {
        return root.workspaces.find(ws => ws.id === id) ?? null;
    }

    // Windows on a workspace in the order they sit: by column, then by
    // position within it; floating windows (no column) after the rest.
    function windowsOn(workspaceId: var): var {
        const pos = w => w.layout?.pos_in_scrolling_layout ?? [Infinity, w.id];
        return root.windows.filter(w => w.workspace_id === workspaceId).sort((a, b) => (pos(a)[0] - pos(b)[0]) || (pos(a)[1] - pos(b)[1]) || (a.id - b.id));
    }

    // Sends a niri action over the IPC socket, e.g. `{ ToggleOverview: {} }`.
    function action(request: var): void {
        if (!ipc.connected)
            ipc.connected = true;
        ipc.write(JSON.stringify({
            Action: request
        }) + "\n");
        ipc.flush();
    }

    // By id, which works on any output without focusing it first. The CLI
    // only takes an index on the focused output, and the focus-monitor it
    // needed warped the pointer to the middle of the screen on every click.
    function focusWorkspace(ws: var): void {
        root.action({
            FocusWorkspace: {
                reference: {
                    Id: ws.id
                }
            }
        });
    }

    function toggleOverview(): void {
        root.action({
            ToggleOverview: {}
        });
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
        } else if (event.WindowLayoutsChanged) {
            // `changes` is a list of [window id, layout] pairs.
            const layouts = new Map(event.WindowLayoutsChanged.changes);
            root.windows = root.windows.map(w => layouts.has(w.id) ? Object.assign({}, w, { layout: layouts.get(w.id) }) : w);
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

    // One long-lived connection for actions; niri answers each request line
    // with a reply line, which is read and dropped.
    Socket {
        id: ipc
        path: Quickshell.env("NIRI_SOCKET")
        connected: true

        parser: SplitParser {}

        onConnectedChanged: {
            if (!ipc.connected)
                reconnectIpc.start();
        }
    }

    Timer {
        id: reconnectIpc
        interval: 1000
        onTriggered: ipc.connected = true
    }
}

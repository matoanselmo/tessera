import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs

// Title of the focused window, claimed only by the bar on the monitor that
// actually holds focus, so a second monitor does not echo the same title.
BarWidget {
    id: root

    required property ShellScreen screen

    readonly property HyprlandMonitor monitor: Hyprland.monitorFor(root.screen)
    readonly property HyprlandToplevel toplevel: Hyprland.activeToplevel

    // Gate on the window actually sitting on this monitor's current workspace.
    // Hyprland does not reliably announce focus moving to an empty workspace, so
    // activeToplevel can hold a window that is no longer focused; comparing
    // workspaces catches that, and it also stops a second monitor's bar from
    // echoing a window belonging to another screen.
    readonly property string title: root.toplevel && root.monitor && root.toplevel.workspace === root.monitor.activeWorkspace ? root.toplevel.title : ""

    visible: root.title !== ""

    icon: "window"
    label: root.title
    color: ShellGlobals.materialColors.primary
    foreground: ShellGlobals.materialColors.onprimary
}

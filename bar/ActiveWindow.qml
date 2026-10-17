import QtQuick
import Quickshell
import qs

// Title of the focused window, claimed only by the bar on the output that
// actually holds it, so a second monitor does not echo the same title.
BarWidget {
    id: root

    required property ShellScreen screen

    // niri reports focus moving to an empty workspace as no focused window, so
    // this clears on its own; the output check keeps other bars quiet.
    readonly property var window: Niri.focusedWindow
    readonly property string title: root.window && Niri.workspaceById(root.window.workspace_id)?.output === root.screen.name ? (root.window.title ?? "") : ""

    visible: root.title !== ""

    icon: "window"
    label: root.title
    color: ShellGlobals.materialColors.primary
    foreground: ShellGlobals.materialColors.onprimary
}

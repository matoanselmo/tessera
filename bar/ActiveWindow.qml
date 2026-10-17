import QtQuick
import Quickshell
import qs
import qs.components
import qs.services

// Title of the focused window, claimed only by the bar on the output that
// actually holds it, so a second monitor does not echo the same title.
BarWidget {
    id: root

    required property ShellScreen screen

    // niri reports focus moving to an empty workspace as no focused window, so
    // this clears on its own; the output check keeps other bars quiet.
    readonly property var window: Niri.focusedWindow
    readonly property string title: root.window && Niri.workspaceById(root.window.workspace_id)?.output === root.screen.name ? (root.window.title ?? "") : ""

    // The last title shown, kept while the widget fades out so it does not
    // blank before it disappears.
    property string shownTitle: ""

    onTitleChanged: {
        if (root.title !== "")
            root.shownTitle = root.title;
    }

    // A different window fades its title in; the same window retitling itself
    // (terminals do, constantly) just updates.
    readonly property var windowId: root.window?.id ?? null
    onWindowIdChanged: root.refreshLabel()

    opacity: root.title !== "" ? 1 : 0
    visible: root.opacity > 0

    Behavior on opacity {
        Anim {}
    }

    icon: "window"
    label: root.shownTitle
    // The label elides against the clock, so the full title lives here.
    tooltip: root.title
    color: ShellGlobals.materialColors.primary
    foreground: ShellGlobals.materialColors.onprimary
}

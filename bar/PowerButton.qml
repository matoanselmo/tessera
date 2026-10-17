import QtQuick
import qs

// Toggles the power menu that drops below it. Kept quiet until pointed at, so
// the one destructive control in the bar announces itself on hover (or while
// its menu is open) rather than sitting there in red.
BarWidget {
    id: root

    // Set by the bar while the power menu is showing.
    property bool active: false

    readonly property bool lit: root.hovered || root.active

    icon: "power.svg"
    color: root.lit ? ShellGlobals.materialColors.errorcontainer : ShellGlobals.materialColors.primarycontainer
    foreground: root.lit ? ShellGlobals.materialColors.onerrorcontainer : ShellGlobals.materialColors.onprimarycontainer

    interactive: true

    Behavior on color {
        ColorAnimation {
            duration: ShellGlobals.animFast
        }
    }
}

import QtQuick
import qs
import qs.logout

// Opens the same full-screen logout menu the "logout" IPC target toggles. Kept
// quiet until pointed at, so the one destructive control in the bar announces
// itself on hover rather than sitting there in red.
BarWidget {
    id: root

    icon: "power.svg"
    color: root.hovered ? ShellGlobals.materialColors.errorcontainer : ShellGlobals.materialColors.primarycontainer
    foreground: root.hovered ? ShellGlobals.materialColors.onerrorcontainer : ShellGlobals.materialColors.onprimarycontainer

    interactive: true
    onClicked: LogoutState.menuOpen = !LogoutState.menuOpen

    Behavior on color {
        ColorAnimation {
            duration: 140
        }
    }
}

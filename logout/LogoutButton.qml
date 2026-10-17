import QtQuick
import Quickshell

// One entry in the power menu: a shell command with a label and an icon
// from logout/icons.
QtObject {
    id: button

    required property string command
    required property string text
    required property string icon

    // When set, the menu asks for a second click before running the command,
    // showing this as the prompt. For actions that end the session.
    property string confirm: ""

    // Resolved here so the icon name stays relative to logout/icons wherever
    // the menu that draws it lives.
    readonly property url iconUrl: Qt.resolvedUrl(`icons/${button.icon}.png`)

    function exec(): void {
        Quickshell.execDetached(["sh", "-c", button.command]);
    }
}

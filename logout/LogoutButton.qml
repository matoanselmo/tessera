import QtQuick
import Quickshell

// One entry in the power menu: a shell command (or an action inside the
// shell) with a label and an icon from logout/icons.
QtObject {
    id: button

    // Run with sh -c, unless `run` is set.
    property string command: ""
    // A function to call instead of a command, for actions the shell does
    // itself (locking).
    property var run: null
    required property string text
    required property string icon

    // When set, the menu asks for a second click before running the command,
    // showing this as the prompt. For actions that end the session.
    property string confirm: ""

    // Resolved here so the icon name stays relative to logout/icons wherever
    // the menu that draws it lives.
    readonly property url iconUrl: Qt.resolvedUrl(`icons/${button.icon}.png`)

    function exec(): void {
        if (button.run)
            button.run();
        else
            Quickshell.execDetached(["sh", "-c", button.command]);
    }
}

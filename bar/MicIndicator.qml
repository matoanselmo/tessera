import QtQuick
import qs
import qs.components
import qs.services

// Only there when the microphone needs attention: in red while muted, in the
// accent colour while an app is listening. Click to mute or unmute.
BarWidget {
    id: root

    readonly property bool wanted: Audio.source !== null && (Audio.micMuted || Audio.micInUse)

    opacity: root.wanted ? 1 : 0
    visible: root.opacity > 0

    Behavior on opacity {
        Anim {}
    }

    icon: Audio.micMuted ? "mic-muted.svg" : "mic.svg"
    color: Audio.micMuted ? ShellGlobals.materialColors.errorcontainer : ShellGlobals.materialColors.secondary
    foreground: Audio.micMuted ? ShellGlobals.materialColors.onerrorcontainer : ShellGlobals.materialColors.onsecondary

    interactive: true
    onClicked: Audio.toggleMicMute()

    tooltip: {
        if (Audio.micMuted)
            return "Microphone muted · click to unmute";
        const apps = [...new Set(Audio.recorders.map(n => n.properties?.["application.name"] || n.name))];
        return `Microphone in use by ${apps.join(", ")} · click to mute`;
    }
}

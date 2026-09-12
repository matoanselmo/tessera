import QtQuick
import Quickshell.Services.Pipewire
import qs

BarWidget {
    id: root

    signal toggleRequested

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property bool muted: root.sink?.audio?.muted ?? false
    readonly property real volume: root.sink?.audio?.volume ?? 0
    readonly property int percent: Math.round(root.volume * 100)

    // A node only publishes live volume and mute state while something binds it.
    PwObjectTracker {
        objects: root.sink ? [root.sink] : []
    }

    icon: {
        if (root.muted || root.percent === 0)
            return "volume-muted.svg";
        if (root.percent < 34)
            return "volume-low.svg";
        if (root.percent < 67)
            return "volume-medium.svg";

        return "volume-high.svg";
    }

    label: root.muted ? "off" : `${root.percent}%`
    color: ShellGlobals.materialColors.tertiarycontainer
    foreground: ShellGlobals.materialColors.ontertiarycontainer

    interactive: true
    onClicked: root.toggleRequested()

    onScrolled: delta => {
        if (!root.sink?.audio)
            return;

        root.sink.audio.muted = false;
        root.sink.audio.volume = Math.max(0, Math.min(1, root.volume + (delta > 0 ? 0.05 : -0.05)));
    }
}

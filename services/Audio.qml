pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

// The default output device and the other sinks it can be switched to.
Singleton {
    id: root

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property bool muted: root.sink?.audio?.muted ?? false
    readonly property real volume: root.sink?.audio?.volume ?? 0
    readonly property int percent: Math.round(root.volume * 100)

    // Hardware outputs only; per-application streams are sinks too.
    readonly property var sinks: [...Pipewire.nodes.values].filter(n => n.isSink && !n.isStream)

    // A node only publishes live volume, mute state and description while
    // something binds it.
    PwObjectTracker {
        objects: root.sink ? [root.sink, ...root.sinks] : root.sinks
    }

    // Unmutes too, since asking for a level means wanting to hear it.
    function setVolume(fraction: real): void {
        if (!root.sink?.audio)
            return;

        root.sink.audio.muted = false;
        root.sink.audio.volume = Math.max(0, Math.min(1, fraction));
    }

    function nudge(delta: real): void {
        root.setVolume(root.volume + delta);
    }

    function toggleMute(): void {
        if (root.sink?.audio)
            root.sink.audio.muted = !root.muted;
    }

    function setDefaultSink(node: PwNode): void {
        Pipewire.preferredDefaultAudioSink = node;
    }
}

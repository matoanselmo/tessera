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

    // Icon file name in bar/icons for the current level.
    readonly property string icon: {
        if (root.muted || root.percent === 0)
            return "volume-muted.svg";
        if (root.percent < 34)
            return "volume-low.svg";
        if (root.percent < 67)
            return "volume-medium.svg";

        return "volume-high.svg";
    }

    // Fired when the default sink's volume or mute state changes, from the
    // shell or anything else (media keys run wpctl). Switching sinks, startup
    // and a sink coming up do not count, so an OSD can show on this alone.
    signal adjusted

    // The last settled reading, compared against to decide what changed.
    property var last: ({
            sink: null,
            volume: -1,
            muted: false
        })

    function check(): void {
        if (!root.sink?.ready || !root.sink.audio)
            return;

        const prev = root.last;
        root.last = {
            sink: root.sink,
            volume: root.volume,
            muted: root.muted
        };

        if (prev.sink === root.sink && (prev.volume !== root.volume || prev.muted !== root.muted))
            root.adjusted();
    }

    onSinkChanged: root.check()
    onVolumeChanged: root.check()
    onMutedChanged: root.check()

    Connections {
        target: root.sink

        function onReadyChanged() {
            root.check();
        }
    }

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

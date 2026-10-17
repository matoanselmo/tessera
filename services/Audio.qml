pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire

// Audio devices and per-application streams, with the default output's level
// singled out for the bar and the OSD. Also holds the volume panel's open
// state and IPC target, so they register once rather than per screen.
//
//     qs ipc call volume toggle|open|close
Singleton {
    id: root

    property bool panelOpen: false

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

    readonly property PwNode source: Pipewire.defaultAudioSource
    readonly property bool micMuted: root.source?.audio?.muted ?? false

    // Applications capturing audio right now.
    readonly property var recorders: root.nodes.filter(n => n.isStream && !n.isSink)
    readonly property bool micInUse: root.recorders.length > 0

    function toggleMicMute(): void {
        root.toggleNodeMute(root.source);
    }

    // Fired when the default input is muted or unmuted, from anywhere (the
    // mic-mute key runs wpctl), but not on startup or when the input changes.
    signal micToggled

    property var lastMic: ({
            source: null,
            muted: false
        })

    function checkMic(): void {
        if (!root.source?.ready || !root.source.audio)
            return;

        const prev = root.lastMic;
        root.lastMic = {
            source: root.source,
            muted: root.micMuted
        };

        if (prev.source === root.source && prev.muted !== root.micMuted)
            root.micToggled();
    }

    onSourceChanged: root.checkMic()
    onMicMutedChanged: root.checkMic()

    Connections {
        target: root.source

        function onReadyChanged() {
            root.checkMic();
        }
    }

    // Hardware outputs and inputs, and applications playing sound. Quickshell
    // flags an application's playback stream as a sink too (it feeds one),
    // while a recording stream is a stream that is not.
    readonly property var nodes: [...Pipewire.nodes.values].filter(n => n.audio)
    readonly property var sinks: root.nodes.filter(n => n.isSink && !n.isStream)
    readonly property var sources: root.nodes.filter(n => !n.isSink && !n.isStream)
    readonly property var streams: root.nodes.filter(n => n.isSink && n.isStream)

    // A node only publishes live volume, mute state and description while
    // something binds it.
    PwObjectTracker {
        objects: root.nodes
    }

    // Unmutes too, since asking for a level means wanting to hear it.
    function setNodeVolume(node: PwNode, fraction: real): void {
        if (!node?.audio)
            return;

        node.audio.muted = false;
        node.audio.volume = Math.max(0, Math.min(1, fraction));
    }

    function nudgeNode(node: PwNode, delta: real): void {
        if (node?.audio)
            root.setNodeVolume(node, node.audio.volume + delta);
    }

    function toggleNodeMute(node: PwNode): void {
        if (node?.audio)
            node.audio.muted = !node.audio.muted;
    }

    // The default output, which is what the bar, OSD and media keys mean.
    function setVolume(fraction: real): void {
        root.setNodeVolume(root.sink, fraction);
    }

    function nudge(delta: real): void {
        root.nudgeNode(root.sink, delta);
    }

    function toggleMute(): void {
        root.toggleNodeMute(root.sink);
    }

    // Makes `node` the default output or input, whichever it is.
    function setDefault(node: PwNode): void {
        if (node.isSink)
            Pipewire.preferredDefaultAudioSink = node;
        else
            Pipewire.preferredDefaultAudioSource = node;
    }

    IpcHandler {
        target: "volume"

        function toggle(): void {
            root.panelOpen = !root.panelOpen;
        }

        function open(): void {
            root.panelOpen = true;
        }

        function close(): void {
            root.panelOpen = false;
        }
    }
}

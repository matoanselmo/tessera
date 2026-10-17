pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Mpris

// The one media player the shell shows and controls.
Singleton {
    id: root

    // Prefer a player that is actually playing, otherwise the first one around.
    readonly property MprisPlayer player: Mpris.players.values.find(p => p.isPlaying) ?? Mpris.players.values[0] ?? null

    // True if anything at all is playing, since `player` prefers a playing one.
    readonly property bool playing: root.player?.isPlaying ?? false

    readonly property bool hasTimeline: root.player !== null && root.player.positionSupported && root.player.lengthSupported && root.player.length > 0
    readonly property real progress: root.hasTimeline ? root.player.position / root.player.length : 0

    // MPRIS does not push position updates. Views that show the position set
    // this while visible, and it is polled once a second while playing.
    property bool trackPosition: false

    Timer {
        running: root.trackPosition && root.playing
        interval: 1000
        repeat: true
        onTriggered: root.player.positionChanged()
    }
}

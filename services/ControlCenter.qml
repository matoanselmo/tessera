pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower
import qs

// State behind the control center: its open state and IPC target, keep
// awake, the power profile and screenshots. The tiles for everything else
// (network, Bluetooth, sound...) drive those services directly.
//
//     qs ipc call control toggle|open|close
//     qs ipc call control screenshot
Singleton {
    id: root

    property bool panelOpen: false

    // Holds off swayidle's lock and blank, through an idle inhibitor on the
    // bar (see Bar.qml), until turned off again.
    property bool keepAwake: false

    // A laptop gets the power profile tile; a desktop gets keep awake there.
    readonly property bool laptop: UPower.displayDevice.ready && UPower.displayDevice.isLaptopBattery

    readonly property string profileName: {
        switch (PowerProfiles.profile) {
        case PowerProfile.PowerSaver:
            return "Power saver";
        case PowerProfile.Performance:
            return "Performance";
        default:
            return "Balanced";
        }
    }

    // Power saver -> balanced -> performance (when the machine has one) -> back.
    function cycleProfile(): void {
        const order = [PowerProfile.PowerSaver, PowerProfile.Balanced];
        if (PowerProfiles.hasPerformanceProfile)
            order.push(PowerProfile.Performance);
        const i = order.indexOf(PowerProfiles.profile);
        PowerProfiles.profile = order[(i + 1) % order.length];
    }

    // niri's own screenshot UI: pick a region, a window or the screen, and
    // niri copies it and saves it to `screenshot-path` from its config. The
    // panel closes first and the UI waits for its fade, so it is never in
    // the picture.
    function screenshot(): void {
        root.panelOpen = false;
        shotDelay.restart();
    }

    Timer {
        id: shotDelay
        interval: ShellGlobals.animNormal * ShellGlobals.motionScale + 150
        onTriggered: Quickshell.execDetached(["niri", "msg", "action", "screenshot"])
    }

    IpcHandler {
        target: "control"

        function toggle(): void {
            root.panelOpen = !root.panelOpen;
        }

        function open(): void {
            root.panelOpen = true;
        }

        function close(): void {
            root.panelOpen = false;
        }

        function screenshot(): void {
            root.screenshot();
        }
    }
}

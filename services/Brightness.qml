pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// The screen backlight, on machines that have one (laptops); `available` is
// false everywhere else, and everything brightness-related hides itself.
// Writes go through logind (`busctl ... SetBrightness`), which lets the
// active session change it without root or a udev rule. The panel's open
// state and IPC target live here so they register once.
//
//     qs ipc call brightness up|down|set <percent>|toggle|open|close
//
// Bind the laptop's brightness keys to `up` and `down` in niri, so the OSD
// shows for them too.
Singleton {
    id: root

    property bool panelOpen: false

    // The backlight's name under /sys/class/backlight, e.g. intel_backlight.
    property string device: ""
    readonly property bool available: root.device !== "" && root.max > 0

    property int raw: 0
    property int max: 0
    readonly property real level: root.max > 0 ? root.raw / root.max : 0
    readonly property int percent: Math.round(root.level * 100)

    // Fired when the level changes, whoever changed it, for the OSD.
    signal adjusted

    readonly property real step: 0.05
    // Never all the way down: a black screen is hard to turn back up.
    readonly property real floor: 0.01

    function set(level: real): void {
        if (!root.available)
            return;
        const value = Math.round(Math.max(root.floor, Math.min(1, level)) * root.max);
        // Shown straight away; the next read confirms it.
        root.raw = value;
        Quickshell.execDetached(["busctl", "call", "org.freedesktop.login1", "/org/freedesktop/login1/session/auto", "org.freedesktop.login1.Session", "SetBrightness", "ssu", "backlight", root.device, String(value)]);
        root.adjusted();
    }

    function nudge(delta: real): void {
        root.set(root.level + delta);
    }

    // Prefers the GPU's own backlight over the firmware's generic one, the
    // same pick brightnessctl makes.
    Process {
        running: true
        command: ["sh", "-c", "ls /sys/class/backlight 2>/dev/null"]

        stdout: StdioCollector {
            onStreamFinished: {
                const names = text.split("\n").filter(n => n !== "");
                root.device = names.find(n => !n.startsWith("acpi_video")) ?? names[0] ?? "";
            }
        }
    }

    FileView {
        id: maxFile
        path: root.device !== "" ? `/sys/class/backlight/${root.device}/max_brightness` : ""
        onLoaded: root.max = parseInt(maxFile.text()) || 0
    }

    // sysfs does not report brightness changes, so it is read on a short
    // timer; changes from anywhere else (the firmware, another tool) still
    // show up, and bring the OSD with them.
    FileView {
        id: levelFile
        path: root.device !== "" ? `/sys/class/backlight/${root.device}/actual_brightness` : ""

        onLoaded: {
            const value = parseInt(levelFile.text()) || 0;
            if (value === root.raw)
                return;
            const first = root.raw === 0;
            root.raw = value;
            if (!first)
                root.adjusted();
        }
    }

    Timer {
        running: root.available
        interval: 500
        repeat: true
        onTriggered: levelFile.reload()
    }

    IpcHandler {
        target: "brightness"

        function up(): void {
            root.nudge(root.step);
        }

        function down(): void {
            root.nudge(-root.step);
        }

        function set(percent: int): void {
            root.set(percent / 100);
        }

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

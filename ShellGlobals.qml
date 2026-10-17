pragma Singleton

import Quickshell
import QtQuick

Singleton {
    // Font Config
    // "Google Sans" was configured but is not installed on this system, so every
    // label silently fell back to the default sans. Adwaita Sans is the Fedora
    // default UI face and is present; fontconfig handles glyph fallback.
    readonly property string fontFamily: "Adwaita Sans"
    readonly property double letterSpacing: 0
    readonly property int fontSize: 11
    // For the terminal-styled panels (network, bluetooth), after bluetui.
    readonly property string monoFamily: "JetBrains Mono"

    // Shape
    readonly property int radius: 0

    // Launcher web search. `%s` is replaced with the percent-encoded query;
    // swap in e.g. "https://duckduckgo.com/?q=%s" / "DuckDuckGo" to change it.
    readonly property string searchEngineUrl: "https://www.google.com/search?q=%s"
    readonly property string searchEngineName: "Google"

    // Extra clocks shown beside local time in the clock menu, left to right.
    // Offsets are fixed minutes from UTC, so only zones without daylight
    // saving stay exact: Brasília has been UTC-3 year-round since 2019.
    readonly property var worldClocks: [
        {
            name: "Brasília",
            offsetMinutes: -180
        }
    ]

    // Lock screen authentication: the PAM service and the directory it lives
    // in. openSUSE ships swaylock's (`auth include login`) in its vendor
    // directory rather than /etc/pam.d.
    readonly property string lockPamConfig: "swaylock"
    readonly property string lockPamDir: "/usr/lib/pam.d"

    // Folders under ~ the launcher's file search (`/`) leaves out, besides
    // hidden and git-ignored ones and node_modules. ~/config is what ~/.config
    // points to here, so it is hidden in all but name, and full of app data.
    readonly property var fileSearchSkip: ["~/config"]

    // Bar metrics
    readonly property int barThickness: 28
    readonly property int barGap: 4
    readonly property int iconSize: 18

    // Popups and overlays
    readonly property int popupPadding: 12
    readonly property int popupSpacing: 10

    // Motion. Durations in ms: `fast` for hover and colour changes, `normal`
    // for things opening, moving or resizing, `slow` for longer travel such
    // as toasts sliding in. Every animation is scaled by `motionScale`, so the
    // whole shell's pace is one number: 1.25 is calmer, 0 turns motion off.
    readonly property real motionScale: 1
    readonly property int animFast: 150
    readonly property int animNormal: 250
    readonly property int animSlow: 400

    // Cubic bezier curves for Easing.BezierSpline (control points, then the
    // end point). `easeOut` decelerates hard into place, for anything
    // arriving or moving; `easeIn` accelerates away, for anything leaving;
    // `easeInOut` is for colour and state changes in place.
    readonly property var easeOut: [0.2, 0, 0, 1, 1, 1]
    readonly property var easeIn: [0.3, 0, 1, 1, 1, 1]
    readonly property var easeInOut: [0.4, 0, 0.2, 1, 1, 1]

    // One Dark material-style roles.
    //
    // Greys run #181a1f -> #21252b -> #2c313c -> #3e4451 -> #4b5263, text is
    // #abb2bf with #d7dae0 for emphasis, and #61afef carries every active or
    // selected state. Ratios were matched against the palette this replaced:
    // body text lands between 4.8:1 and 9.3:1, and each surface sits roughly the
    // same distance from the one behind it.
    readonly property var materialColors: QtObject {
        readonly property color primary: "#2c313c"
        readonly property color onprimary: "#abb2bf"
        readonly property color primarycontainer: "#3e4451"
        readonly property color onprimarycontainer: "#d7dae0"
        readonly property color inverseprimary: "#61afef"
        readonly property color secondary: "#61afef"
        readonly property color onsecondary: "#181a1f"
        readonly property color secondarycontainer: "#21252b"
        readonly property color onsecondarycontainer: "#abb2bf"
        readonly property color tertiary: "#4b5263"
        readonly property color ontertiary: "#d7dae0"
        readonly property color tertiarycontainer: "#2c313c"
        readonly property color ontertiarycontainer: "#abb2bf"
        readonly property color background: "#181a1f"
        readonly property color onbackground: "#abb2bf"
        readonly property color surface: "#282c34"
        readonly property color onsurface: "#abb2bf"
        readonly property color surfacevariant: "#2c313c"
        readonly property color onsurfacevariant: "#abb2bf"
        readonly property color surfacetint: "#61afef"
        readonly property color inversesurface: "#abb2bf"
        readonly property color inverseonsurface: "#282c34"
        readonly property color error: "#e06c75"
        readonly property color onerror: "#181a1f"
        readonly property color errorcontainer: "#be5046"
        readonly property color onerrorcontainer: "#ffffff"
        readonly property color outline: "transparent"
        readonly property color outlinevariant: "transparent"
        readonly property color scrim: "#181a1f"
        readonly property color surfacebright: "#4b5263"
        readonly property color surfacecontainer: "#21252b"
        readonly property color surfacecontainerhigh: "#2c313c"
        readonly property color surfacecontainerhighest: "#3e4451"
        readonly property color surfacecontainerlow: "#1e2127"
        readonly property color surfacecontainerlowest: "#181a1f"
        readonly property color surfacedim: "#181a1f"
    }
}

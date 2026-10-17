pragma Singleton

import Quickshell
import QtQuick

Singleton {
    property bool isDnd: false

    // Font Config
    // "Google Sans" was configured but is not installed on this system, so every
    // label silently fell back to the default sans. Adwaita Sans is the Fedora
    // default UI face and is present; fontconfig handles glyph fallback.
    readonly property string fontFamily: "Adwaita Sans"
    readonly property double letterSpacing: 0
    readonly property int fontSize: 11

    // Shape
    readonly property int radius: 0

    // Launcher web search. `%s` is replaced with the percent-encoded query;
    // swap in e.g. "https://duckduckgo.com/?q=%s" / "DuckDuckGo" to change it.
    readonly property string searchEngineUrl: "https://www.google.com/search?q=%s"
    readonly property string searchEngineName: "Google"

    // Bar metrics
    readonly property int barThickness: 28
    readonly property int barGap: 4
    readonly property int iconSize: 18

    // Popups and overlays
    readonly property int popupPadding: 12
    readonly property int popupSpacing: 10

    // Animation durations, in ms. `fast` for hover and state colour changes,
    // `fade` for popups opening and closing, `slow` for notifications.
    readonly property int animFast: 140
    readonly property int animFade: 160
    readonly property int animSlow: 320

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

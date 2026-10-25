import QtQuick
import QtQuick.Layouts
import qs
import qs.components

// Shared skeleton for every bar module: a tinted icon next to optional bold
// text, on a rounded-by-token background. Horizontal, to match the top bar.
Rectangle {
    id: root

    // File name inside bar/icons. ".png" is assumed when no extension is given,
    // so SVG icons can be named explicitly.
    property string icon: ""
    // Optional second icon drawn before the main one, same naming rules.
    property string badge: ""
    property string label: ""
    property color foreground: ShellGlobals.materialColors.onprimary
    property bool interactive: false
    // Shown after the pointer rests on the widget; works without `interactive`.
    property string tooltip: ""
    property bool tooltipMono: false

    // Pixel ceiling for the whole widget. 0 lets it size to its content, which
    // is what every fixed-width module wants; anything longer elides its label.
    property int maximumWidth: 0

    readonly property alias hovered: mouse.containsMouse

    signal clicked
    signal rightClicked
    signal scrolled(int delta)

    // Resolved here, in bar/, so callers anywhere can name icons by file name.
    function iconUrl(name: string): url {
        return name === "" ? "" : Qt.resolvedUrl(`icons/${name}${name.includes(".") ? "" : ".png"}`);
    }

    color: ShellGlobals.materialColors.primary
    radius: ShellGlobals.radius

    implicitWidth: root.maximumWidth > 0 ? Math.min(row.implicitWidth + 16, root.maximumWidth) : row.implicitWidth + 16
    implicitHeight: ShellGlobals.barThickness

    // A label changing length glides the widget (and its neighbours) to the
    // new width instead of shifting the bar in one frame.
    Behavior on implicitWidth {
        Anim {}
    }

    Behavior on color {
        CAnim {}
    }

    // A small squeeze while pressed, springing back with a hint of overshoot.
    scale: mouse.pressed && root.interactive ? 0.95 : 1

    Behavior on scale {
        Anim {
            time: ShellGlobals.animFast
            easing.type: Easing.OutBack
            easing.overshoot: 1.2
        }
    }

    Layout.preferredHeight: ShellGlobals.barThickness
    Layout.alignment: Qt.AlignVCenter

    RowLayout {
        id: row

        // With a label the row spans the widget so the text can elide; without
        // one it keeps its natural width and sits centred, so a widget given
        // more room than its icons need does not pack them to the left.
        // Switching anchors on the label instead tripped Qt's "left, right and
        // horizontalCenter at once" warning while the bindings settled.
        anchors.centerIn: parent
        width: root.label !== "" ? parent.width - 16 : implicitWidth

        spacing: (root.label !== "" && root.icon !== "") || root.badge !== "" ? 6 : 0

        TintedIcon {
            visible: root.badge !== ""
            source: root.iconUrl(root.badge)
            color: root.foreground
            Layout.alignment: Qt.AlignVCenter
        }

        TintedIcon {
            visible: root.icon !== ""
            source: root.iconUrl(root.icon)
            color: root.foreground
            Layout.alignment: Qt.AlignVCenter
        }

        StyledText {
            id: labelText
            visible: root.label !== ""
            text: root.label
            elide: Text.ElideRight
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            font.pixelSize: ShellGlobals.fontSize + 2
            font.bold: true
            color: root.foreground
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        enabled: root.interactive || root.tooltip !== ""
        hoverEnabled: true
        cursorShape: root.interactive ? Qt.PointingHandCursor : Qt.ArrowCursor
        // A tooltip-only widget watches hover but lets clicks through.
        acceptedButtons: root.interactive ? Qt.LeftButton | Qt.RightButton : Qt.NoButton
        onClicked: event => event.button === Qt.RightButton ? root.rightClicked() : root.clicked()
        onWheel: event => root.scrolled(event.angleDelta.y)
    }

    // Fades the label in, for when it now means something else entirely (a
    // different window) rather than just ticking over.
    function refreshLabel(): void {
        labelFade.restart();
    }

    Anim {
        id: labelFade
        target: labelText
        property: "opacity"
        from: 0
        to: 1
        time: ShellGlobals.animNormal
    }

    Tooltip {
        target: root
        text: root.tooltip
        mono: root.tooltipMono
        hovered: mouse.containsMouse
    }
}

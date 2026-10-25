import QtQuick
import QtQuick.Layouts
import qs
import qs.components
import qs.services

// The control center's button: network, sound and brightness folded into
// one widget, the way Windows groups its quick settings. Bluetooth joins
// only while a device is connected, and brightness only where there is a
// backlight; either slides in and out rather than popping. Click opens the
// control center, scrolling changes the volume, and the tooltip spells out
// what the icons mean.
Rectangle {
    id: root

    // Lit while the control center is open.
    property bool active: false
    readonly property bool present: true

    signal clicked

    readonly property color foreground: root.active ? ShellGlobals.materialColors.onsecondary : ShellGlobals.materialColors.onprimary

    readonly property var connected: BluetoothState.connected

    color: root.active ? ShellGlobals.materialColors.secondary : mouse.containsMouse ? ShellGlobals.materialColors.primarycontainer : ShellGlobals.materialColors.primary
    radius: ShellGlobals.radius

    implicitWidth: row.implicitWidth + 20
    implicitHeight: ShellGlobals.barThickness
    Layout.preferredHeight: ShellGlobals.barThickness
    Layout.alignment: Qt.AlignVCenter

    Behavior on color {
        CAnim {}
    }

    // The same squeeze as every other bar widget.
    scale: mouse.pressed ? 0.95 : 1

    Behavior on scale {
        Anim {
            time: ShellGlobals.animFast
            easing.type: Easing.OutBack
            easing.overshoot: 1.2
        }
    }

    // One icon, with the gap before it, that grows out of nothing when it
    // starts to apply and shrinks away when it stops.
    component Slot: Item {
        id: slot

        property url source
        property bool shown: true
        property bool first: false

        property real reveal: slot.shown ? 1 : 0

        Behavior on reveal {
            Anim {}
        }

        implicitWidth: (ShellGlobals.iconSize + (slot.first ? 0 : 10)) * slot.reveal
        implicitHeight: ShellGlobals.iconSize
        opacity: slot.reveal
        visible: slot.reveal > 0
        clip: slot.reveal < 1

        TintedIcon {
            anchors.right: parent.right
            source: slot.source
            color: root.foreground

            Behavior on color {
                CAnim {}
            }
        }
    }

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: 0

        Slot {
            first: true
            source: Qt.resolvedUrl(`icons/${Internet.icon}`)
        }

        Slot {
            shown: root.connected.length > 0
            source: Qt.resolvedUrl("icons/bluetooth.svg")
        }

        Slot {
            source: Qt.resolvedUrl(`icons/${Audio.icon}`)
        }

        Slot {
            shown: Brightness.available
            source: Qt.resolvedUrl("icons/brightness.svg")
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
        onWheel: event => Audio.nudge(event.angleDelta.y > 0 ? 0.05 : -0.05)
    }

    Tooltip {
        target: root
        hovered: mouse.containsMouse && !root.active
        text: {
            const parts = [Internet.summary];
            if (root.connected.length > 0)
                parts.push(root.connected.map(d => d.name).join(", "));
            parts.push(Audio.muted ? "Muted" : `Volume ${Audio.percent}%`);
            if (Brightness.available)
                parts.push(`Brightness ${Brightness.percent}%`);
            return parts.join(" · ");
        }
    }
}

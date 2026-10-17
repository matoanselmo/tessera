import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import qs

// Shared skeleton for every bar module: a tinted icon next to optional bold
// text, on a rounded-by-token background. Horizontal, to match the top bar.
Rectangle {
    id: root

    // File name inside bar/icons. ".png" is assumed when no extension is given,
    // so SVG icons can be named explicitly.
    property string icon: ""
    readonly property string iconSource: root.icon === "" ? "" : `icons/${root.icon}${root.icon.includes(".") ? "" : ".png"}`
    // Optional second icon drawn before the main one, same naming rules.
    property string badge: ""
    readonly property string badgeSource: root.badge === "" ? "" : `icons/${root.badge}${root.badge.includes(".") ? "" : ".png"}`
    property string label: ""
    property color foreground: ShellGlobals.materialColors.onprimary
    property int iconRotation: 0
    property bool interactive: false

    // Pixel ceiling for the whole widget. 0 lets it size to its content, which
    // is what every fixed-width module wants; anything longer elides its label.
    property int maximumWidth: 0

    readonly property alias hovered: mouse.containsMouse

    signal clicked
    signal rightClicked
    signal scrolled(int delta)

    color: ShellGlobals.materialColors.primary
    radius: ShellGlobals.radius

    implicitWidth: root.maximumWidth > 0 ? Math.min(row.implicitWidth + 16, root.maximumWidth) : row.implicitWidth + 16
    implicitHeight: ShellGlobals.barThickness

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

        Item {
            visible: root.badge !== ""
            Layout.preferredWidth: ShellGlobals.iconSize
            Layout.preferredHeight: ShellGlobals.iconSize
            Layout.alignment: Qt.AlignVCenter

            Image {
                id: badgeImage
                anchors.fill: parent
                source: root.badgeSource
                smooth: true
                mipmap: true
                visible: false
            }

            ColorOverlay {
                anchors.fill: parent
                source: badgeImage
                color: root.foreground
            }
        }

        Item {
            visible: root.icon !== ""
            Layout.preferredWidth: ShellGlobals.iconSize
            Layout.preferredHeight: ShellGlobals.iconSize
            Layout.alignment: Qt.AlignVCenter
            rotation: root.iconRotation

            Image {
                id: iconImage
                anchors.fill: parent
                source: root.iconSource
                smooth: true
                mipmap: true
                visible: false
            }

            ColorOverlay {
                anchors.fill: parent
                source: iconImage
                color: root.foreground
            }
        }

        Text {
            visible: root.label !== ""
            text: root.label
            elide: Text.ElideRight
            Layout.fillWidth: true
            font.family: ShellGlobals.fontFamily
            font.pixelSize: ShellGlobals.fontSize + 2
            font.bold: true
            font.letterSpacing: ShellGlobals.letterSpacing
            color: root.foreground
            Layout.alignment: Qt.AlignVCenter
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        enabled: root.interactive
        hoverEnabled: root.interactive
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: event => event.button === Qt.RightButton ? root.rightClicked() : root.clicked()
        onWheel: event => root.scrolled(event.angleDelta.y)
    }
}

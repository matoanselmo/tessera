import QtQuick
import QtQuick.Layouts
import qs

// A bordered box with its title set into the top border, the way bluetui and
// impala draw their panes. The border and title light up when `focused`.
Item {
    id: pane

    property string title: ""
    property bool focused: false

    default property alias content: inner.data

    signal clicked

    readonly property color accent: pane.focused ? ShellGlobals.materialColors.secondary : Qt.alpha(ShellGlobals.materialColors.ontertiarycontainer, 0.35)

    Layout.fillWidth: true
    implicitWidth: inner.implicitWidth + 20
    implicitHeight: inner.implicitHeight + title.implicitHeight / 2 + 16

    // Clicking anywhere in the pane focuses it; rows inside take their own clicks.
    MouseArea {
        anchors.fill: parent
        onClicked: pane.clicked()
    }

    Rectangle {
        id: frame
        anchors.fill: parent
        anchors.topMargin: title.implicitHeight / 2
        color: "transparent"
        border.width: 1
        border.color: pane.accent
        radius: ShellGlobals.radius
    }

    // Masks the border behind the title.
    Rectangle {
        x: 10
        width: title.implicitWidth + 8
        height: title.implicitHeight
        color: ShellGlobals.materialColors.tertiarycontainer

        StyledText {
            id: title
            anchors.centerIn: parent
            text: pane.title
            font.family: ShellGlobals.monoFamily
            font.bold: true
            color: pane.focused ? ShellGlobals.materialColors.secondary : ShellGlobals.materialColors.ontertiarycontainer
        }
    }

    ColumnLayout {
        id: inner
        anchors {
            left: frame.left
            right: frame.right
            top: frame.top
            leftMargin: 10
            rightMargin: 10
            topMargin: title.implicitHeight / 2 + 4
        }
        spacing: 0
    }
}

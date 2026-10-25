import QtQuick
import QtQuick.Layouts
import qs
import qs.components
import qs.services

// A slider for the backlight, under its bar widget. h/l or the arrows step
// it by 5%, a digit jumps straight to that tenth (0 is 100%), and the slider
// takes clicks, drags and the wheel.
BarPanel {
    id: panel

    implicitWidth: 300
    contentHeight: column.implicitHeight + ShellGlobals.popupPadding * 2

    readonly property bool shouldShow: Brightness.panelOpen

    onShouldShowChanged: panel.shouldShow ? panel.open() : panel.close()
    onHidden: Brightness.panelOpen = false

    readonly property var hints: [
        {
            key: "h/l",
            label: "−/+ 5%",
            action: () => Brightness.nudge(Brightness.step)
        },
        {
            key: "1-0",
            label: "jump",
            action: null
        },
        {
            key: "esc",
            label: "close",
            action: panel.close
        }
    ]

    Item {
        anchors.fill: parent
        focus: true

        Keys.onPressed: event => {
            if (event.key === Qt.Key_L || event.key === Qt.Key_Right || event.key === Qt.Key_K || event.key === Qt.Key_Up) {
                Brightness.nudge(Brightness.step);
            } else if (event.key === Qt.Key_H || event.key === Qt.Key_Left || event.key === Qt.Key_J || event.key === Qt.Key_Down) {
                Brightness.nudge(-Brightness.step);
            } else if (event.key >= Qt.Key_0 && event.key <= Qt.Key_9) {
                const n = event.key - Qt.Key_0;
                Brightness.set(n === 0 ? 1 : n / 10);
            } else {
                return;
            }
            event.accepted = true;
        }
    }

    ColumnLayout {
        id: column
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            margins: ShellGlobals.popupPadding
        }
        spacing: 10

        RowLayout {
            Layout.fillWidth: true

            StyledText {
                text: "Brightness"
                font.bold: true
                font.pixelSize: 13
            }

            Item {
                Layout.fillWidth: true
            }

            StyledText {
                text: Brightness.device
                font.family: ShellGlobals.monoFamily
                font.pixelSize: 10
                opacity: 0.5
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            TintedIcon {
                source: Qt.resolvedUrl("icons/brightness.svg")
                color: ShellGlobals.materialColors.ontertiarycontainer
            }

            Track {
                Layout.fillWidth: true
                thickness: 6
                interactive: true
                value: Brightness.level
                onMoved: value => Brightness.set(value)
            }

            StyledText {
                Layout.preferredWidth: 36
                horizontalAlignment: Text.AlignRight
                text: `${Brightness.percent}%`
                font.bold: true
            }
        }

        TuiFooter {
            hints: panel.hints
        }
    }
}

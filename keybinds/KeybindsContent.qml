import QtQuick
import QtQuick.Layouts
import Quickshell
import qs

import "parse.js" as Parse

Item {
    id: root

    required property var binds

    signal closeRequested

    readonly property real maxListHeight: 520

    // The window keeps the tallest size so the panel can shrink and grow inside
    // it while filtering, the same way the launcher does.
    width: 680
    height: 16 * 2 + header.implicitHeight + searchContainer.Layout.topMargin + searchContainer.implicitHeight + list.topMargin + list.bottomMargin + root.maxListHeight

    function scrollBy(dy: real): void {
        const top = list.originY - list.topMargin;
        const bottom = Math.max(top, list.originY + list.contentHeight + list.bottomMargin - list.height);
        list.contentY = Math.max(top, Math.min(bottom, list.contentY + dy));
    }

    Rectangle {
        id: panel
        width: parent.width
        height: 16 * 2 + header.implicitHeight + searchContainer.Layout.topMargin + searchContainer.implicitHeight + list.topMargin + list.bottomMargin + Math.min(Math.max(list.contentHeight, 40), root.maxListHeight)
        Behavior on height {
            NumberAnimation {
                duration: 200
                easing.type: Easing.OutCubic
            }
        }
        color: ShellGlobals.materialColors.tertiarycontainer
        radius: ShellGlobals.radius
        clip: true

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 0

            RowLayout {
                id: header
                Layout.fillWidth: true

                Text {
                    text: "Keybinds"
                    font.bold: true
                    font.pixelSize: 15
                    font.family: ShellGlobals.fontFamily
                    font.letterSpacing: ShellGlobals.letterSpacing
                    color: ShellGlobals.materialColors.ontertiarycontainer
                }

                Item {
                    Layout.fillWidth: true
                }

                Text {
                    text: `${root.binds.length} binds`
                    font.pixelSize: 12
                    font.family: ShellGlobals.fontFamily
                    color: ShellGlobals.materialColors.ontertiarycontainer
                    opacity: 0.6
                }
            }

            Rectangle {
                id: searchContainer
                Layout.fillWidth: true
                Layout.topMargin: 10
                implicitHeight: search.implicitHeight + 20
                color: ShellGlobals.materialColors.secondarycontainer
                radius: ShellGlobals.radius

                TextInput {
                    id: search
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.leftMargin: 15
                    anchors.rightMargin: 15
                    color: ShellGlobals.materialColors.onsecondarycontainer

                    font.family: ShellGlobals.fontFamily
                    font.pixelSize: 16
                    font.bold: true
                    font.letterSpacing: ShellGlobals.letterSpacing

                    focus: true
                    Keys.onEscapePressed: root.closeRequested()
                    Keys.onUpPressed: root.scrollBy(-list.rowHeight)
                    Keys.onDownPressed: root.scrollBy(list.rowHeight)

                    Keys.onPressed: event => {
                        if (event.key == Qt.Key_PageUp) {
                            root.scrollBy(-list.height);
                            event.accepted = true;
                        } else if (event.key == Qt.Key_PageDown) {
                            root.scrollBy(list.height);
                            event.accepted = true;
                        }
                    }

                    onTextChanged: list.positionViewAtBeginning()

                    Text {
                        anchors.fill: parent
                        visible: search.text === ""
                        text: "Search keybinds"
                        color: ShellGlobals.materialColors.onsecondarycontainer
                        opacity: 0.5
                        font: search.font
                    }
                }
            }

            ListView {
                id: list
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                topMargin: 7
                bottomMargin: 0

                readonly property real rowHeight: 34

                model: ScriptModel {
                    values: Parse.filterRows(root.binds, search.text)
                }

                Text {
                    anchors.centerIn: parent
                    visible: list.count === 0
                    text: root.binds.length === 0 ? "No binds found in the niri config" : "No matching binds"
                    color: ShellGlobals.materialColors.ontertiarycontainer
                    opacity: 0.6
                    font.pixelSize: 13
                    font.family: ShellGlobals.fontFamily
                }

                delegate: Item {
                    id: row
                    required property var modelData

                    width: ListView.view.width
                    height: row.modelData.header ? 30 : list.rowHeight

                    Text {
                        visible: row.modelData.header
                        anchors.left: parent.left
                        anchors.leftMargin: 12
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 6
                        text: row.modelData.text
                        color: ShellGlobals.materialColors.secondary
                        font.pixelSize: 12
                        font.bold: true
                        font.family: ShellGlobals.fontFamily
                        font.letterSpacing: ShellGlobals.letterSpacing
                    }

                    Rectangle {
                        visible: !row.modelData.header
                        anchors.fill: parent
                        color: hover.hovered ? ShellGlobals.materialColors.tertiary : "transparent"
                        radius: ShellGlobals.radius

                        HoverHandler {
                            id: hover
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 8
                            spacing: 12

                            Text {
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignVCenter
                                text: row.modelData.text
                                elide: Text.ElideRight
                                color: ShellGlobals.materialColors.ontertiarycontainer
                                font.pixelSize: 14
                                font.bold: true
                                font.family: ShellGlobals.fontFamily
                                font.letterSpacing: ShellGlobals.letterSpacing
                            }

                            Row {
                                Layout.alignment: Qt.AlignVCenter
                                spacing: 4

                                Repeater {
                                    model: row.modelData.keys

                                    delegate: Rectangle {
                                        id: chip
                                        required property string modelData

                                        implicitWidth: Math.max(24, chipLabel.implicitWidth + 14)
                                        implicitHeight: 22
                                        color: ShellGlobals.materialColors.secondarycontainer
                                        radius: ShellGlobals.radius

                                        Text {
                                            id: chipLabel
                                            anchors.centerIn: parent
                                            text: chip.modelData
                                            color: ShellGlobals.materialColors.onsecondarycontainer
                                            font.pixelSize: 12
                                            font.bold: true
                                            font.family: ShellGlobals.fontFamily
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

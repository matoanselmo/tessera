import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs
import qs.components

// A tray app's menu, drawn like the shell's other menus rather than as a
// native Qt menu (which would also need QApplication mode). Submenus open in
// place, with a back row on top.
BarPopup {
    id: menu

    required property PanelWindow bar

    property Item anchorItem: null
    property var rootMenu: null

    // Submenu entries drilled into, innermost last.
    property var path: []
    readonly property var current: menu.path.length > 0 ? menu.path[menu.path.length - 1] : menu.rootMenu

    anchor.item: menu.anchorItem
    anchor.edges: Edges.Bottom
    anchor.gravity: Edges.Bottom
    anchor.margins.top: ShellGlobals.barGap

    implicitWidth: Math.max(180, Math.min(320, column.implicitWidth + ShellGlobals.barGap * 2))
    contentHeight: column.implicitHeight + ShellGlobals.barGap * 2

    // Opens `handle` (a SystemTrayItem's menu) under `item`.
    function show(item: Item, handle: var): void {
        menu.anchorItem = item;
        menu.rootMenu = handle;
        menu.path = [];
        menu.open();
    }

    onHidden: menu.path = []

    // The app quit (or dropped its icon) with the menu open.
    onAnchorItemChanged: {
        if (!menu.anchorItem)
            menu.close();
    }

    QsMenuOpener {
        id: opener
        menu: menu.current
    }

    ColumnLayout {
        id: column
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            margins: ShellGlobals.barGap
        }
        spacing: 0

        MenuRow {
            visible: menu.path.length > 0
            icon: Qt.resolvedUrl("icons/chevron-left.svg")
            text: "Back"
            onActivated: menu.path = menu.path.slice(0, -1)
        }

        Divider {
            visible: menu.path.length > 0
        }

        Repeater {
            model: opener.children

            delegate: Loader {
                id: slot
                required property QsMenuEntry modelData

                Layout.fillWidth: true
                sourceComponent: slot.modelData.isSeparator ? separator : entry

                Component {
                    id: separator

                    Item {
                        implicitHeight: 9

                        Rectangle {
                            anchors.centerIn: parent
                            width: parent.width
                            height: 1
                            color: ShellGlobals.materialColors.ontertiarycontainer
                            opacity: 0.15
                        }
                    }
                }

                Component {
                    id: entry

                    MenuRow {
                        text: slot.modelData.text
                        icon: slot.modelData.icon
                        enabled: slot.modelData.enabled
                        submenu: slot.modelData.hasChildren
                        mark: {
                            if (slot.modelData.buttonType === QsMenuButtonType.CheckBox)
                                return slot.modelData.checkState === Qt.Checked ? "✓" : " ";
                            if (slot.modelData.buttonType === QsMenuButtonType.RadioButton)
                                return slot.modelData.checkState === Qt.Checked ? "●" : " ";
                            return "";
                        }

                        onActivated: {
                            if (slot.modelData.hasChildren) {
                                menu.path = [...menu.path, slot.modelData];
                            } else {
                                slot.modelData.triggered();
                                menu.close();
                            }
                        }
                    }
                }
            }
        }
    }

    // One clickable line: optional check mark, icon, label, submenu arrow.
    component MenuRow: Rectangle {
        id: row

        property string text: ""
        property string icon: ""
        property string mark: ""
        property bool submenu: false

        signal activated

        implicitWidth: content.implicitWidth + 20
        implicitHeight: 30
        Layout.fillWidth: true
        radius: ShellGlobals.radius
        color: hover.containsMouse && row.enabled ? ShellGlobals.materialColors.tertiary : "transparent"
        opacity: row.enabled ? 1 : 0.45

        RowLayout {
            id: content
            anchors {
                left: parent.left
                right: parent.right
                verticalCenter: parent.verticalCenter
                leftMargin: 10
                rightMargin: 10
            }
            spacing: 8

            StyledText {
                visible: row.mark !== ""
                Layout.preferredWidth: 12
                text: row.mark
                font.bold: true
            }

            IconImage {
                visible: row.icon !== ""
                implicitSize: 16
                source: row.icon
            }

            StyledText {
                Layout.fillWidth: true
                text: row.text.replace(/_(?!_)/g, "")
                elide: Text.ElideRight
                font.pixelSize: 13
            }

            TintedIcon {
                visible: row.submenu
                size: 14
                source: Qt.resolvedUrl("icons/chevron-right.svg")
            }
        }

        MouseArea {
            id: hover
            anchors.fill: parent
            hoverEnabled: true
            enabled: row.enabled
            onClicked: row.activated()
        }
    }
}

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import qs
import qs.components

// Status icons published by apps (StatusNotifierItem). Left click activates
// the app, or opens its menu if a menu is all it has; right click opens the
// menu; middle click is the app's secondary action; scrolling is passed on.
Rectangle {
    id: root

    // Where an item's menu is drawn; one per bar, shared by every item.
    required property TrayMenu menu

    color: ShellGlobals.materialColors.primary
    radius: ShellGlobals.radius

    implicitWidth: row.implicitWidth + 12
    implicitHeight: ShellGlobals.barThickness

    Layout.preferredHeight: ShellGlobals.barThickness
    Layout.alignment: Qt.AlignVCenter

    visible: repeater.count > 0



    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: 4

        Repeater {
            id: repeater
            model: SystemTray.items

            delegate: Item {
                id: entry
                required property SystemTrayItem modelData

                implicitWidth: ShellGlobals.iconSize + 4
                implicitHeight: ShellGlobals.barThickness

                // Some apps (Electron, Spotify) send "name?path=/dir" for an
                // icon outside the theme; turn that into a file URL.
                readonly property string iconSource: {
                    const icon = entry.modelData.icon;
                    if (!icon.includes("?path=")) {
                        return icon;
                    }

                    const [name, path] = icon.split("?path=");
                    return `file://${path}/${name.slice(name.lastIndexOf("/") + 1)}`;
                }

                function openMenu(): void {
                    root.menu.show(entry, entry.modelData.menu);
                }

                IconImage {
                    anchors.centerIn: parent
                    implicitSize: ShellGlobals.iconSize
                    source: entry.iconSource
                    opacity: mouse.containsMouse ? 0.75 : 1

                    Behavior on opacity {
                        Anim {
                            time: ShellGlobals.animFast
                        }
                    }
                }

                MouseArea {
                    id: mouse
                    cursorShape: Qt.PointingHandCursor
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton

                    onClicked: event => {
                        if (event.button === Qt.MiddleButton)
                            entry.modelData.secondaryActivate();
                        else if (event.button === Qt.LeftButton && !entry.modelData.onlyMenu)
                            entry.modelData.activate();
                        else if (entry.modelData.hasMenu)
                            entry.openMenu();
                    }

                    onWheel: event => entry.modelData.scroll(event.angleDelta.y, false)
                }

                Tooltip {
                    target: entry
                    text: entry.modelData.tooltipTitle || entry.modelData.title || entry.modelData.id
                    hovered: mouse.containsMouse
                }
            }
        }
    }
}

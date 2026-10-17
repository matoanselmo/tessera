import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Notifications
import qs
import qs.components

Item {
    id: root

    required property var notif

    property string body: notif?.body ?? ""
    property string appName: notif?.appName ?? ""
    property string summary: notif?.summary ?? ""
    property string image: notif?.image ?? ""
    property string appIcon: notif?.appIcon ?? ""
    property list<NotificationAction> actions: notif?.actions ?? []

    // Quickshell's icon provider answers `image://icon/<name>` with a magenta
    // placeholder texture instead of failing, so Image.status is Ready even for a
    // name the active theme does not carry. The name has to be validated up front.
    function validIconSource(source: string): string {
        const prefix = "image://icon/";
        if (!source)
            return "";
        if (!source.startsWith(prefix))
            return source;

        return Quickshell.iconPath(source.slice(prefix.length), true) !== "" ? source : "";
    }

    readonly property string resolvedImage: root.validIconSource(root.image)
    readonly property string resolvedAppIcon: root.appIcon !== "" ? Quickshell.iconPath(root.appIcon, true) : ""

    // Height comes straight from the content, so nothing has to round-trip
    // through the card's own geometry to be measured.
    implicitHeight: content.implicitHeight + 16

    Rectangle {
        id: field
        anchors.fill: parent
        color: ShellGlobals.materialColors.tertiary
        radius: ShellGlobals.radius

        RowLayout {
            id: content
            spacing: 8

            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                margins: 8
            }

            Item {
                visible: notifImage.visible || appIconImage.visible
                Layout.preferredWidth: 40
                Layout.preferredHeight: 40
                Layout.alignment: Qt.AlignTop

                Image {
                    id: notifImage
                    anchors.fill: parent
                    visible: root.resolvedImage !== ""
                    source: root.resolvedImage
                    sourceSize: Qt.size(80, 80)
                    fillMode: Image.PreserveAspectCrop
                    smooth: true
                    mipmap: true
                    asynchronous: true
                }

                Image {
                    id: appIconImage
                    anchors.fill: parent
                    visible: !notifImage.visible && root.resolvedAppIcon !== ""
                    source: root.resolvedAppIcon
                    sourceSize: Qt.size(80, 80)
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                    mipmap: true
                    asynchronous: true
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    StyledText {
                        id: appText
                        Layout.fillWidth: true
                        text: root.appName
                        color: ShellGlobals.materialColors.ontertiary
                        elide: Text.ElideRight
                    }

                    TintedIcon {
                        size: 14
                        source: Qt.resolvedUrl("icons/close.png")
                        color: ShellGlobals.materialColors.ontertiary

                        MouseArea {
                            anchors.fill: parent
                            onClicked: root.notif.dismiss()
                        }
                    }
                }

                StyledText {
                    id: sumText
                    Layout.fillWidth: true
                    wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                    text: root.summary
                    font.bold: true
                    color: ShellGlobals.materialColors.ontertiary
                    font.pixelSize: 15
                }

                StyledText {
                    id: bodText
                    Layout.fillWidth: true
                    visible: root.body.length > 0
                    wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                    text: root.body
                    // The server advertises body markup, so it has to be parsed
                    // rather than printed as literal tags.
                    textFormat: Text.StyledText
                    color: ShellGlobals.materialColors.ontertiary
                    font.pixelSize: ShellGlobals.fontSize + 2
                    maximumLineCount: 3
                    elide: Text.ElideRight
                }

                RowLayout {
                    Layout.alignment: Qt.AlignRight
                    visible: root.actions.length > 0
                    spacing: 4

                    Repeater {
                        model: root.actions

                        Rectangle {
                            id: actionRect
                            required property NotificationAction modelData

                            implicitWidth: actionText.width + 12
                            implicitHeight: actionText.height + 6
                            radius: ShellGlobals.radius
                            color: ShellGlobals.materialColors.secondary

                            StyledText {
                                id: actionText
                                anchors.centerIn: parent
                                text: actionRect?.modelData?.text ?? "Activate"
                                color: ShellGlobals.materialColors.onsecondary
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: actionRect.modelData.invoke()
                            }
                        }
                    }
                }
            }
        }
    }
}

import QtQuick
import Qt5Compat.GraphicalEffects
import qs

// A monochrome icon recoloured to `color`. This is the only ColorOverlay in the
// shell, so moving off Qt5Compat later is a one-file change.
//
// Pass an absolute URL, e.g. `Qt.resolvedUrl("icons/close.png")` from the
// caller's own file: Qt 6 resolves a relative path against the file that uses
// it, which would be this one.
Item {
    id: root

    property url source
    property color color: ShellGlobals.materialColors.ontertiarycontainer
    property int size: ShellGlobals.iconSize

    implicitWidth: root.size
    implicitHeight: root.size

    Image {
        id: image
        anchors.fill: parent
        source: root.source
        smooth: true
        mipmap: true
        visible: false
    }

    ColorOverlay {
        anchors.fill: parent
        source: image
        color: root.color
    }
}

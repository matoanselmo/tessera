import QtQuick

Item {
    id: root

    property alias source: image.source
    property alias asynchronous: image.asynchronous

    clip: true

    // PreserveAspectCrop fills the output at any resolution. The old version
    // hardcoded a width of 1920 with no height binding, so it only ever lined up
    // on a 1920-wide screen showing a 16:9 image.
    Image {
        id: image
        anchors.fill: parent
        source: Qt.resolvedUrl("Wallpaper.png")
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        smooth: true
        mipmap: true
    }
}

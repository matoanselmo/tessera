import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import qs
import qs.components
import qs.services

// Beside clipboard history: the selected entry in full, the image fitted to
// the pane or the text as it was copied, with what it is underneath. It
// fades in with the rest of the clipboard layout, and its content fades
// over as the selection moves.
Rectangle {
    id: root

    property var entry: null
    property bool shown: false

    // The whole text, which cliphist's list cuts short. Read when selected.
    property string fullText: ""

    color: ShellGlobals.materialColors.secondarycontainer
    radius: ShellGlobals.radius
    clip: true

    opacity: root.shown ? 1 : 0
    visible: root.opacity > 0

    Behavior on opacity {
        Anim {}
    }

    // Read after the cursor settles, so holding j does not start a decode
    // for every row it passes.
    onEntryChanged: {
        root.fullText = "";
        swap.restart();
        if (root.entry && !root.entry.image)
            settle.restart();
    }

    Timer {
        id: settle
        interval: 80
        onTriggered: {
            if (!root.entry || root.entry.image)
                return;
            decoder.command = ["sh", "-c", 'cliphist decode "$1" | head -c 8000', "sh", root.entry.id];
            decoder.running = true;
        }
    }

    Process {
        id: decoder

        stdout: StdioCollector {
            onStreamFinished: root.fullText = text
        }
    }

    // A quick fade as one entry replaces another.
    Anim {
        id: swap
        target: body
        property: "opacity"
        from: 0.4
        to: 1
        time: ShellGlobals.animFast
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 8

        Item {
            id: body
            Layout.fillWidth: true
            Layout.fillHeight: true

            Image {
                anchors.fill: parent
                visible: root.entry?.image ?? false
                source: root.entry?.image ? Clipboard.thumbOf(root.entry) : ""
                fillMode: Image.PreserveAspectFit
                asynchronous: true
                sourceSize.width: 720
                opacity: status === Image.Ready ? 1 : 0

                Behavior on opacity {
                    Anim {
                        time: ShellGlobals.animFast
                    }
                }
            }

            StyledText {
                anchors.fill: parent
                visible: root.entry !== null && !root.entry.image
                text: root.fullText !== "" ? root.fullText : (root.entry?.text ?? "")
                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                elide: Text.ElideRight
                textFormat: Text.PlainText
                font.family: ShellGlobals.monoFamily
                color: ShellGlobals.materialColors.onprimarycontainer
            }

            StyledText {
                anchors.centerIn: parent
                visible: root.entry === null
                text: "Nothing selected"
                opacity: 0.5
            }
        }

        StyledText {
            Layout.fillWidth: true
            elide: Text.ElideRight
            text: {
                const e = root.entry;
                if (!e)
                    return "";
                if (e.image)
                    return `${e.format.toUpperCase()} ${e.width}×${e.height} · ${e.size}`;
                const t = root.fullText !== "" ? root.fullText : e.text;
                const lines = t.split("\n").length;
                return `${t.length} chars${lines > 1 ? ` · ${lines} lines` : ""}`;
            }
            font.family: ShellGlobals.monoFamily
            font.pixelSize: 11
            opacity: 0.6
        }
    }
}

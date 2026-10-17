import QtQuick
import QtQuick.Layouts
import qs

// A terminal-style table: a dim header row, then rows of monospace cells with
// the current one highlighted (solid when the table has focus, faint when
// not). Meant to sit inside a TuiPane.
//
// `columns` is a list of `{ title, width }`, with width in pixels or 0 for the
// column that takes up the slack. `rows` is a list of string arrays.
ColumnLayout {
    id: table

    property var columns: []
    property var rows: []
    property int currentIndex: 0
    property bool focused: false
    property string emptyText: ""

    // A click selects the row; a double click (or Enter, from the owner)
    // means "do the obvious thing" with it.
    signal selected(int index)
    signal activated(int index)

    readonly property int rowHeight: 22

    Layout.fillWidth: true
    spacing: 0

    function move(delta: int): void {
        if (table.rows.length === 0)
            return;
        table.currentIndex = Math.max(0, Math.min(table.rows.length - 1, table.currentIndex + delta));
    }

    // Keep the cursor on a real row as the list shrinks.
    onRowsChanged: {
        if (table.currentIndex >= table.rows.length)
            table.currentIndex = Math.max(0, table.rows.length - 1);
    }

    component Cells: RowLayout {
        id: cells

        required property var values
        property color color: ShellGlobals.materialColors.ontertiarycontainer
        property bool bold: false

        spacing: 12

        Repeater {
            model: table.columns

            StyledText {
                required property var modelData
                required property int index

                Layout.preferredWidth: modelData.width > 0 ? modelData.width : -1
                Layout.fillWidth: modelData.width === 0
                text: cells.values[index] ?? ""
                elide: Text.ElideRight
                font.family: ShellGlobals.monoFamily
                font.bold: cells.bold
                color: cells.color
            }
        }
    }

    Cells {
        Layout.fillWidth: true
        Layout.leftMargin: 6
        Layout.rightMargin: 6
        Layout.preferredHeight: table.rowHeight
        values: table.columns.map(c => c.title)
        bold: true
        color: Qt.alpha(ShellGlobals.materialColors.ontertiarycontainer, 0.6)
    }

    StyledText {
        visible: table.rows.length === 0 && table.emptyText !== ""
        Layout.fillWidth: true
        Layout.leftMargin: 6
        Layout.preferredHeight: table.rowHeight
        verticalAlignment: Text.AlignVCenter
        text: table.emptyText
        font.family: ShellGlobals.monoFamily
        opacity: 0.5
    }

    // Counted rather than handed the array: given a fresh array of the same
    // length (a re-sort), Repeater kept its old items in their old order. By
    // index, each row always shows whatever is now at its position.
    Repeater {
        model: table.rows.length

        Rectangle {
            id: row
            required property int index

            readonly property var values: table.rows[row.index] ?? []

            readonly property bool current: row.index === table.currentIndex

            Layout.fillWidth: true
            Layout.preferredHeight: table.rowHeight
            radius: ShellGlobals.radius
            color: {
                if (row.current && table.focused)
                    return ShellGlobals.materialColors.secondary;
                if (row.current || hover.containsMouse)
                    return ShellGlobals.materialColors.tertiary;
                return "transparent";
            }

            Cells {
                anchors.fill: parent
                anchors.leftMargin: 6
                anchors.rightMargin: 6
                values: row.values
                color: row.current && table.focused ? ShellGlobals.materialColors.onsecondary : ShellGlobals.materialColors.ontertiarycontainer
            }

            MouseArea {
                id: hover
                anchors.fill: parent
                hoverEnabled: true
                onClicked: {
                    table.currentIndex = row.index;
                    table.selected(row.index);
                }
                onDoubleClicked: table.activated(row.index)
            }
        }
    }
}

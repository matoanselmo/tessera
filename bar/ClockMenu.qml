import QtQuick
import QtQuick.Layouts
import Quickshell
import qs
import qs.services
import qs.components

// Drops down from the centred clock: local time beside any world clocks set
// in ShellGlobals, a month calendar, and controls for whichever media player
// is active.
BarPopup {
    id: menu

    required property PanelWindow bar
    required property Item anchorItem

    readonly property var player: Media.player

    property int viewYear: clock.date.getFullYear()
    property int viewMonth: clock.date.getMonth()

    anchor.item: menu.anchorItem
    anchor.edges: Edges.Bottom
    anchor.gravity: Edges.Bottom
    anchor.margins.top: ShellGlobals.barGap

    // Grows past the default when several world clocks need the room. Only the
    // clock row counts, so a long track title still elides instead.
    implicitWidth: Math.max(300, clocks.implicitWidth + ShellGlobals.popupPadding * 2)
    contentHeight: column.implicitHeight + ShellGlobals.popupPadding * 2

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    onOpened: menu.resetMonth()

    // The progress bar needs fresh positions only while it can be seen.
    Binding {
        target: Media
        property: "trackPosition"
        value: true
        when: menu.visible
    }

    function resetMonth(): void {
        const months = (clock.date.getFullYear() - menu.viewYear) * 12 + clock.date.getMonth() - menu.viewMonth;
        menu.viewYear = clock.date.getFullYear();
        menu.viewMonth = clock.date.getMonth();
        menu.slideCalendar(Math.sign(months));
    }

    // Slides the new month in from the side it lies on, fading up.
    function slideCalendar(direction: int): void {
        if (direction === 0)
            return;
        monthChange.stop();
        calendarShift.x = 16 * direction;
        monthChange.start();
    }

    ParallelAnimation {
        id: monthChange

        Anim {
            target: calendarShift
            property: "x"
            to: 0
        }
        Anim {
            target: calendar
            property: "opacity"
            from: 0.2
            to: 1
        }
    }

    function shiftMonth(delta: int): void {
        const d = new Date(menu.viewYear, menu.viewMonth + delta, 1);
        menu.viewYear = d.getFullYear();
        menu.viewMonth = d.getMonth();
        menu.slideCalendar(delta);
    }

    function pad(n: int): string {
        return n.toString().padStart(2, "0");
    }

    function formatDuration(seconds: real): string {
        const s = Math.max(0, Math.floor(seconds));
        return `${Math.floor(s / 60)}:${menu.pad(s % 60)}`;
    }

    // `{ time, label }` for a fixed UTC offset at the current minute. Shifting
    // the instant by the offset and reading it back in UTC gives that zone's
    // wall clock without needing Intl in the JS engine.
    function worldTime(name: string, offsetMinutes: int): var {
        const now = clock.date;
        const z = new Date(now.getTime() + offsetMinutes * 60000);
        // Compare calendar days so the label can say when the zone is ahead.
        const localDay = Date.UTC(now.getFullYear(), now.getMonth(), now.getDate());
        const zoneDay = Date.UTC(z.getUTCFullYear(), z.getUTCMonth(), z.getUTCDate());
        const diff = Math.round((zoneDay - localDay) / 86400000);
        return {
            time: `${menu.pad(z.getUTCHours())}:${menu.pad(z.getUTCMinutes())}`,
            label: diff > 0 ? `${name}, tomorrow` : diff < 0 ? `${name}, yesterday` : name
        };
    }

    ColumnLayout {
        id: column
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            margins: ShellGlobals.popupPadding
        }
        spacing: ShellGlobals.popupSpacing

        // Clocks
        RowLayout {
            id: clocks
            Layout.fillWidth: true
            spacing: 10

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                StyledText {
                    text: Qt.formatDateTime(clock.date, "HH:mm")
                    font.bold: true
                    font.pixelSize: 26
                    color: ShellGlobals.materialColors.onprimarycontainer
                }

                StyledText {
                    text: Qt.formatDateTime(clock.date, "dddd, d MMMM")
                }
            }

            // A layout's maximum width is capped by its children, so the
            // column's fillWidth alone cannot push the world clocks to the edge.
            Item {
                Layout.fillWidth: true
            }

            Repeater {
                model: ShellGlobals.worldClocks

                ColumnLayout {
                    id: zone
                    required property var modelData
                    readonly property var now: menu.worldTime(zone.modelData.name, zone.modelData.offsetMinutes)

                    Layout.alignment: Qt.AlignRight
                    spacing: 0

                    StyledText {
                        Layout.alignment: Qt.AlignRight
                        text: zone.now.time
                        font.bold: true
                        font.pixelSize: 26
                        color: ShellGlobals.materialColors.onprimarycontainer
                    }

                    StyledText {
                        Layout.alignment: Qt.AlignRight
                        text: zone.now.label
                    }
                }
            }
        }

        Divider {}

        // Calendar
        RowLayout {
            Layout.fillWidth: true
            spacing: 6

            BarWidget {
                icon: "chevron-left.svg"
                color: hovered ? ShellGlobals.materialColors.tertiary : "transparent"
                foreground: ShellGlobals.materialColors.ontertiarycontainer
                implicitHeight: 26
                Layout.preferredHeight: 26
                interactive: true
                onClicked: menu.shiftMonth(-1)
            }

            StyledText {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                text: Qt.formatDate(new Date(menu.viewYear, menu.viewMonth, 1), "MMMM yyyy")
                font.bold: true
                font.pixelSize: 13
                color: ShellGlobals.materialColors.onprimarycontainer

                // Clicking the title jumps back to the current month.
                MouseArea {
                    cursorShape: Qt.PointingHandCursor
                    anchors.fill: parent
                    onClicked: menu.resetMonth()
                }
            }

            BarWidget {
                icon: "chevron-right.svg"
                color: hovered ? ShellGlobals.materialColors.tertiary : "transparent"
                foreground: ShellGlobals.materialColors.ontertiarycontainer
                implicitHeight: 26
                Layout.preferredHeight: 26
                interactive: true
                onClicked: menu.shiftMonth(1)
            }
        }

        GridLayout {
            id: calendar
            Layout.fillWidth: true
            columns: 7
            transform: Translate {
                id: calendarShift
            }
            rowSpacing: 2
            columnSpacing: 2

            readonly property int firstDay: Qt.locale().firstDayOfWeek % 7
            readonly property int leading: (new Date(menu.viewYear, menu.viewMonth, 1).getDay() - calendar.firstDay + 7) % 7

            Repeater {
                model: 7

                StyledText {
                    required property int index
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    text: Qt.locale().dayName((calendar.firstDay + index) % 7, Locale.ShortFormat).slice(0, 2)
                    font.pixelSize: 11
                    font.bold: true
                    opacity: 0.6
                }
            }

            Repeater {
                model: 42

                Rectangle {
                    id: cell
                    required property int index

                    readonly property date day: new Date(menu.viewYear, menu.viewMonth, 1 - calendar.leading + index)
                    readonly property bool inMonth: cell.day.getMonth() === menu.viewMonth
                    readonly property bool isToday: cell.day.toDateString() === clock.date.toDateString()

                    Layout.fillWidth: true
                    Layout.preferredHeight: 28
                    radius: ShellGlobals.radius
                    color: cell.isToday ? ShellGlobals.materialColors.secondary : "transparent"

                    StyledText {
                        anchors.centerIn: parent
                        text: cell.day.getDate()
                        font.bold: cell.isToday
                        color: cell.isToday ? ShellGlobals.materialColors.onsecondary : ShellGlobals.materialColors.onprimarycontainer
                        opacity: cell.inMonth ? 1 : 0.35
                    }
                }
            }
        }

        // Media, only when some player is around
        Divider {
            visible: menu.player !== null
        }

        RowLayout {
            Layout.fillWidth: true
            visible: menu.player !== null
            spacing: 10

            Rectangle {
                Layout.preferredWidth: 56
                Layout.preferredHeight: 56
                radius: ShellGlobals.radius
                color: ShellGlobals.materialColors.tertiary
                clip: true

                BarWidget {
                    anchors.centerIn: parent
                    visible: art.status !== Image.Ready
                    icon: "music.svg"
                    color: "transparent"
                    foreground: ShellGlobals.materialColors.ontertiary
                }

                Image {
                    id: art
                    anchors.fill: parent
                    source: menu.player?.trackArtUrl ?? ""
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    sourceSize.width: 112
                    sourceSize.height: 112
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                StyledText {
                    Layout.fillWidth: true
                    text: menu.player?.trackTitle || menu.player?.identity || ""
                    elide: Text.ElideRight
                    font.bold: true
                    font.pixelSize: 13
                    color: ShellGlobals.materialColors.onprimarycontainer
                }

                StyledText {
                    Layout.fillWidth: true
                    visible: text !== ""
                    text: menu.player?.trackArtist ?? ""
                    elide: Text.ElideRight
                }

                StyledText {
                    Layout.fillWidth: true
                    text: menu.player?.identity ?? ""
                    elide: Text.ElideRight
                    font.pixelSize: 11
                    opacity: 0.6
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            visible: Media.hasTimeline
            spacing: 4

            Track {
                Layout.fillWidth: true
                value: Media.progress
                // Positions are polled once a second while visible.
                continuous: Media.playing
                step: 1000
            }

            RowLayout {
                Layout.fillWidth: true

                StyledText {
                    Layout.fillWidth: true
                    text: menu.formatDuration(menu.player?.position ?? 0)
                    font.pixelSize: 11
                }

                StyledText {
                    text: menu.formatDuration(menu.player?.length ?? 0)
                    font.pixelSize: 11
                }
            }
        }

        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            visible: menu.player !== null
            spacing: 8

            BarWidget {
                icon: "media-previous.svg"
                color: hovered ? ShellGlobals.materialColors.surfacebright : ShellGlobals.materialColors.tertiary
                foreground: ShellGlobals.materialColors.ontertiary
                implicitHeight: 30
                Layout.preferredHeight: 30
                opacity: menu.player?.canGoPrevious ? 1 : 0.4
                interactive: menu.player?.canGoPrevious ?? false
                onClicked: menu.player.previous()
            }

            BarWidget {
                icon: menu.player?.isPlaying ? "media-pause.svg" : "media-play.svg"
                color: ShellGlobals.materialColors.secondary
                foreground: ShellGlobals.materialColors.onsecondary
                implicitWidth: 48
                implicitHeight: 30
                Layout.preferredHeight: 30
                opacity: menu.player?.canTogglePlaying ? 1 : 0.4
                interactive: menu.player?.canTogglePlaying ?? false
                onClicked: menu.player.togglePlaying()
            }

            BarWidget {
                icon: "media-next.svg"
                color: hovered ? ShellGlobals.materialColors.surfacebright : ShellGlobals.materialColors.tertiary
                foreground: ShellGlobals.materialColors.ontertiary
                implicitHeight: 30
                Layout.preferredHeight: 30
                opacity: menu.player?.canGoNext ? 1 : 0.4
                interactive: menu.player?.canGoNext ?? false
                onClicked: menu.player.next()
            }
        }
    }
}

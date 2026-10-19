// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import "../../../../../shared" as Glassy

// EveryThing-UI's date designs (Prince-1652, MIT): a pill with the day in a
// ring that fills through the month, or the month as a 7-column grid of
// dots (past, today in the accent, ahead) or of numbers. Like the pages, a
// click turns each over: the pill to its week, the month to its day; the
// wheel leafs through the months.
Glassy.EveryFrame {
    id: f
    // "pill", "dots" or "numbers"
    property string layout: "pill"
    property string family
    property date now: new Date()
    designWidth: 190
    designHeight: layout === "pill" ? 95 : 190
    card: layout === "pill" ? "pill" : "block"

    // 0 the front (the pill, the month), 1 the back (the week, the day).
    property int page: 0
    // Off inside the pages: their corner turns them, not a click here.
    property bool interactive: true
    property int monthOffset: 0
    readonly property bool turning: turn.running
    function togglePage() { if (!turning) turn.start() }

    readonly property int day: now.getDate()
    readonly property date month: new Date(now.getFullYear(), now.getMonth() + monthOffset, 1, 12)
    readonly property bool thisMonth: monthOffset === 0
    readonly property int daysInMonth: new Date(month.getFullYear(), month.getMonth() + 1, 0).getDate()
    // Columns from the locale's first weekday (Rainmeter's skin fixes Monday).
    readonly property int lead: (month.getDay() - Qt.locale().firstDayOfWeek + 7) % 7
    readonly property string monthName: Qt.locale().standaloneMonthName(month.getMonth(), Locale.LongFormat)
    // The days of this week from the locale's first weekday.
    readonly property var week: {
        const start = new Date(now.getFullYear(), now.getMonth(), day - (now.getDay() - Qt.locale().firstDayOfWeek + 7) % 7, 12);
        return [0, 1, 2, 3, 4, 5, 6].map(i => new Date(start.getFullYear(), start.getMonth(), start.getDate() + i, 12));
    }

    SequentialAnimation {
        id: turn
        ParallelAnimation {
            NumberAnimation { target: faces; property: "scale"; to: 0.94; duration: 140; easing.type: Easing.InCubic }
            NumberAnimation { target: faces; property: "opacity"; to: 0; duration: 140 }
        }
        ScriptAction { script: { f.page = 1 - f.page; f.monthOffset = 0; } }
        ParallelAnimation {
            NumberAnimation { target: faces; property: "scale"; to: 1; duration: 210; easing.type: Easing.OutCubic }
            NumberAnimation { target: faces; property: "opacity"; to: 1; duration: 210 }
        }
    }

    component Label: Glassy.EveryText {
        s: f.s
        color: f.colors.textPrimary
        font.family: f.family
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: f.interactive ? Qt.PointingHandCursor : Qt.ArrowCursor
        Accessible.role: Accessible.Button
        Accessible.name: f.layout === "pill" ? (f.page === 0 ? i18n("Show the week") : i18n("Show the date"))
            : f.page === 0 ? i18n("Show the day") : i18n("Show the month")
        onClicked: if (f.interactive) f.togglePage()
        // One notch a month, while the month shows.
        property real wheelRemainder: 0
        onWheel: wheel => {
            if (f.layout === "pill" || f.page !== 0) { wheel.accepted = false; return; }
            wheelRemainder += wheel.angleDelta.y;
            while (Math.abs(wheelRemainder) >= 120) {
                const step = wheelRemainder > 0 ? -1 : 1;
                wheelRemainder += step * 120;
                f.monthOffset += step;
            }
        }
    }

    Item {
        id: faces
        width: f.canvas.width
        height: f.canvas.height

        // Pill
        Glassy.EveryRing {
            visible: f.layout === "pill" && f.page === 0
            s: f.s; cx: 47.5; cy: 47.5; inner: 28; outer: 35
            value: (f.day - 1) / 30
            trackColor: f.track
            fillColor: f.colors.accent
        }
        Label { visible: f.layout === "pill" && f.page === 0; px: 47.5; py: 52; pt: 24; align: "CenterCenter"; value: Qt.formatDate(f.now, "dd") }
        Label { visible: f.layout === "pill" && f.page === 0; px: 95; py: 45; pt: 14; align: "LeftBottom"; upper: true; value: Qt.locale().standaloneMonthName(f.now.getMonth(), Locale.LongFormat); clipWidth: 85 }
        Label {
            visible: f.layout === "pill" && f.page === 0
            px: 95; py: 57; pt: 11; align: "LeftTop"; upper: true; clipWidth: 85
            value: Qt.locale().dayName(f.now.getDay(), Locale.LongFormat)
            color: f.colors.textSecondary
        }
        // The pill's back: this week, a letter and a dot a day, today in the accent.
        Repeater {
            model: f.layout === "pill" && f.page === 1 ? f.week : []
            Item {
                id: weekday
                required property date modelData
                required property int index
                readonly property real cx: 29 + index * 22
                readonly property bool today: modelData.getDate() === f.day && modelData.getMonth() === f.now.getMonth()
                Label {
                    px: weekday.cx; py: 34; pt: 10; align: "CenterCenter"; upper: true
                    value: Qt.locale().dayName(weekday.modelData.getDay(), Locale.NarrowFormat)
                    color: weekday.today ? f.colors.textPrimary : f.colors.textMuted
                }
                Rectangle {
                    readonly property real r: weekday.today ? 6 : 4
                    x: (weekday.cx - r) * f.s
                    y: (62 - r) * f.s
                    width: 2 * r * f.s
                    height: width
                    radius: width / 2
                    color: weekday.today ? f.colors.accent : weekday.modelData < f.now ? f.colors.textPrimary : f.track
                }
            }
        }

        // Month grid
        Label { visible: f.layout !== "pill" && f.page === 0; px: 20; py: 20; pt: 18; upper: true; value: f.monthName; clipWidth: f.thisMonth ? 150 : 110 }
        Label {
            visible: f.layout !== "pill" && f.page === 0 && !f.thisMonth
            px: 170; py: 23; pt: 12; align: "RightTop"
            value: String(f.month.getFullYear())
            color: f.colors.textSecondary
        }
        Repeater {
            model: f.layout === "pill" || f.page !== 0 ? 0 : f.daysInMonth
            Item {
                id: cell
                required property int index
                readonly property int number: index + 1
                readonly property bool today: f.thisMonth && number === f.day
                readonly property bool past: f.monthOffset < 0 || (f.thisMonth && number < f.day)
                readonly property real cx: 26 + ((index + f.lead) % 7) * 23
                readonly property real cy: 65 + Math.floor((index + f.lead) / 7) * 23
                // Dots: past days white, today the accent, the rest grey.
                Rectangle {
                    visible: f.layout === "dots" || cell.today
                    readonly property real r: f.layout === "dots" ? 6 : 10
                    x: (cell.cx - r) * f.s
                    y: (cell.cy - r) * f.s
                    width: 2 * r * f.s
                    height: width
                    radius: width / 2
                    color: cell.today ? f.colors.accent : cell.past ? f.colors.textPrimary : f.track
                }
                Label {
                    visible: f.layout === "numbers"
                    px: cell.cx; py: cell.cy; pt: 10; align: "CenterCenter"
                    value: String(cell.number)
                    color: cell.today ? f.colors.accentText : f.colors.textPrimary
                }
            }
        }
        // The month's back: the day, large.
        Label {
            visible: f.layout !== "pill" && f.page === 1
            px: 20; py: 20; pt: 18; upper: true; clipWidth: 150
            value: Qt.locale().dayName(f.now.getDay(), Locale.LongFormat)
            color: f.colors.accent
        }
        Label {
            visible: f.layout !== "pill" && f.page === 1
            px: 95; py: 102; pt: 72; align: "CenterCenter"
            value: String(f.day)
        }
        Label {
            visible: f.layout !== "pill" && f.page === 1
            px: 95; py: 168; pt: 12; align: "CenterCenter"; upper: true
            value: Qt.locale().standaloneMonthName(f.now.getMonth(), Locale.LongFormat) + " " + f.now.getFullYear()
            color: f.colors.textSecondary
        }
    }
}

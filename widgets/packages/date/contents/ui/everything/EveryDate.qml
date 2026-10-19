// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import "../../../../../shared" as Glassy

// EveryThing-UI's date designs (Prince-1652, MIT): a pill with the day in a
// ring that fills through the month, or the month as a 7-column grid of
// dots (past, today in the accent, ahead) or of numbers.
Glassy.EveryFrame {
    id: f
    // "pill", "dots" or "numbers"
    property string layout: "pill"
    property string family
    property date now: new Date()
    designWidth: 190
    designHeight: layout === "pill" ? 95 : 190
    card: layout === "pill" ? "pill" : "block"

    readonly property int day: now.getDate()
    readonly property int daysInMonth: new Date(now.getFullYear(), now.getMonth() + 1, 0).getDate()
    // Columns from the locale's first weekday (Rainmeter's skin fixes Monday).
    readonly property int lead: (new Date(now.getFullYear(), now.getMonth(), 1).getDay() - Qt.locale().firstDayOfWeek + 7) % 7
    readonly property string monthName: Qt.locale().standaloneMonthName(now.getMonth(), Locale.LongFormat)

    component Label: Glassy.EveryText {
        s: f.s
        color: f.colors.textPrimary
        font.family: f.family
    }

    // Pill
    Glassy.EveryRing {
        visible: f.layout === "pill"
        s: f.s; cx: 47.5; cy: 47.5; inner: 28; outer: 35
        value: (f.day - 1) / 30
        trackColor: f.track
        fillColor: f.colors.textPrimary
    }
    Label { visible: f.layout === "pill"; px: 47.5; py: 52; pt: 24; align: "CenterCenter"; value: Qt.formatDate(f.now, "dd"); color: f.colors.accent }
    Label { visible: f.layout === "pill"; px: 95; py: 45; pt: 14; align: "LeftBottom"; upper: true; value: f.monthName; clipWidth: 85 }
    Label {
        visible: f.layout === "pill"
        px: 95; py: 57; pt: 11; align: "LeftTop"; upper: true; clipWidth: 85
        value: Qt.locale().dayName(f.now.getDay(), Locale.LongFormat)
        color: f.colors.accent
    }

    // Month grid
    Label { visible: f.layout !== "pill"; px: 20; py: 20; pt: 18; upper: true; value: f.monthName; clipWidth: 150 }
    Repeater {
        model: f.layout === "pill" ? 0 : f.daysInMonth
        Item {
            id: cell
            required property int index
            readonly property int number: index + 1
            readonly property real cx: 26 + ((index + f.lead) % 7) * 23
            readonly property real cy: 65 + Math.floor((index + f.lead) / 7) * 23
            // Dots: past days white, today the accent, the rest grey.
            Rectangle {
                visible: f.layout === "dots" || cell.number === f.day
                readonly property real r: f.layout === "dots" ? 6 : 10
                x: (cell.cx - r) * f.s
                y: (cell.cy - r) * f.s
                width: 2 * r * f.s
                height: width
                radius: width / 2
                color: cell.number === f.day ? f.colors.accent : cell.number < f.day ? f.colors.textPrimary : f.track
            }
            Label {
                visible: f.layout === "numbers"
                px: cell.cx; py: cell.cy; pt: 10; align: "CenterCenter"
                value: String(cell.number)
                color: cell.number === f.day ? f.colors.accentText : f.colors.textPrimary
            }
        }
    }
}

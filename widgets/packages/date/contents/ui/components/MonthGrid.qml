// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick

// A month on a 7-column grid starting at the locale's first weekday: numbers
// with today in the accent, or (numbers: false) one dot per day.
Grid {
    id: grid
    required property QtObject colors
    property var locale: Qt.locale()
    property date today: new Date()
    property string numberFamily: ""
    property date month: new Date(grid.today.getFullYear(), grid.today.getMonth(), 1)
    property bool numbers: true
    property real cell: 24
    readonly property int offset: (month.getDay() - grid.locale.firstDayOfWeek % 7 + 7) % 7
    readonly property int days: new Date(month.getFullYear(), month.getMonth() + 1, 0).getDate()
    columns: 7
    Repeater {
        model: 7
        Text {
            required property int index
            width: grid.cell
            height: grid.cell * 0.8
            visible: grid.numbers
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            text: grid.upper(grid.locale.standaloneDayName((grid.locale.firstDayOfWeek + index) % 7, Locale.NarrowFormat))
            color: grid.colors.textMuted
            font.pixelSize: grid.cell * 0.4
        }
    }
    Repeater {
        model: 42
        Item {
            id: day
            required property int index
            readonly property int number: index - grid.offset + 1
            readonly property bool inMonth: number >= 1 && number <= grid.days
            readonly property bool isToday: inMonth && grid.month.getMonth() === grid.today.getMonth()
                && grid.month.getFullYear() === grid.today.getFullYear() && number === grid.today.getDate()
            readonly property bool past: grid.month < new Date(grid.today.getFullYear(), grid.today.getMonth(), 1)
                || (grid.month.getMonth() === grid.today.getMonth() && grid.month.getFullYear() === grid.today.getFullYear() && number < grid.today.getDate())
            width: grid.cell
            height: grid.cell
            visible: index < 35 || grid.offset + grid.days > 35
            Rectangle {
                anchors.centerIn: parent
                width: grid.numbers ? parent.width * 0.86 : parent.width * 0.5
                height: width
                radius: width / 2
                visible: day.inMonth && (day.isToday || !grid.numbers)
                color: day.isToday ? grid.colors.accent : day.past ? grid.colors.textPrimary : grid.colors.alpha(grid.colors.textPrimary, 0.22)
            }
            Text {
                anchors.centerIn: parent
                visible: grid.numbers && day.inMonth
                text: day.number
                color: day.isToday ? grid.colors.accentText : grid.colors.textPrimary
                font.family: grid.numberFamily
                font.pixelSize: grid.cell * 0.5
            }
        }
    }
    function upper(text) { return text.toLocaleUpperCase(locale.name); }
    function dayAt(cellIndex) { return new Date(month.getFullYear(), month.getMonth(), cellIndex - offset + 1, 12); }
}

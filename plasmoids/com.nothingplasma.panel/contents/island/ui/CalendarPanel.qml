// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import org.kde.plasma.plasmoid
import org.kde.plasma.workspace.calendar as PlasmaCalendar
import "."

// The island's calendar: a month of days, or the year's months to jump to,
// with Plasma's holiday and moon-phase events and the chosen day below.
Item {
    id: calendar

    signal closed
    property var panelConfig: Plasmoid.configuration

    // Events come from Plasma's own calendar plugins, switched in the header.
    readonly property var plugins: panelConfig?.calendarEvents ?? ["holidaysevents"]
    function togglePlugin(id) {
        if (!panelConfig) return;
        panelConfig.calendarEvents = plugins.includes(id) ? plugins.filter(p => p !== id) : plugins.concat(id);
    }
    PlasmaCalendar.EventPluginsManager {
        id: eventPlugins
        enabledPlugins: calendar.plugins
    }
    PlasmaCalendar.Calendar {
        id: source
        days: 7
        weeks: 6
        firstDayOfWeek: calendar.locale.firstDayOfWeek
        today: calendar.today
        displayedDate: calendar.month
        Component.onCompleted: daysModel.setPluginsManager(eventPlugins)
    }
    // Plugins answer asynchronously; bindings that ask for events read this.
    property int eventsVersion: 0
    Connections {
        target: source.daysModel
        function onAgendaUpdated() { calendar.eventsVersion++; }
        function onModelReset() { calendar.eventsVersion++; }
    }
    function eventsOn(day) {
        void calendar.eventsVersion;
        return source.daysModel.eventsForDate(day);
    }

    readonly property var locale: Cfg.locale
    property date today: new Date()
    // The first day of the month on show.
    property date month: new Date(today.getFullYear(), today.getMonth(), 1)
    property date selected: new Date(NaN)
    property bool pickingMonth: false
    readonly property date focusDay: isNaN(selected.getTime()) ? today : selected
    readonly property bool onThisMonth: month.getMonth() === today.getMonth() && month.getFullYear() === today.getFullYear()

    // Follows midnight without a timer per cell.
    Timer {
        interval: 60000
        running: true
        repeat: true
        onTriggered: {
            const now = new Date();
            if (!calendar.sameDay(now, calendar.today)) calendar.today = now;
        }
    }

    function shift(months) {
        month = new Date(month.getFullYear(), month.getMonth() + months, 1);
    }
    function showToday() {
        month = new Date(today.getFullYear(), today.getMonth(), 1);
        selected = new Date(today.getFullYear(), today.getMonth(), today.getDate());
        pickingMonth = false;
    }
    function sameDay(a, b) {
        return a.toDateString() === b.toDateString();
    }
    // ISO 8601: the week that holds the year's first Thursday is week 1.
    function isoWeek(day) {
        const thursday = new Date(day.getFullYear(), day.getMonth(), day.getDate() + 3 - (day.getDay() + 6) % 7);
        // Rounded to whole days first: a daylight saving change shifts the difference by an hour.
        return 1 + Math.floor(Math.round((thursday - new Date(thursday.getFullYear(), 0, 1)) / 86400000) / 7);
    }
    function upper(text) {
        return text.toLocaleUpperCase(calendar.locale.name);
    }
    // Six weeks starting on the locale's first weekday.
    readonly property var days: {
        const lead = (month.getDay() - locale.firstDayOfWeek + 7) % 7;
        return Array.from({length: 42}, (_, i) => new Date(month.getFullYear(), month.getMonth(), 1 - lead + i));
    }

    implicitHeight: content.implicitHeight + 44

    // Swaps between the days and the months, sliding a little.
    component Page: Item {
        property bool shown: true
        width: parent.width
        opacity: shown ? 1 : 0
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: Theme.durShort } }
        Behavior on y { NumberAnimation { duration: Theme.durMedium; easing.type: Easing.Bezier; easing.bezierCurve: Theme.emphasizedDecel } }
    }

    Column {
        id: content
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        spacing: 10

        PanelHeader {
            title: Cfg.t("CALENDAR")
            onClosed: calendar.closed()
            Repeater {
                model: [{id: "holidaysevents", icon: "celebration", label: "HOLIDAYS"},
                    {id: "astronomicalevents", icon: "bedtime", label: "MOON PHASES"}]
                RoundButton {
                    required property var modelData
                    icon: modelData.icon
                    on: calendar.plugins.includes(modelData.id)
                    onClicked: calendar.togglePlugin(modelData.id)
                    Accessible.role: Accessible.CheckBox
                    Accessible.name: Cfg.t(modelData.label)
                    Accessible.checked: on
                }
            }
            RoundButton {
                visible: !calendar.onThisMonth
                label: Cfg.t("TODAY")
                onClicked: calendar.showToday()
            }
        }

        // Month and year; the title switches to the month picker.
        Item {
            width: parent.width
            height: 34
            RoundButton {
                id: back
                anchors.verticalCenter: parent.verticalCenter
                height: 30
                flat: true
                iconSize: 20
                icon: "chevron_left"
                onClicked: calendar.shift(calendar.pickingMonth ? -12 : -1)
            }
            RoundButton {
                anchors.left: back.right
                anchors.right: forward.left
                anchors.margins: 4
                anchors.verticalCenter: parent.verticalCenter
                height: 32
                flat: true
                held: calendar.pickingMonth
                onClicked: calendar.pickingMonth = !calendar.pickingMonth
                Text {
                    anchors.centerIn: parent
                    text: calendar.pickingMonth ? String(calendar.month.getFullYear())
                        : calendar.upper(calendar.locale.standaloneMonthName(calendar.month.getMonth(), Locale.LongFormat) + " " + calendar.month.getFullYear())
                    color: Theme.fg
                    font.family: Theme.font
                    font.pixelSize: Theme.bodyMedium
                    font.weight: Font.Medium
                    font.letterSpacing: Theme.labelSpacing
                }
            }
            RoundButton {
                id: forward
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                height: 30
                flat: true
                iconSize: 20
                icon: "chevron_right"
                onClicked: calendar.shift(calendar.pickingMonth ? 12 : 1)
            }
        }

        Item {
            width: parent.width
            height: 214
            clip: true

            Page {
                id: dayPage
                shown: !calendar.pickingMonth
                y: shown ? 0 : -14
                height: parent.height
                readonly property real cell: width / 7
                Row {
                    Repeater {
                        model: 7
                        Text {
                            required property int index
                            width: dayPage.cell
                            height: 22
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            text: calendar.upper(calendar.locale.dayName((calendar.locale.firstDayOfWeek + index) % 7, Locale.ShortFormat).substring(0, 2))
                            color: Theme.fgFaint
                            font.family: Theme.font
                            font.pixelSize: Theme.labelSmall
                            font.letterSpacing: Theme.labelSpacing
                        }
                    }
                }
                Grid {
                    y: 26
                    columns: 7
                    Repeater {
                        model: calendar.days
                        Item {
                            id: day
                            required property date modelData
                            readonly property bool isToday: calendar.sameDay(modelData, calendar.today)
                            readonly property bool inMonth: modelData.getMonth() === calendar.month.getMonth()
                            width: dayPage.cell
                            height: 30
                            Rectangle {
                                anchors.centerIn: parent
                                width: 28
                                height: 28
                                radius: 14
                                color: day.isToday ? Theme.inverted : Qt.alpha(Theme.fg, dayArea.containsMouse ? Theme.stateHover : 0)
                                border.width: !day.isToday && calendar.sameDay(day.modelData, calendar.selected) ? 1.5 : 0
                                border.color: Theme.fgDim
                                Behavior on color { ColorAnimation { duration: Theme.durShort } }
                                Text {
                                    anchors.centerIn: parent
                                    text: day.modelData.getDate()
                                    color: day.isToday ? Theme.invertedFg : day.inMonth ? Theme.fg : Theme.fgFaint
                                    font.family: Theme.fontDots
                                    font.pixelSize: 15
                                    font.weight: Font.Bold
                                }
                                // A dot under days with events.
                                Rectangle {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    anchors.bottom: parent.bottom
                                    anchors.bottomMargin: 2
                                    width: 4
                                    height: 4
                                    radius: 2
                                    visible: calendar.eventsOn(day.modelData).length > 0
                                    color: day.isToday ? Theme.invertedFg : Theme.primary
                                    opacity: day.inMonth ? 1 : 0.4
                                }
                                MouseArea {
                                    id: dayArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        calendar.selected = day.modelData;
                                        if (!day.inMonth) calendar.month = new Date(day.modelData.getFullYear(), day.modelData.getMonth(), 1);
                                    }
                                }
                            }
                        }
                    }
                }
            }

            Page {
                id: monthPage
                shown: calendar.pickingMonth
                y: shown ? 0 : 14
                height: parent.height
                Grid {
                    columns: 4
                    Repeater {
                        model: 12
                        Item {
                            id: monthCell
                            required property int index
                            readonly property bool current: index === calendar.month.getMonth()
                            readonly property bool thisMonth: index === calendar.today.getMonth() && calendar.month.getFullYear() === calendar.today.getFullYear()
                            width: monthPage.width / 4
                            height: 66
                            Rectangle {
                                anchors.centerIn: parent
                                width: parent.width - 8
                                height: 54
                                radius: Theme.shapeMd
                                color: monthCell.current ? Theme.inverted : monthArea.containsMouse ? Theme.surfaceHigh : Theme.surfaceAlt
                                border.width: monthCell.thisMonth && !monthCell.current ? 1.5 : 0
                                border.color: Theme.fgDim
                                Behavior on color { ColorAnimation { duration: Theme.durShort } }
                                Text {
                                    anchors.centerIn: parent
                                    text: calendar.upper(calendar.locale.standaloneMonthName(monthCell.index, Locale.ShortFormat))
                                    color: monthCell.current ? Theme.invertedFg : Theme.fg
                                    font.family: Theme.font
                                    font.pixelSize: Theme.bodySmall
                                    font.weight: Font.Medium
                                    font.letterSpacing: Theme.labelSpacing
                                }
                                MouseArea {
                                    id: monthArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        calendar.month = new Date(calendar.month.getFullYear(), monthCell.index, 1);
                                        calendar.pickingMonth = false;
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // The chosen day (or today): weekday, month, week number and events.
        Rectangle {
            id: summary
            width: parent.width
            height: Math.max(46, details.implicitHeight + 16)
            radius: Theme.shapeLg
            color: Theme.surfaceAlt
            readonly property string events: calendar.eventsOn(calendar.focusDay).map(e => e.title).join(" · ")
            Text {
                id: dayNumber
                anchors.left: parent.left
                anchors.leftMargin: 14
                anchors.verticalCenter: parent.verticalCenter
                text: calendar.focusDay.getDate()
                color: Theme.fg
                font.family: Theme.fontDots
                font.pixelSize: 24
                font.weight: Font.Bold
            }
            Column {
                id: details
                anchors.left: dayNumber.right
                anchors.right: parent.right
                anchors.leftMargin: 12
                anchors.rightMargin: 14
                anchors.verticalCenter: parent.verticalCenter
                spacing: 1
                Text {
                    width: parent.width
                    text: calendar.upper(calendar.locale.dayName(calendar.focusDay.getDay(), Locale.LongFormat))
                    color: Theme.fg
                    font.family: Theme.font
                    font.pixelSize: Theme.labelMedium
                    font.letterSpacing: Theme.labelSpacing
                    elide: Text.ElideRight
                }
                Text {
                    width: parent.width
                    text: calendar.upper(calendar.locale.standaloneMonthName(calendar.focusDay.getMonth(), Locale.LongFormat) + " "
                        + calendar.focusDay.getFullYear() + " · " + Cfg.t("Week") + " " + calendar.isoWeek(calendar.focusDay))
                    color: Theme.fgFaint
                    font.family: Theme.font
                    font.pixelSize: Theme.labelSmall
                    font.letterSpacing: Theme.labelSpacing
                    elide: Text.ElideRight
                }
                Text {
                    width: parent.width
                    visible: text !== ""
                    text: calendar.upper(summary.events)
                    color: Theme.primary
                    font.family: Theme.font
                    font.pixelSize: Theme.labelSmall
                    font.letterSpacing: Theme.labelSpacing
                    wrapMode: Text.Wrap
                    maximumLineCount: 2
                    elide: Text.ElideRight
                }
            }
        }
    }
}

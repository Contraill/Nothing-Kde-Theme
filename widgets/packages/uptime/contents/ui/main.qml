// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.ksysguard.sensors as Sensors
import "../../../../shared" as Glassy
import "components"
import "everything"

// Time on per day for the current week (EveryThing-UI's uptime). Each day's
// seconds are kept in the widget's configuration, two weeks at most.
PlasmoidItem {
    id: root
    preferredRepresentation: fullRepresentation
    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground

    NothingColors {
        id: nColors
        themeMode: Plasmoid.configuration.themeMode
        useSystemAccent: Plasmoid.configuration.useSystemAccent
        monochrome: Plasmoid.configuration.monochrome
    }
    Glassy.DotFont { id: dotFont }

    Sensors.Sensor {
        id: sinceBoot
        sensorId: "os/system/uptime"
        updateRateLimit: 60000
        // The first reading arrives after the first tick.
        onValueChanged: if (root.lastTick > 0 && Number(value) > 0) root.raiseToday()
    }
    function raiseToday() {
        const current = new Date();
        const days = read();
        const today = key(current);
        const sinceMidnight = (current - new Date(current.getFullYear(), current.getMonth(), current.getDate())) / 1000;
        const floor = Math.round(Math.min(Number(sinceBoot.value) || 0, sinceMidnight));
        if ((days[today] || 0) >= floor) return;
        days[today] = floor;
        history = days;
        Plasmoid.configuration.history = JSON.stringify(days);
    }

    property var history: ({})
    property date now: new Date()
    property real lastTick: 0

    function key(day) {
        const pad = n => (n < 10 ? "0" : "") + n;
        return day.getFullYear() + "-" + pad(day.getMonth() + 1) + "-" + pad(day.getDate());
    }
    function read() {
        try { return JSON.parse(Plasmoid.configuration.history || "{}") || {}; } catch (e) { return {}; }
    }
    // Adds the time since the last tick to today; a long gap means the machine
    // slept, and counts as one tick. Today never shows less than the time since
    // boot (or since midnight, whichever is shorter), which also covers the
    // minutes before the widget first ran.
    function tick() {
        const current = new Date();
        const today = key(current);
        const days = read();
        const sinceMidnight = (current - new Date(current.getFullYear(), current.getMonth(), current.getDate())) / 1000;
        if (lastTick > 0) {
            const gap = (current.getTime() - lastTick) / 1000;
            days[today] = (days[today] || 0) + Math.min(gap > 180 ? 60 : gap, sinceMidnight);
        }
        days[today] = Math.round(Math.max(days[today] || 0, Math.min(Number(sinceBoot.value) || 0, sinceMidnight)));
        const oldest = key(new Date(current.getFullYear(), current.getMonth(), current.getDate() - 14));
        for (const day of Object.keys(days))
            if (day < oldest) delete days[day];
        lastTick = current.getTime();
        now = current;
        history = days;
        Plasmoid.configuration.history = JSON.stringify(days);
    }
    Timer {
        interval: 60000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.tick()
    }

    // The week from the locale's first day.
    readonly property var week: {
        const start = new Date(now.getFullYear(), now.getMonth(), now.getDate() - (now.getDay() - Qt.locale().firstDayOfWeek + 7) % 7);
        const today = key(now);
        return [0, 1, 2, 3, 4, 5, 6].map(i => {
            const day = new Date(start.getFullYear(), start.getMonth(), start.getDate() + i);
            const k = key(day);
            return {label: Qt.locale().dayName(day.getDay(), Locale.ShortFormat), seconds: history[k] || 0, today: k === today, future: k > today};
        });
    }

    fullRepresentation: EveryUptime {
        transparent: Plasmoid.configuration.transparent
        Layout.preferredWidth: 400
        Layout.preferredHeight: 200
        Layout.minimumWidth: 260
        Layout.minimumHeight: 130
        colors: nColors
        family: dotFont.name
        days: root.week
        todayText: hours(root.history[root.key(root.now)] || 0)
    }
}

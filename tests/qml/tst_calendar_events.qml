import QtQuick
import QtTest
import "../../plasmoids/com.nothingplasma.panel/contents/island/ui" as Island

Item {
    width: 420
    height: 480
    QtObject {
        id: config
        property var calendarEvents: ["holidaysevents"]
    }
    Island.CalendarPanel { id: panel; width: 400; panelConfig: config }
    TestCase {
        name: "CalendarEvents"
        when: windowShown
        function test_togglePlugins() {
            panel.togglePlugin("astronomicalevents");
            compare(config.calendarEvents, ["holidaysevents", "astronomicalevents"]);
            panel.togglePlugin("holidaysevents");
            compare(config.calendarEvents, ["astronomicalevents"]);
            compare(panel.plugins, ["astronomicalevents"]);
        }
        function test_isoWeeks() {
            compare(panel.isoWeek(new Date(2026, 9, 19)), 43);
            compare(panel.isoWeek(new Date(2026, 0, 1)), 1);
            compare(panel.isoWeek(new Date(2027, 0, 1)), 53);
            compare(panel.isoWeek(new Date(2024, 11, 30)), 1);
            // Across the spring daylight saving change.
            compare(panel.isoWeek(new Date(2026, 2, 30)), 14);
        }
        function test_eventsAreAList() {
            compare(typeof panel.eventsOn(new Date()).length, "number");
        }
    }
}

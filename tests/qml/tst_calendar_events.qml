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
        function test_eventsAreAList() {
            compare(typeof panel.eventsOn(new Date()).length, "number");
        }
    }
}

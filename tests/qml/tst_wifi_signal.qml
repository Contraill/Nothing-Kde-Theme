import QtQuick
import QtTest
import "../../plasmoids/com.nothingplasma.panel/contents/island/ui" as Island

Item {
    width: 100; height: 100
    Island.WifiSignal { id: icon }
    TestCase {
        name: "WifiSignal"
        when: windowShown
        function initTestCase() { Island.Backend.preview = true; }
        function test_signal_levels_data() {
            return [{tag:"unknown", value:-1, level:0}, {tag:"weak", value:0, level:0},
                    {tag:"below_first", value:24, level:0}, {tag:"one", value:25, level:1},
                    {tag:"below_second", value:49, level:1}, {tag:"two", value:50, level:2},
                    {tag:"below_full", value:74, level:2}, {tag:"full", value:75, level:3},
                    {tag:"maximum", value:100, level:3}];
        }
        function test_signal_levels(data) { icon.strength = data.value; compare(icon.level, data.level); }
    }
}

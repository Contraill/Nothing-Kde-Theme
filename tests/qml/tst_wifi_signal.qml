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
        function test_cached_signal_without_network_menu() {
            compare(Island.Net.netWatchers, 0);
            Island.Net.readBase("wifi:connected:Test\n---\nenabled\n---\nPowered: yes\n---\n:99\n*:63\n");
            compare(Island.Net.signal_, 63);
            compare(Island.Net.isWifi, true);
            Island.Net.readBase("wifi:disconnected:\n---\nenabled\n---\nPowered: yes\n---\n");
            compare(Island.Net.signal_, -1);
            compare(Island.Net.isWifi, false);
        }
        function test_unknown_is_not_zero_signal() {
            Island.Net.readBase("wifi:connected:Test\n---\nenabled\n---\nPowered: yes\n---\n*:invalid\n");
            compare(Island.Net.signal_, -1);
            verify(Island.Net.baseCmd.includes("--rescan no"));
        }
    }
}

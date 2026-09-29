import QtQuick
import QtTest
import "../../plasmoids/com.nothingplasma.panel/contents/ui/components" as Components
Item {
    Components.WallpaperSync { id: sync; enabled: false; screens: [] }
    SignalSpy { id: requests; target: sync; signalName: "synchronize" }
    TestCase {
        name: "WallpaperSync"
        function init() { sync.enabled = false; sync.screens = []; sync.activity = ""; sync.mode = "dark"; requests.clear(); }
        function cleanup() { sync.enabled = false; }
        function fast() { sync.delay = 1; sync.retry.restart(); }
        function test_startup_burst_is_bounded_and_uses_current_mode() {
            sync.enabled = true; fast();
            tryCompare(requests, "count", 4);
            wait(40); compare(requests.count,4);
            sync.mode = "light"; fast();
            tryCompare(requests, "count", 8);
            compare(requests.signalArguments[7][0], "light");
        }
        function test_hotplug_and_activity_trigger_even_after_startup() {
            sync.enabled = true; fast(); tryCompare(requests,"count",4);
            sync.screens = ["new-monitor"]; fast(); tryCompare(requests,"count",8);
            sync.activity = "second-activity"; fast(); tryCompare(requests,"count",12);
        }
        function test_opt_out_cancels_pending_requests() {
            sync.enabled = true;
            sync.enabled = false;
            sync.screens = ["new-monitor"];
            wait(30); compare(requests.count,0); compare(sync.retry.running,false);
        }
    }
}

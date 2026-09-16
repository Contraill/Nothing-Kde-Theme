import QtQuick
import QtTest
import "../../widgets/packages/media/contents/ui/components" as Media

Item {
    width: 400; height: 100
    Component {
        id: factory
        Media.MarqueeText { width: 100; height: 50; initialPause: 20; endPause: 20; scrollSpeed: 2 }
    }
    TestCase {
        name: "MarqueeSizing"
        when: windowShown
        property var page
        property var label
        function init() { page = factory.createObject(parent); label = page.children[0]; }
        function cleanup() { page.destroy(); }
        function test_text_and_container_resize() {
            page.text = "Long enough track title to require scrolling";
            tryVerify(() => label.x < 0);
            page.width = 2000;
            tryCompare(label, "x", 0);
            wait(100); compare(label.x, 0);
            page.width = 100;
            tryVerify(() => label.x < 0);
            page.text = "Short";
            tryCompare(label, "x", 0);
            wait(100); compare(label.x, 0);
        }
        function test_font_metrics_restart_scrolling() {
            page.width = 150; page.fontSize = 10; page.text = "Track title";
            wait(100); compare(label.x, 0);
            page.fontSize = 40;
            tryVerify(() => label.x < 0);
            page.fontSize = 10;
            tryCompare(label, "x", 0);
            wait(100); compare(label.x, 0);
        }
    }
}

import QtQuick
import QtTest
import "../../widgets/packages/media/contents/ui/components" as Media

Item {
    width: 400; height: 100
    Component {
        id: factory
        Media.Marquee { width: 100; height: 50; pause: 20; speed: 1 }
    }
    TestCase {
        name: "Marquee"
        when: windowShown
        property var marquee
        function init() { marquee = factory.createObject(parent); }
        function cleanup() { marquee.destroy(); }
        function test_scrolls_only_while_the_text_overflows() {
            marquee.text = "Long enough track title to require scrolling";
            tryVerify(() => marquee.label.x < 0);
            marquee.width = 2000;
            tryCompare(marquee.label, "x", 0);
            wait(100); compare(marquee.label.x, 0);
            marquee.width = 100;
            tryVerify(() => marquee.label.x < 0);
            marquee.text = "Short";
            tryCompare(marquee.label, "x", 0);
            wait(100); compare(marquee.label.x, 0);
        }
        function test_font_size_restarts_scrolling() {
            marquee.width = 150; marquee.fontSize = 10; marquee.text = "Track title";
            wait(100); compare(marquee.label.x, 0);
            marquee.fontSize = 40;
            tryVerify(() => marquee.label.x < 0);
            marquee.fontSize = 10;
            tryCompare(marquee.label, "x", 0);
            wait(100); compare(marquee.label.x, 0);
        }
    }
}

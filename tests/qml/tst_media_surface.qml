import QtQuick
import QtTest
import "../../widgets/shared" as Glassy
import "../../widgets/packages/media/contents/ui/components" as Media

Rectangle {
    width: 220; height: 220
    color: "#202020"
    Glassy.WidgetColors { id: colors }
    Media.AlbumCoverCarousel {
        id: card
        width: 200; height: 200
        colors: colors
        albumArt: ""
    }
    TestCase {
        name: "MediaGlassyFallback"
        when: windowShown
        function test_empty_art_does_not_paint_an_opaque_card() {
            waitForRendering(card)
            const image = grabImage(card)
            // grabImage captures the composed window region, not a standalone
            // transparent FBO. Compare the surface over the known backdrop.
            const expected = Math.round((colors.background.r * 255 + 32) / 2)
            verify(Math.abs(image.red(30, 30) - expected) <= 2,
                   "Expected blended red " + expected + ", got " + image.red(30, 30))
            compare(image.red(0, 0), 32)
        }
    }
}

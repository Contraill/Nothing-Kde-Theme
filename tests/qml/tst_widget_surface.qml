import QtQuick
import QtTest
import org.kde.kirigami as Kirigami
import "../../widgets/shared" as Glassy

Item {
    width: 240; height: 160
    Glassy.GlassySurface {
        id: surface
        width: 200; height: 120
        Text { id: label; text: "Opaque content"; color: surface.foregroundColor }
    }
    Glassy.WidgetColors { id: colors }
    Item {
        id: paletteFixture
        property color background: "#e9e7df"
        property color foreground: "#292c36"
        Kirigami.Theme.inherit: false
        Kirigami.Theme.backgroundColor: background
        Kirigami.Theme.textColor: foreground
        Glassy.GlassySurface { id: automatic; width: 20; height: 20 }
    }
    TestCase {
        name: "GlassyWidgetSurface"
        when: windowShown
        function test_palette_data() {
            return [{tag: "light", bg: "#edeae2", fg: "#282725"},
                    {tag: "dark", bg: "#242735", fg: "#efeff5"}]
        }
        function test_palette(data) {
            surface.backgroundColor = data.bg
            surface.foregroundColor = data.fg
            verify(Math.abs(surface.color.a - 0.5) < 0.005)
            compare(surface.color.r, surface.backgroundColor.r)
            compare(surface.color.g, surface.backgroundColor.g)
            compare(surface.color.b, surface.backgroundColor.b)
            compare(surface.border.width, 1)
            verify(Math.abs(surface.border.color.a - 0.12) < 0.005)
            compare(surface.border.color.r, surface.foregroundColor.r)
            compare(surface.opacity, 1)
            compare(label.opacity, 1)
            compare(label.color.a, 1)
        }
        function test_radius_and_resize() {
            surface.cornerRadius = 20
            surface.width = 200; surface.height = 120
            compare(surface.radius, 20)
            surface.height = 12; compare(surface.radius, 6)
            surface.height = 120; surface.cornerRadius = 0
            compare(surface.radius, 0)
            surface.cornerRadius = 100; compare(surface.radius, 60)
            surface.cornerRadius = 20
        }
        function test_accent_does_not_tint_surface_or_text() {
            colors.themeMode = 2
            const bg = colors.background, fg = colors.textPrimary
            colors.useSystemAccent = !colors.useSystemAccent
            compare(colors.background, bg); compare(colors.textPrimary, fg)
            compare(bg, colors.paletteBackground); compare(fg, colors.paletteText)
            compare(colors.textSecondary.a, 1)
        }
        function test_explicit_mode_preserves_palette_pair() {
            colors.themeMode = 0
            compare(colors.isLight, false)
            colors.themeMode = 1
            compare(colors.isLight, true)
            colors.themeMode = 2
            compare(colors.background, colors.paletteBackground)
        }
        function test_live_inherited_palette() {
            for (const pair of [["#e9e7df", "#292c36"], ["#292c36", "#e9e7df"], ["#e9e7df", "#292c36"]]) {
                paletteFixture.background = pair[0]
                paletteFixture.foreground = pair[1]
                compare(automatic.backgroundColor, paletteFixture.background)
                compare(automatic.foregroundColor, paletteFixture.foreground)
                compare(automatic.color.r, paletteFixture.background.r)
                compare(automatic.border.color.r, paletteFixture.foreground.r)
            }
        }
    }
}

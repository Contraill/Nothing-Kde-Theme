// SPDX-License-Identifier: GPL-3.0-or-later
pragma Singleton

import QtQuick
import org.kde.kirigami as Kirigami
import "."

// Colours, type, shapes and motion for the island and dock. Five base
// colours come from Cfg, which the panel binds to the light or dark palette;
// the other tones are mixed from them. The accent is KDE's own.
QtObject {
    function mix(from, to, amount) {
        return Qt.rgba(from.r + (to.r - from.r) * amount, from.g + (to.g - from.g) * amount, from.b + (to.b - from.b) * amount, 1);
    }
    function luminance(c) {
        return 0.299 * c.r + 0.587 * c.g + 0.114 * c.b;
    }

    // Cards on the island's background, then three raised tones for chips and tracks.
    readonly property color surface: Cfg.cardColor
    readonly property color surfaceAlt: mix(surface, fg, 0.045)
    readonly property color surfaceHigh: mix(surface, fg, 0.098)
    readonly property color surfaceTop: mix(surface, fg, 0.143)

    readonly property color fg: Cfg.textColor
    readonly property color fgDim: mix(fg, Cfg.backgroundColor, 0.396)
    readonly property color fgFaint: mix(fg, Cfg.backgroundColor, 0.694)
    readonly property color outline: mix(Cfg.backgroundColor, fg, 0.165)

    // Active tiles are filled with the inverted colour.
    readonly property color inverted: Cfg.invertedColor
    readonly property color invertedFg: luminance(inverted) > 0.5 ? "#000000" : "#FFFFFF"
    readonly property color alert: Cfg.alertColor
    // DecorationFocus is the accent itself; highlightColor is the darker
    // selection tone (the accent blended into the background).
    readonly property color primary: Kirigami.Theme.focusColor

    readonly property FontLoader uiFace: FontLoader { source: Qt.resolvedUrl("../fonts/SpaceGrotesk.ttf") }
    readonly property FontLoader dotFace: FontLoader { source: Qt.resolvedUrl("../fonts/NothingDots.ttf") }
    readonly property FontLoader iconFace: FontLoader { source: Qt.resolvedUrl("../fonts/MaterialSymbolsRounded.ttf") }
    // Never an empty family: labels keep a font while the bundled ones load,
    // or are registered again after a system font-cache change.
    readonly property string font: Cfg.uiFont || (uiFace.status === FontLoader.Ready && uiFace.name.length ? uiFace.name : Kirigami.Theme.defaultFont.family)
    readonly property string fontDots: Cfg.dotFont || (dotFace.status === FontLoader.Ready && dotFace.name.length ? dotFace.name : font)
    readonly property string fontIcons: iconFace.name

    // Pixel sizes: the expanded clock, its seconds, then body and label text.
    readonly property int displayLarge: 40
    readonly property int displaySmall: 22
    readonly property int bodyMedium: 13
    readonly property int bodySmall: 12
    readonly property int labelMedium: 11
    readonly property int labelSmall: 10
    readonly property real labelSpacing: 1.2

    readonly property int shapeSm: 10
    readonly property int shapeMd: 14
    readonly property int shapeLg: 18
    readonly property int expandedRadius: 26

    // Cubic Bézier curves for Easing.Bezier; the second settles more gently.
    readonly property var emphasized: [0.2, 0.0, 0.0, 1.0, 1.0, 1.0]
    readonly property var emphasizedDecel: [0.05, 0.7, 0.1, 1.0, 1.0, 1.0]
    readonly property int durShort: 180
    readonly property int durMedium: 280
    readonly property int durLong: 380
    readonly property real stateHover: 0.10

    readonly property int collapsedHeight: 36
    readonly property int collapsedWidth: 460
    readonly property int expandedWidth: 580
    readonly property int notifStrip: 62
}

pragma Singleton

import QtQuick
import org.kde.kirigami as Kirigami
import "."
QtObject {
    readonly property color bg: Cfg.colorFondo         // fondo de la isla
    readonly property color surface: Cfg.colorTarjeta  // tarjetas sobre el fondo
    readonly property color surfaceAlt: mezcla(surface, fg, 0.045)
    readonly property color surfaceHigh: mezcla(surface, fg, 0.098)
    readonly property color surfaceTop: mezcla(surface, fg, 0.143)  // tracks, bordes rellenos

    readonly property color inverted: Cfg.colorInvertida
    readonly property color invertedFg: brillo(inverted) > 0.5 ? "#000000" : "#FFFFFF"

    readonly property color fg: Cfg.colorTexto
    readonly property color fgDim: mezcla(fg, bg, 0.396)
    readonly property color fgFaint: mezcla(fg, bg, 0.694)
    readonly property color outline: mezcla(bg, fg, 0.165)
    readonly property color alert: Cfg.colorAlerta
    function mezcla(a, b, t) {
        return Qt.rgba(a.r + (b.r - a.r) * t, a.g + (b.g - a.g) * t, a.b + (b.b - a.b) * t, 1);
    }

    function brillo(c) {
        return 0.299 * c.r + 0.587 * c.g + 0.114 * c.b;
    }
    // DecorationFocus is KDE's accent itself; highlightColor is the selection tone
    // (accent blended into the background), which reads darker in dark mode.
    readonly property color primary: Kirigami.Theme.focusColor
    readonly property color primaryFg: invertedFg
    readonly property color secondary: fgDim
    readonly property color tertiary: fgDim
    readonly property color error: alert
    readonly property color fgVariant: fgDim
    readonly property color outlineVariant: outline
    readonly property color container: surface
    readonly property color containerLow: surface
    readonly property color containerHigh: surfaceAlt
    readonly property color containerHighest: surfaceHigh
    readonly property color primaryContainer: surfaceAlt
    readonly property color primaryContainerFg: fg
    readonly property FontLoader cargaUi: FontLoader {
        source: Qt.resolvedUrl("../fonts/SpaceGrotesk.ttf")
    }
    readonly property FontLoader cargaNumeros: FontLoader {
        source: Qt.resolvedUrl("../fonts/ndot-47-inspired-by-nothing.otf")
    }
    readonly property FontLoader cargaIconos: FontLoader {
        source: Qt.resolvedUrl("../fonts/MaterialSymbolsRounded.ttf")
    }

    // Do not bind labels to an empty family while bundled fonts are loading
    // or being re-registered after a system font-cache change.
    readonly property string font: Cfg.fuenteUi || (cargaUi.status === FontLoader.Ready && cargaUi.name.length ? cargaUi.name : Kirigami.Theme.defaultFont.family)
    readonly property string fontDots: Cfg.fuenteNumeros || (cargaNumeros.status === FontLoader.Ready && cargaNumeros.name.length ? cargaNumeros.name : font)
    readonly property string fontIcons: cargaIconos.name

    readonly property int displayLarge: 40   // reloj del panel
    readonly property int displaySmall: 22
    readonly property int titleMedium: 16
    readonly property int titleSmall: 14
    readonly property int bodyMedium: 13
    readonly property int bodySmall: 12
    readonly property int labelMedium: 11
    readonly property int labelSmall: 10
    readonly property real labelSpacing: 1.2
    readonly property int shapeXs: 6
    readonly property int shapeSm: 10
    readonly property int shapeMd: 14
    readonly property int shapeLg: 18
    readonly property int shapeXl: 26
    readonly property var emphasized: [0.2, 0.0, 0.0, 1.0, 1.0, 1.0]
    readonly property var emphasizedDecel: [0.05, 0.7, 0.1, 1.0, 1.0, 1.0]
    readonly property var standard: [0.2, 0.0, 0.0, 1.0, 1.0, 1.0]

    readonly property int durShort: 180
    readonly property int durMedium: 280
    readonly property int durLong: 380
    readonly property real stateHover: 0.10
    readonly property real statePressed: 0.16
    readonly property int collapsedHeight: 36
    readonly property int expandedHeight: 502
    readonly property int collapsedWidth: 460
    readonly property int expandedWidth: 580
    readonly property int notifStrip: 62
    readonly property int expandedRadius: shapeXl
    readonly property int topGap: 0
}

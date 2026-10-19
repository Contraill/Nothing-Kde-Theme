// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import "components"
import "matrix.js" as Matrix

// A round dot matrix: your drawing, a clock, an animation, or a picture.
PlasmoidItem {
    id: root
    preferredRepresentation: fullRepresentation
    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground

    NothingColors {
        id: nColors
        themeMode: Plasmoid.configuration.themeMode
        useSystemAccent: Plasmoid.configuration.useSystemAccent
        monochrome: Plasmoid.configuration.monochrome
    }

    // 0 drawing, 1 clock, 2 pulse, 3 radar, 4 rain, 5 life, 6 picture.
    readonly property int variant: Plasmoid.configuration.widgetVariant
    readonly property bool animated: variant >= 1 && variant <= 5
    // KDE's region settings decide: a 12-hour format has AM/PM in it.
    readonly property bool clock24: !/a/i.test(Qt.locale().timeFormat(Locale.ShortFormat).replace(/'[^']*'/g, ""))
    readonly property url picture: {
        const path = Plasmoid.configuration.picture;
        return variant !== 6 || !path ? "" : path.startsWith("/") ? "file://" + path : path;
    }

    property var frame: Matrix.empty()
    property var cells: null
    property int generation: 0
    Timer {
        interval: root.variant === 1 ? 1000 : root.variant === 5 ? 240 : 50
        running: root.animated
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            const t = Date.now() / 1000;
            switch (root.variant) {
            case 1: root.frame = Matrix.clock(new Date(), root.clock24); break;
            case 2: root.frame = Matrix.pulse(t); break;
            case 3: root.frame = Matrix.radar(t); break;
            case 4: root.frame = Matrix.rain(t); break;
            case 5: {
                // A new game when this one settles or has run long.
                const next = Matrix.life(root.generation > 160 ? null : root.cells);
                root.generation = next.join() === String(root.cells) || root.generation > 160 ? 0 : root.generation + 1;
                root.cells = next;
                root.frame = next;
                break;
            }
            }
        }
    }

    fullRepresentation: GlyphMatrix {
        Layout.preferredWidth: 220
        Layout.preferredHeight: 220
        Layout.minimumWidth: 120
        Layout.minimumHeight: 120
        colors: nColors
        transparent: Plasmoid.configuration.transparent
        // Without a picture chosen, the picture style shows the drawing.
        frame: root.variant === 0 || (root.variant === 6 && !root.picture.toString()) ? Matrix.fromDrawing(Plasmoid.configuration.drawing) : root.frame
        picture: root.picture
    }
}

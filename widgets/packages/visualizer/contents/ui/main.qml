// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtQuick.Layouts
import QtQuick.Window
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.private.volume as PA
import "../../../../shared" as Glassy
import "components"
import "everything"

// Bands that move with what is playing (EveryThing-UI's visualizers).
// shortcut: Plasma's audio bindings give the output's loudness, not a spectrum, so the bands are that level shaped and set in motion per band; a real spectrum needs an FFT of the monitor stream (for example through cava).
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

    readonly property int variant: Plasmoid.configuration.widgetVariant
    readonly property string layout: ["circle", "bars", "pill"][variant] ?? "circle"
    // 3 to 7: one light of a glyph interface.
    readonly property bool glyph: variant >= 3
    readonly property string glyphShape: ["ring", "arc", "strip", "line", "dot"][variant - 3] ?? "ring"
    readonly property int bands: layout === "circle" ? 20 : layout === "bars" ? 25 : 11

    // The model connects to PulseAudio; the monitor reads the output's peak.
    readonly property PA.SinkModel sinks: PA.SinkModel {}
    PA.VolumeMonitor {
        id: monitor
        target: PA.PreferredDevice.sink
    }

    property var levels: []
    property real phase: 0
    // The five glyph zones. Their motion runs on the wall clock, so every
    // glyph widget computes the same light from the same sound: placed side
    // by side they play as one interface, each zone its own part of it.
    property var zones: [0, 0, 0, 0, 0]
    // Auto: the zone from where the widget sits across the screen.
    property int autoZone: 0
    readonly property int zone: Plasmoid.configuration.glyphZone > 0 ? Plasmoid.configuration.glyphZone - 1 : autoZone
    Timer {
        interval: 2000
        repeat: true
        running: root.glyph && Plasmoid.configuration.glyphZone === 0
        triggeredOnStart: true
        onTriggered: {
            const x = root.mapToGlobal(root.width / 2, 0).x;
            root.autoZone = Math.max(0, Math.min(4, Math.floor((x - Screen.virtualX) / Math.max(1, Screen.width) * 5)));
        }
    }
    function zoneLight(n) {
        return root.zones[(root.zone + n) % 5] ?? 0;
    }
    // 25 frames a second while something sounds, then until the bands settle.
    Timer {
        interval: 40
        repeat: true
        running: monitor.available && (monitor.volume > 0.005 || root.levels.some(v => v > 0.01) || root.zones.some(v => v > 0.01))
        onTriggered: {
            root.phase += 0.04;
            const level = Math.min(1, monitor.volume * Plasmoid.configuration.sensitivity / 100);
            if (root.glyph) {
                const t = Date.now() / 1000;
                root.zones = root.zones.map((before, z) => {
                    // Zone 1 holds the beat; the higher zones flicker faster.
                    const motion = 0.5 + 0.5 * Math.sin(t * (2.1 + z * 1.6) + z * 1.9) * Math.sin(t * (1.1 + z * 0.5) + z);
                    const target = level * (z === 0 ? 0.6 + 0.4 * motion : 0.25 + 0.75 * motion);
                    return target > before ? before + (target - before) * 0.7 : before + (target - before) * 0.2;
                });
                return;
            }
            const out = [];
            for (let i = 0; i < root.bands; ++i) {
                const shape = 0.55 + 0.45 * Math.sin(Math.PI * (i + 0.5) / root.bands);
                const motion = 0.5 + 0.5 * Math.sin(root.phase * (5 + i % 7) + i * 1.7) * Math.sin(root.phase * 3.1 + i * 0.6);
                const target = level * shape * (0.35 + 0.65 * motion);
                const before = root.levels[i] ?? 0;
                // Rise fast, fall slower, like Rainmeter's FFT attack and decay.
                out.push(target > before ? before + (target - before) * 0.6 : before + (target - before) * 0.25);
            }
            root.levels = out;
        }
    }

    fullRepresentation: Item {
        Layout.preferredWidth: root.glyph ? (root.glyphShape === "strip" ? 115 : 200) : root.layout === "bars" ? 400 : 200
        Layout.preferredHeight: root.glyph ? 200 : root.layout === "circle" ? 200 : 115
        Layout.minimumWidth: root.glyph ? 60 : 150
        Layout.minimumHeight: 60
        GlyphLight {
            anchors.fill: parent
            visible: root.glyph
            colors: nColors
            shape: root.glyphShape
            transparent: Plasmoid.configuration.transparent
            light: n => root.zoneLight(n)
        }
        Loader {
            anchors.fill: parent
            active: !root.glyph
            sourceComponent: bandsView
        }
    }
    Component {
        id: bandsView
        EveryVisualizer {
            colors: nColors
            layout: root.layout
            levels: root.levels
            transparent: Plasmoid.configuration.transparent
        }
    }
}

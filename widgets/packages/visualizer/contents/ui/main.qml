// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtQuick.Layouts
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
    readonly property int bands: layout === "circle" ? 20 : layout === "bars" ? 25 : 11

    // The model connects to PulseAudio; the monitor reads the output's peak.
    readonly property PA.SinkModel sinks: PA.SinkModel {}
    PA.VolumeMonitor {
        id: monitor
        target: PA.PreferredDevice.sink
    }

    property var levels: []
    property real phase: 0
    // 25 frames a second while something sounds, then until the bands settle.
    Timer {
        interval: 40
        repeat: true
        running: monitor.available && (monitor.volume > 0.005 || root.levels.some(v => v > 0.01))
        onTriggered: {
            root.phase += 0.04;
            const level = Math.min(1, monitor.volume * Plasmoid.configuration.sensitivity / 100);
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

    fullRepresentation: EveryVisualizer {
        Layout.preferredWidth: root.layout === "bars" ? 400 : 200
        Layout.preferredHeight: root.layout === "circle" ? 200 : 115
        Layout.minimumWidth: 150
        Layout.minimumHeight: 60
        colors: nColors
        layout: root.layout
        levels: root.levels
    }
}

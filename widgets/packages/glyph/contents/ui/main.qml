// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.private.volume as PA
import "components"

// One glyph light that flashes on the beat of what is playing. Every glyph
// widget reads the same sound and steps the same way on each sample, so
// several play together: each has a zone, a step of loudness to light at,
// and the louder the beat the more zones flash.
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

    readonly property string shape: ["ring", "arc", "strip", "line", "dot"][Plasmoid.configuration.widgetVariant] ?? "ring"

    // Auto: the glyph widgets of this desktop numbered in the order they were added.
    readonly property int autoZone: {
        const ids = (Plasmoid.containment?.applets ?? []).filter(a => a.pluginName === Plasmoid.pluginName).map(a => a.id).sort((a, b) => a - b);
        return Math.max(0, ids.indexOf(Plasmoid.id)) % 5;
    }
    readonly property int zone: Plasmoid.configuration.glyphZone > 0 ? Plasmoid.configuration.glyphZone - 1 : autoZone
    // The loudness a zone lights at: zone 1 on every beat, zone 5 on the strongest.
    readonly property real threshold: 0.25 + zone * 0.15

    // The model connects to PulseAudio; the monitor reads the output's peak.
    readonly property PA.SinkModel sinks: PA.SinkModel {}
    PA.VolumeMonitor {
        id: monitor
        target: PA.PreferredDevice.sink
    }

    // The beat: how far a sample stands over the song's own running loudness,
    // and how fast it rose, so compressed music still shows its hits. A hit
    // flashes at once and fades in a fifth of a second.
    property real mean: 0
    property real spread: 0.05
    property real previous: 0
    property real hit: 0
    property double lastSample: 0
    function step(level) {
        mean += (level - mean) * 0.04;
        spread += (Math.abs(level - mean) - spread) * 0.05;
        const above = Math.max(0, level - mean) / Math.max(0.02, 2.2 * spread);
        const rise = Math.max(0, level - previous) / Math.max(0.02, 3 * spread);
        previous = level;
        const gain = Plasmoid.configuration.sensitivity / 100;
        hit = Math.max(hit * 0.62, Math.min(1, (above * 0.7 + rise * 0.6) * gain));
    }
    // Every widget steps on the same samples, so they stay in time.
    Connections {
        target: monitor
        function onVolumeChanged() {
            root.lastSample = Date.now();
            root.step(monitor.volume);
        }
    }
    // A steady sample sends no signal: keep fading meanwhile.
    Timer {
        interval: 40
        repeat: true
        running: root.hit > 0.01
        onTriggered: if (Date.now() - root.lastSample > 60) root.step(monitor.volume)
    }

    fullRepresentation: GlyphLight {
        readonly property real side: root.shape === "dot" ? 60 : 160
        Layout.preferredWidth: root.shape === "strip" ? 44 : side
        Layout.preferredHeight: root.shape === "strip" ? 180 : side
        Layout.minimumWidth: 24
        Layout.minimumHeight: 24
        colors: nColors
        shape: root.shape
        transparent: Plasmoid.configuration.transparent
        level: root.hit
        threshold: root.threshold
    }
}

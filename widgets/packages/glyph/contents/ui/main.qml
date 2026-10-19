// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import "components"
import "."

// One glyph light that plays the music with every other glyph widget: they
// share one beat (Beat.qml), so together they put on one show. Soft passages
// glow softly, hits flash sharply: the step from one to the other is the
// point. On each beat the lead moves to the next zone, the louder a hit the
// more zones join it, and the strongest light everything.
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

    // This desktop's glyph widgets in the order they were added: each light's
    // place in the show, however many there are.
    readonly property var glyphs: (Plasmoid.containment?.applets ?? []).filter(a => a.pluginName === Plasmoid.pluginName).map(a => a.id).sort((a, b) => a - b)
    readonly property int count: Math.max(1, glyphs.length)
    readonly property int rank: Math.max(0, glyphs.indexOf(Plasmoid.id))
    // The zone is a tier of loudness, 1 lighting on every hit and 5 on the
    // hardest; Auto spreads the lights over the five tiers by their place.
    readonly property int zone: Plasmoid.configuration.glyphZone > 0 ? Plasmoid.configuration.glyphZone - 1 : Math.min(4, Math.floor(rank * 5 / count))

    // Whether this light leads on beat `b`. Every eight beats the walk
    // changes, so many lights neither crowd nor repeat: forward along the
    // lights, back, every other one, then out from the middle.
    function leads(b) {
        const n = count;
        switch (Math.floor(b / 8) % 4) {
        case 0: return b % n === rank;
        case 1: return n - 1 - b % n === rank;
        case 2: return n > 2 ? rank % 2 === b % 2 && Math.floor(rank / 2) % 2 === Math.floor(b / 2) % 2 : b % n === rank;
        default: {
            const middle = (n - 1) / 2;
            return Math.round(Math.abs(rank - middle) - (middle % 1)) === b % Math.ceil(n / 2);
        }
        }
    }

    Component.onCompleted: Beat.users += 1
    Component.onDestruction: Beat.users -= 1

    readonly property real gain: Plasmoid.configuration.sensitivity / 100
    readonly property real hit: Math.min(1, Beat.hit * gain)
    readonly property real body: Math.min(1, Beat.body * gain)
    readonly property double since: Beat.now - Beat.beatTime

    // The light of part `n` of this widget (the ring has four; the rest one).
    function light(n) {
        // The ring's further parts need harder hits: all four only on the hardest.
        const step = 0.30 + zone * 0.13 + n * 0.2;
        // Soft: the music's body, a gentle glow well under a flash.
        const soft = Math.max(0, Math.min(1, (body - zone * 0.12) / 0.6)) * 0.38;
        // Sharp: the hit over this zone's step.
        const sharp = Math.max(0, Math.min(1, (hit - step) / 0.1));
        // In the ring the lead's flash turns from part to part.
        const lead = leads(Beat.beats) && (shape !== "ring" || (Beat.beats + rank) % 4 === n);
        const chase = lead ? Beat.fade(since, 300) * Math.min(1, Beat.beatStrength * gain * 1.1) : 0;
        // The hardest hits, a few a minute, light everything at once.
        const blast = Beat.beatStrength * gain > 1.25 ? Beat.fade(since, 170) : 0;
        return Math.max(soft, sharp, chase, blast);
    }

    fullRepresentation: GlyphLight {
        readonly property real side: root.shape === "dot" ? 72 : 180
        Layout.preferredWidth: root.shape === "strip" ? 64 : side
        Layout.preferredHeight: root.shape === "strip" ? 200 : side
        Layout.minimumWidth: 24
        Layout.minimumHeight: 24
        colors: nColors
        shape: root.shape
        transparent: Plasmoid.configuration.transparent
        light: n => root.light(n)
        // The strip, and the line and arc as a progress, fill with the beat.
        fill: Math.max(root.hit, root.body * 0.6)
        progress: Plasmoid.configuration.progress
        sweep: Plasmoid.configuration.arcSweep
        mirror: Plasmoid.configuration.mirror
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import "components"
import "."

// One glyph light that plays the music with every other glyph widget: they
// share one beat (Beat.qml), so together they put on one show. Soft passages
// glow softly, beats flash. Each beat is ranked against the song's recent
// ones, so the steps a light shows (parts of the ring, dots of the dot ring,
// segments of the strip, zones across the lights) come up about equally
// often and read clearly; the lead walks the lights from beat to beat.
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

    readonly property string shape: ["ring", "arc", "strip", "line", "dot", "corner", "dots"][Plasmoid.configuration.widgetVariant] ?? "ring"

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
    // Turning the strip turns its widget: Plasma only ever grows a widget to
    // what it prefers, so swap the desktop's box for it, about its centre,
    // and have the desktop place it and keep it.
    function turn() {
        const box = root.parent;
        if (shape !== "strip" || !box || box.layout === undefined) return;
        const sideways = Plasmoid.configuration.sideways;
        if (box.width !== box.height && (box.width > box.height) === sideways) return;
        // The long side stays; a square box narrows to a strip's proportions.
        const long = Math.max(box.width, box.height);
        const short = Math.min(box.width, box.height, Math.max(48, Math.round(long / 3)));
        const cx = box.x + box.width / 2, cy = box.y + box.height / 2;
        box.width = sideways ? long : short;
        box.height = sideways ? short : long;
        box.x = Math.round(cx - box.width / 2);
        box.y = Math.round(cy - box.height / 2);
        box.layout.positionItem?.(box);
        box.layout.save?.();
    }
    Connections {
        target: Plasmoid.configuration
        function onSidewaysChanged() { root.turn() }
    }
    Component.onDestruction: Beat.users -= 1

    readonly property real gain: Plasmoid.configuration.sensitivity / 100
    readonly property real body: Math.min(1, Beat.body * gain)
    readonly property double since: Beat.now - Beat.beatTime

    // A beat's place among the song's last 32 beats, so the steps a light
    // shows come up about equally often: the ring lights one to four parts,
    // the dot ring up to twelve dots, the tiers one zone to all five.
    readonly property real strength: Math.min(1, Beat.beatRank * gain)
    readonly property real hold: Beat.fade(since, 350)

    // The light of part `n` of this widget: the ring has four, the dot ring
    // twelve, the rest one.
    function light(n) {
        // Soft: the music's body, a gentle glow well under a flash.
        let soft = Math.max(0, Math.min(1, (body - zone * 0.12) / 0.6)) * 0.38;
        let beat = 0;
        if (shape === "ring") {
            // As many parts as the beat ranks, from the lead part round,
            // drawing back one by one as it fades.
            const lead = (Beat.beats + rank) % 4;
            const lit = Math.ceil(strength * 4 * hold - 0.001);
            beat = (n - lead + 4) % 4 < lit ? 1 : 0;
        } else if (shape === "dots") {
            // The dots turn softly on their own and spread from the lead on a beat.
            const turn = (Beat.travel * 4 + rank * 3) % 12;
            const near = Math.min(Math.abs(n - turn), 12 - Math.abs(n - turn));
            soft = Math.max(soft * 0.6, Math.max(0, 1 - near / 2.5) * Math.min(1, 0.25 + body) * 0.5);
            const lead = (Beat.beats * 5 + rank * 3) % 12;
            const d = Math.min(Math.abs(n - lead), 12 - Math.abs(n - lead));
            const lit = Math.round(strength * 12 * Beat.fade(since, 400));
            beat = lit > 0 && d <= (lit - 1) / 2 ? 1 : 0;
        } else {
            // A tier of the beat: zone 1 on every beat, zone 5 on the top fifth;
            // the lead, walking the lights, flashes whatever the tier.
            const tier = strength >= zone / 5 ? Beat.fade(since, 300) : 0;
            const lead = leads(Beat.beats) ? Beat.fade(since, 300) * (0.5 + 0.5 * strength) : 0;
            beat = Math.max(tier, lead);
        }
        // The hardest beats, the top few in a song, light everything at once.
        const blast = Beat.beatRank > 0.93 ? Beat.fade(since, 170) : 0;
        return Math.max(soft, beat, blast);
    }

    fullRepresentation: GlyphLight {
        readonly property real side: root.shape === "dot" ? 72 : 180
        // The lines' default proportions; resize to stretch them.
        // On its side the strip asks Plasma for a wide, low box, and lies down in it.
        readonly property size stretched: root.shape === "strip" ? (Plasmoid.configuration.sideways ? Qt.size(200, 64) : Qt.size(64, 200)) : Qt.size(side, side)
        // Plasma grows a desktop widget to what it prefers whenever that is
        // set, so at every login: an upright line came back wide, and slanted.
        // Once placed, the light prefers no more than the box it was given.
        // shortcut: a box left at the desktop's default size still grows, as it cannot be told from a new one.
        readonly property Item box: root.parent?.layout ? root.parent : null
        readonly property bool placed: box !== null && (box.width !== box.layout.defaultItemWidth || box.height !== box.layout.defaultItemHeight)
        Layout.preferredWidth: placed ? Math.min(stretched.width, box.width) : stretched.width
        Layout.preferredHeight: placed ? Math.min(stretched.height, box.height) : stretched.height
        Layout.minimumWidth: 24
        Layout.minimumHeight: 24
        colors: nColors
        shape: root.shape
        transparent: Plasmoid.configuration.transparent
        light: n => root.light(n)
        // The strip, and the line, arc and corner as a progress, rise to the
        // beat's rank and fall back, with the moment's level in between.
        fill: Math.max(Math.min(1, Beat.level * root.gain) * 0.85, root.strength * Beat.fade(root.since, 450))
        progress: Plasmoid.configuration.progress
        sweep: Plasmoid.configuration.arcSweep
        mirror: Plasmoid.configuration.mirror
        corner: Plasmoid.configuration.corner
        segments: Plasmoid.configuration.segments
    }
}

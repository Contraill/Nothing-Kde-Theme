// SPDX-License-Identifier: GPL-3.0-or-later
pragma Singleton
import QtQuick
import org.kde.plasma.private.volume as PA

// The one beat every glyph widget plays to. Plasma runs all widgets in one
// QML engine, so this is a single object: one sound monitor, one beat
// counter, and every light reads the same moment.
QtObject {
    id: beat
    // Widgets showing a light; the monitor runs only while there are some.
    property int users: 0

    readonly property PA.SinkModel sinks: PA.SinkModel {}
    readonly property PA.VolumeMonitor monitor: PA.VolumeMonitor {
        target: beat.users > 0 ? PA.PreferredDevice.sink : null
        onTargetChanged: beat.heard = 0
    }

    // How far a sample stands over the song's own running loudness, and how
    // fast it rose, so compressed music still shows its hits; `hit` flashes
    // at once and fades in a fifth of a second, `body` follows the loudness
    // more slowly for what lingers between the hits.
    property real mean: 0
    property real spread: 0.05
    property real previous: 0
    property real hit: 0
    property real body: 0
    // `level` is the hit ranked against this song's last eight seconds of
    // hits, so a meter's steps come up about equally often, whatever the
    // song or the volume; `beatRank` ranks a beat against the last 32.
    property real level: 0
    property real beatRank: 0
    property var recentHits: []
    property var recentBeats: []
    // Until a song has given a dozen, typical hits stand in.
    readonly property var typical: [0.55, 0.62, 0.7, 0.78, 0.86, 0.95, 1.05, 1.15, 1.3, 1.6]
    function rank(list, value) {
        const all = list.length < 12 ? list.concat(typical) : list;
        let below = 0;
        for (const v of all) if (v <= value) ++below;
        return below / all.length;
    }
    // A beat is a hit that rises out of a quiet moment.
    property int beats: 0
    property double beatTime: 0
    property real beatStrength: 0
    property bool armed: true
    // The clock the lights fade by; ticks while anything is lit.
    property double now: 0
    property double lastSample: 0
    // How far the dot ring has turned: a shared distance, faster the more
    // the music drives.
    property real travel: 0
    property double lastStep: 0

    // Samples heard since the sound came on: the first second settles the
    // running loudness as a plain average, so a song's start is not one flash.
    property int heard: 0
    function step(sample) {
        if (heard === 0) {
            if (sample < 0.01) return;
            mean = sample;
            previous = sample;
            spread = 0;
        }
        heard = Math.min(heard + 1, 1000);
        mean += (sample - mean) * Math.max(0.04, 1 / heard);
        spread += (Math.abs(sample - mean) - spread) * Math.max(0.05, 1 / heard);
        const above = Math.max(0, sample - mean) / Math.max(0.02, 2.2 * spread);
        const rise = Math.max(0, sample - previous) / Math.max(0.02, 3 * spread);
        previous = sample;
        const raw = above * 0.7 + rise * 0.6;
        hit = Math.max(hit * 0.62, Math.min(1, raw));
        // 25 samples a second: 200 are eight seconds of the song.
        if (raw > 0.05) {
            recentHits.push(raw);
            if (recentHits.length > 200) recentHits.shift();
        }
        beat.level = Math.max(beat.level * 0.72, raw > 0.05 ? rank(recentHits, raw) : 0);
        body += (Math.min(1, above) - body) * (above > body ? 0.35 : 0.08);
        now = Date.now();
        advance();
        if (armed && hit > 0.55 && now - beatTime > 110) {
            beats += 1;
            beatTime = now;
            // Unclipped: most beats land near 0.6 to 1.3, the hardest well over.
            beatStrength = raw;
            recentBeats.push(raw);
            if (recentBeats.length > 32) recentBeats.shift();
            beatRank = rank(recentBeats, raw);
            armed = false;
        } else if (hit < 0.35) {
            armed = true;
        }
    }
    function advance() {
        const dt = Math.min(0.1, Math.max(0, (now - lastStep) / 1000));
        lastStep = now;
        travel += dt * (0.15 + 0.5 * body + 1.6 * hit);
    }
    // A flash that started at `since` milliseconds ago, over `length`.
    function fade(since, length) {
        return since < 0 ? 0 : Math.max(0, 1 - since / length);
    }

    readonly property Connections samples: Connections {
        target: beat.monitor
        function onVolumeChanged() {
            beat.lastSample = Date.now();
            beat.step(beat.monitor.volume);
        }
    }
    // A steady sample sends no signal: keep the lights fading meanwhile.
    readonly property Timer ticker: Timer {
        interval: 30
        repeat: true
        running: beat.users > 0 && (beat.hit > 0.01 || beat.body > 0.01 || beat.level > 0.01 || Date.now() - beat.beatTime < 600)
        onTriggered: {
            if (Date.now() - beat.lastSample > 50) beat.step(beat.monitor.volume);
            else { beat.now = Date.now(); beat.advance(); }
        }
    }
}

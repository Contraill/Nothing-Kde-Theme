// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import "../../../../../shared" as Glassy

// EveryThing-UI's batteries (Prince-1652, MIT): a circle ringed with the
// charge around the dotted bolt, or a pill with a small ring.
Glassy.EveryFrame {
    id: f
    property bool round: true
    property string family
    property int percent: 0
    property bool charging: false
    designWidth: 190
    designHeight: round ? 190 : 95
    card: round ? "circle" : "pill"

    Glassy.EveryRing {
        s: f.s
        cx: f.round ? 95 : 47.5
        cy: f.round ? 95 : 47.5
        inner: f.round ? 85 : 28
        outer: f.round ? 95 : 35
        value: f.percent / 100
        trackColor: f.track
        fillColor: f.percent <= 15 && !f.charging ? f.colors.error : f.colors.accent
    }
    // The bolt: 27 dots on a 6 px grid (4 px in the pill), centred on x 95 / 47.5.
    Glassy.DotGlyph {
        readonly property real pitch: f.round ? 6 : 4
        name: "bolt-dots"
        x: ((f.round ? 95 : 47.5) - 3.5 * pitch) * f.s
        y: ((f.round ? 51 : 31.5) - 0.5 * pitch) * f.s
        width: 7 * pitch * f.s
        height: 9 * pitch * f.s
        dotRatio: (f.round ? 5 : 3) / pitch
        color: f.charging ? f.colors.accent : f.colors.textPrimary
    }
    Glassy.EveryText {
        s: f.s
        px: f.round ? 95 : 95
        py: f.round ? 115 : 50
        pt: f.round ? 26 : 20
        align: f.round ? "CenterTop" : "LeftCenter"
        value: f.percent + "%"
        color: f.colors.textPrimary
        font.family: f.family
    }
}

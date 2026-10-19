// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import "../../../../../shared" as Glassy

// EveryThing-UI's mantra (Prince-1652, MIT): an accent dot and a phrase
// that changes every ten seconds. The phrases are the note's lines.
Glassy.EveryFrame {
    id: f
    property string family
    property var phrases: []
    property int index: 0
    designWidth: 390
    designHeight: 95
    card: "pill"

    Timer {
        interval: 10000
        running: f.phrases.length > 1
        repeat: true
        onTriggered: f.index = (f.index + 1) % f.phrases.length
    }
    Rectangle {
        x: 39.5 * f.s; y: 39.5 * f.s; width: 16 * f.s; height: width; radius: width / 2
        color: f.colors.accent
    }
    Glassy.EveryText {
        id: phrase
        s: f.s; px: 80; py: 50; pt: 18; align: "LeftCenter"; upper: true; clipWidth: 290
        value: f.phrases.length ? f.phrases[f.index % f.phrases.length] : ""
        color: f.colors.textPrimary
        font.family: f.family
        Behavior on value {
            SequentialAnimation {
                NumberAnimation { target: phrase; property: "opacity"; to: 0; duration: 180 }
                PropertyAction {}
                NumberAnimation { target: phrase; property: "opacity"; to: 1; duration: 260 }
            }
        }
    }
}

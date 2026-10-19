// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import "../../../../../shared" as Glassy

// EveryThing-UI's pets (Prince-1652, MIT), redrawn as dot-matrix sprites
// (assets/pets/build-pets.py): a cat, dog, hamster or robot peeking over
// the bottom edge of a card, or straight on the wallpaper.
Glassy.EveryFrame {
    id: f
    // Unused; every design takes it so settings previews can pass it.
    property string family
    // "cat", "dog", "hamster" or "robo"
    property string pet: "cat"
    property bool transparent: false
    property bool running: true
    designWidth: 190
    designHeight: 190
    card: transparent ? "none" : "block"

    // From sprites.json: frame size, and where the sprite sits in the original 1280x720 frame.
    readonly property var sheets: ({
        cat: {height: 145, place: [0.0719, 0.0417, 0.8562, 0.9583]},
        dog: {height: 140, place: [0.0563, 0.0264, 0.9039, 0.9736]},
        hamster: {height: 155, place: [0.1133, 0.0847, 0.7586, 0.9153]},
        robo: {height: 195, place: [0.1484, 0.0, 0.6672, 1.0]}
    })
    readonly property var sheet: sheets[pet] ?? sheets.cat
    // The original draws the frame 1.2 times the inner width, its bottom on the inner edge.
    readonly property real frameWidth: 170 * 1.2
    readonly property real frameHeight: frameWidth * 720 / 1280
    readonly property real frameX: transparent ? 0 : 10 - 170 * 0.1
    readonly property real frameY: 190 - 10 - frameHeight

    Item {
        x: (f.transparent ? 0 : 10) * f.s
        y: (f.transparent ? 0 : 10) * f.s
        width: parent.width - 2 * x
        height: parent.height - 2 * y
        clip: !f.transparent
        AnimatedSprite {
            x: (f.frameX + f.sheet.place[0] * f.frameWidth) * f.s - parent.x
            y: (f.frameY + f.sheet.place[1] * f.frameHeight) * f.s - parent.y
            width: f.sheet.place[2] * f.frameWidth * f.s
            height: f.sheet.place[3] * f.frameHeight * f.s
            source: Qt.resolvedUrl("../../sprites/" + f.pet + ".png")
            frameWidth: 230
            frameHeight: f.sheet.height
            frameCount: 80
            frameDuration: 100
            interpolate: false
            running: f.running
            smooth: true
        }
    }
}

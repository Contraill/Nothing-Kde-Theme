// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import "../../../../../shared" as Glassy

// EveryThing-UI's analog clocks (Prince-1652, MIT), on our surface: a circle
// or a rounded square with an accent dot at twelve, a thick hour hand and
// a grey minute hand.
Glassy.EveryFrame {
    id: f
    // Unused; every design takes it so settings previews can pass it.
    property string family
    property bool round: true
    property int hours: 0
    property int minutes: 0
    property int seconds: 0
    card: round ? "circle" : "block"

    Rectangle {
        x: 90 * f.s
        y: 15 * f.s
        width: 10 * f.s
        height: width
        radius: width / 2
        color: f.colors.accent
    }
    // A hand from 8 px behind the centre to `reach`, turned about the centre.
    component Hand: Rectangle {
        id: hand
        property real reach
        property real thickness
        property real turn
        x: (95 - thickness / 2) * f.s
        y: (95 - reach) * f.s
        width: thickness * f.s
        height: (reach + 8) * f.s
        antialiasing: true
        transform: Rotation { origin.x: hand.width / 2; origin.y: 95 * f.s - hand.y; angle: hand.turn }
    }
    Hand {
        reach: 70
        thickness: 6
        turn: (f.minutes + f.seconds / 60) * 6
        color: f.colors.textMuted
    }
    Hand {
        reach: 55
        thickness: 12
        turn: (f.hours % 12 + f.minutes / 60) * 30
        color: f.colors.textPrimary
    }
}

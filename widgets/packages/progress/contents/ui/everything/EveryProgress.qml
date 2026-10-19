// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import "../../../../../shared" as Glassy

// EveryThing-UI's trackers (Prince-1652, MIT): the year's progress and the
// time until midnight, each as a ring block or a ringed circle; the
// countdown block also has a bar through the day.
Glassy.EveryFrame {
    id: f
    // "year" or "countdown"
    property string kind: "year"
    property bool round: false
    property string family
    property date now: new Date()
    property real yearFraction: 0
    property real dayFraction: 0
    property int dayOfYear: 1
    // Whole hours, minutes and seconds left today, as the original counts them.
    readonly property int hoursLeft: 23 - now.getHours()
    readonly property int minutesLeft: 59 - now.getMinutes()
    readonly property int secondsLeft: 59 - now.getSeconds()
    card: round ? "circle" : "block"

    component Label: Glassy.EveryText {
        s: f.s
        color: f.colors.textPrimary
        font.family: f.family
    }

    // The ring: inside the block (58 to 70 around 95,85) or at the edge of the circle.
    Glassy.EveryRing {
        visible: f.kind === "year" || f.round
        s: f.s
        cx: 95; cy: f.round ? 95 : 85
        inner: f.round ? 85 : 58
        outer: f.round ? 95 : 70
        value: f.kind === "year" ? f.yearFraction : f.dayFraction
        trackColor: f.track
        fillColor: f.colors.textPrimary
    }

    // Year
    Label { visible: f.kind === "year"; px: 95; py: f.round ? 75 : 80; pt: 28; align: "CenterCenter"; value: Math.round(f.yearFraction * 100) + "%" }
    Label { visible: f.kind === "year"; px: 95; py: 100; pt: 10; align: "Center"; upper: true; value: i18n("Day %1", f.dayOfYear) }
    Label {
        visible: f.kind === "year"
        px: 95; py: f.round ? 125 : 160; pt: f.round ? 14 : 10; align: "Center"
        value: String(f.now.getFullYear())
        color: f.colors.accent
    }

    // Countdown block
    Label { visible: f.kind === "countdown" && !f.round; px: 95; py: 20; pt: 13; align: "Center"; upper: true; value: i18n("Until midnight"); color: f.colors.accent }
    Label { visible: f.kind === "countdown" && !f.round; px: 95; py: 55; pt: 40; align: "Center"; value: f.hoursLeft + "h" }
    Label {
        visible: f.kind === "countdown" && !f.round
        px: 95; py: 105; pt: 18; align: "Center"
        value: f.minutesLeft + "m " + f.secondsLeft + "s"
    }
    Glassy.EveryBar {
        visible: f.kind === "countdown" && !f.round
        s: f.s; bx: 20; by: 140; bw: 150; bh: 30; radius: 15
        value: f.dayFraction
        trackColor: f.track
        fillColor: f.colors.textPrimary
    }
    // Countdown circle
    Label {
        visible: f.kind === "countdown" && f.round
        px: 95; py: 75; pt: 22; align: "CenterCenter"
        value: f.hoursLeft + "h " + f.minutesLeft + "m"
    }
    Label { visible: f.kind === "countdown" && f.round; px: 95; py: 115; pt: 11; align: "Center"; upper: true; value: i18n("Remaining"); color: f.colors.textSecondary }
}

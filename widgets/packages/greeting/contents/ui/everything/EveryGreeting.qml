// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import "../../../../../shared" as Glassy
import "../../../../../shared/every.js" as Every

// EveryThing-UI's greetings (Prince-1652, MIT): good morning, afternoon or
// evening with the time, as a wide pill or a square.
Glassy.EveryFrame {
    id: f
    property bool square: false
    property string family
    property date now: new Date()
    property bool clock24: true
    // Without the time the greeting sits in the middle.
    property bool showTime: true
    designWidth: square ? 190 : 390
    designHeight: square ? 190 : 95
    card: square ? "block" : "pill"
    readonly property string greeting: {
        const key = Every.greetingKey(now.getHours());
        return key === "GOOD MORNING" ? i18n("Good morning") : key === "GOOD AFTERNOON" ? i18n("Good afternoon") : i18n("Good evening");
    }
    readonly property string hour: Qt.formatTime(now, clock24 ? "HH" : "hh")
    readonly property string minute: Qt.formatTime(now, "mm")

    component Label: Glassy.EveryText {
        s: f.s
        color: f.colors.textPrimary
        font.family: f.family
    }

    // Pill
    Label { visible: !f.square; px: 30; py: f.showTime ? 25 : 47.5; align: f.showTime ? "LeftTop" : "LeftCenter"; pt: 18; upper: true; value: f.greeting; clipWidth: 310 }
    Label { visible: !f.square && f.showTime; px: 30; py: 55; pt: 16; upper: true; value: f.clock24 ? f.hour + ":" + f.minute : Qt.formatTime(f.now, "hh:mm AP") }
    Rectangle {
        visible: !f.square
        x: 352 * f.s; y: 39.5 * f.s; width: 16 * f.s; height: width; radius: width / 2
        color: f.colors.accent
    }
    // Square: the greeting on two lines, the time below.
    Label {
        visible: f.square
        px: 95; py: f.showTime ? 25 : 95; pt: 20; align: f.showTime ? "Center" : "CenterCenter"; upper: true
        value: f.greeting.replace(" ", "\n")
        horizontalAlignment: Text.AlignHCenter
    }
    Label { visible: f.square && f.showTime; px: 55; py: 120; pt: 30; align: "Center"; value: f.hour }
    Label { visible: f.square && f.showTime; px: 95; py: 120; pt: 30; align: "Center"; value: ":"; color: f.colors.accent }
    Label { visible: f.square && f.showTime; px: 135; py: 120; pt: 30; align: "Center"; value: f.minute }
}

// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import "../../../../../shared" as Glassy

// EveryThing-UI's digital clocks (Prince-1652, MIT): hours over minutes in
// a tall pill, side by side in a wide pill with an accent colon, or a square
// with the date, month and weekday below.
Glassy.EveryFrame {
    id: f
    // "vertical", "horizontal" or "square"
    property string layout: "vertical"
    property string family
    property string hour: "00"
    property string minute: "00"
    property date now: new Date()
    designWidth: layout === "vertical" ? 95 : 190
    designHeight: layout === "horizontal" ? 95 : 190
    card: layout === "square" ? "block" : "pill"

    component Label: Glassy.EveryText {
        s: f.s
        color: f.colors.textPrimary
        font.family: f.family
    }
    Label { visible: f.layout === "vertical"; px: 47.5; py: 77; pt: 38; align: "CenterCenter"; value: f.hour }
    Label { visible: f.layout === "vertical"; px: 47.5; py: 129; pt: 38; align: "CenterCenter"; value: f.minute }

    Label { visible: f.layout === "horizontal"; px: 60; py: 54.5; pt: 38; align: "CenterCenter"; value: f.hour }
    Label { visible: f.layout === "horizontal"; px: 95; py: 52; pt: 38; align: "CenterCenter"; value: ":"; color: f.colors.accent }
    Label { visible: f.layout === "horizontal"; px: 130; py: 54.5; pt: 38; align: "CenterCenter"; value: f.minute }

    Label { visible: f.layout === "square"; px: 56; py: 54.5; pt: 44; align: "CenterCenter"; value: f.hour }
    Label { visible: f.layout === "square"; px: 95; py: 52; pt: 44; align: "CenterCenter"; value: ":"; color: f.colors.accent }
    Label { visible: f.layout === "square"; px: 134; py: 54.5; pt: 44; align: "CenterCenter"; value: f.minute }
    Label {
        id: day
        visible: f.layout === "square"
        px: 20; py: 150; pt: 34; align: "LeftBottom"
        value: Qt.formatDate(f.now, "dd")
    }
    // Rainmeter: 8 px right of the date, 10 px above its top.
    Label {
        visible: f.layout === "square"
        px: day.x / f.s + day.width / f.s + 8; py: 150 - 10; pt: 12; align: "LeftBottom"; upper: true
        value: Qt.locale().standaloneMonthName(f.now.getMonth(), Locale.LongFormat)
        color: f.colors.textSecondary
    }
    Label {
        visible: f.layout === "square"
        px: 20; py: 170; pt: 16; align: "LeftBottom"; upper: true
        value: Qt.locale().dayName(f.now.getDay(), Locale.LongFormat)
    }
}

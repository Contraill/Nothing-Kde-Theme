// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import "../../../../../shared" as Glassy

// EveryThing-UI's quick utilities (Prince-1652, MIT): Wi-Fi, Bluetooth or
// airplane mode as a pill with its name or as a circle, lit in the accent
// while on; or the volume as a ring block or a pie pill.
Glassy.EveryFrame {
    id: f
    // "wifi", "bluetooth", "airplane" or "volume"
    property string kind: "wifi"
    property bool round: false
    property string family
    property bool on: false
    property real volume: 0
    property bool muted: false
    signal toggled()
    readonly property bool isVolume: kind === "volume"
    designWidth: isVolume ? 190 : round ? 95 : 190
    designHeight: isVolume ? (round ? 95 : 190) : 95
    card: isVolume && !round ? "block" : round && !isVolume ? "circle" : "pill"
    readonly property color ink: on ? colors.accent : colors.textPrimary

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: f.toggled()
        onWheel: wheel => wheel.accepted = false
    }

    // A switch: the glyph at 28.5 px in a 38 px square, the name right-aligned.
    Glassy.DotGlyph {
        visible: !f.isVolume
        x: 28.5 * f.s
        y: 28.5 * f.s
        width: 38 * f.s
        height: 38 * f.s
        name: f.kind === "bluetooth" ? "bluetooth" : f.kind === "airplane" ? "airplane" : "wifi"
        color: f.ink
    }
    Glassy.EveryText {
        visible: !f.isVolume && !f.round
        s: f.s
        px: f.kind === "wifi" ? 130 : f.kind === "bluetooth" ? 170 : 165
        py: 50
        pt: 14
        align: "RightCenter"
        // Names stay as written; only the translated word is upper-cased by locale.
        upper: f.kind === "airplane"
        value: f.kind === "wifi" ? "WI-FI" : f.kind === "bluetooth" ? "BLUETOOTH" : i18n("Airplane")
        color: f.ink
        font.family: f.family
    }

    // Volume block: a ring with the level, VOLUME below.
    Glassy.EveryRing {
        visible: f.isVolume && !f.round
        s: f.s; cx: 95; cy: 85; inner: 58; outer: 70
        value: f.muted ? 0 : f.volume
        trackColor: f.track
        fillColor: f.colors.textPrimary
    }
    Glassy.EveryText {
        visible: f.isVolume && !f.round
        s: f.s; px: 95; py: 90; pt: 26; align: "CenterCenter"
        value: Math.round(f.volume * 100) + "%"
        color: f.muted ? f.colors.textMuted : f.colors.textPrimary
        font.family: f.family
    }
    Glassy.EveryText {
        visible: f.isVolume && !f.round
        s: f.s; px: 95; py: 160; pt: 10; align: "Center"; upper: true
        value: f.muted ? i18n("Muted") : i18n("Volume")
        color: f.muted ? f.colors.accent : f.colors.textPrimary
        font.family: f.family
    }
    // Volume pill: a pie, the level and VOL.
    Glassy.EveryPie {
        visible: f.isVolume && f.round
        s: f.s; cx: 47.5; cy: 47.5; radius: 32.5
        value: f.muted ? 0 : f.volume
        trackColor: f.track
        fillColor: f.colors.textPrimary
    }
    Glassy.EveryText {
        visible: f.isVolume && f.round
        s: f.s; px: 95; py: 52; pt: 20; align: "LeftBottom"
        value: Math.round(f.volume * 100) + "%"
        color: f.muted ? f.colors.textMuted : f.colors.textPrimary
        font.family: f.family
    }
    Glassy.EveryText {
        visible: f.isVolume && f.round
        s: f.s; px: 95; py: 57; pt: 16; align: "LeftTop"; upper: f.muted
        value: f.muted ? i18n("Muted") : "VOL"
        color: f.muted ? f.colors.accent : f.colors.textSecondary
        font.family: f.family
    }
}

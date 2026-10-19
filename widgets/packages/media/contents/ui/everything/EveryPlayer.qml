// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import org.kde.kirigami as Kirigami
import "../../../../../shared" as Glassy

// EveryThing-UI's players (Prince-1652, MIT): a block with a large rounded
// cover, or a pill with a round one; title, artist in the accent, grey
// skip buttons, the play button and an accent progress bar.
Glassy.EveryFrame {
    id: f
    property bool pill: false
    property string family
    property string title: ""
    property string artist: ""
    property string artUrl: ""
    property bool playing: false
    property real progress: 0
    signal previous()
    signal playPause()
    signal next()
    designWidth: 390
    designHeight: pill ? 95 : 190
    card: pill ? "pill" : "block"

    // The cover, or a grey placeholder with a note.
    Rectangle {
        x: (f.pill ? 15 : 20) * f.s
        y: (f.pill ? 12.5 : 20) * f.s
        width: (f.pill ? 70 : 150) * f.s
        height: width
        radius: f.pill ? width / 2 : 20 * f.s
        color: f.track
        Glassy.DotGlyph {
            anchors.centerIn: parent
            width: parent.width * 0.42
            height: width
            visible: cover.status !== Image.Ready
            name: "note"
            color: f.colors.textMuted
        }
        Kirigami.ShadowedImage {
            id: cover
            anchors.fill: parent
            radius: parent.radius
            source: f.artUrl
            fillMode: Image.PreserveAspectCrop
            visible: status === Image.Ready
            sourceSize.width: 300
            sourceSize.height: 300
        }
    }
    Glassy.EveryText {
        s: f.s; px: f.pill ? 95 : 195; py: f.pill ? 20 : 30; pt: f.pill ? 12 : 16; clipWidth: f.pill ? 120 : 175; upper: true
        value: f.title || i18n("Nothing playing")
        color: f.colors.textPrimary
        font.family: f.family
    }
    Glassy.EveryText {
        s: f.s; px: f.pill ? 95 : 195; py: f.pill ? 42 : 65; pt: f.pill ? 10 : 12; clipWidth: f.pill ? 120 : 175; upper: true
        value: f.artist
        color: f.colors.textSecondary
        font.family: f.family
    }

    // Skip back, play or pause, skip forward: 16 px dot glyphs (12 in the pill).
    component Button: Item {
        id: button
        property real at
        property string glyph
        property color tint
        signal clicked
        readonly property real size: f.pill ? 12 : 16
        x: at * f.s
        y: (f.pill ? 30 : 105) * f.s
        width: size * f.s
        height: size * f.s
        Glassy.DotGlyph {
            anchors.fill: parent
            name: button.glyph
            color: button.tint
            dotRatio: 0.92
        }
        MouseArea {
            anchors.fill: parent
            anchors.margins: -8 * f.s
            cursorShape: Qt.PointingHandCursor
            onClicked: button.clicked()
        }
    }
    // The original greys the skip buttons; on our translucent card that grey can
    // vanish over a light wallpaper, so they take the muted text colour.
    Button { at: f.pill ? 252 : 211; glyph: "previous"; tint: f.colors.textMuted; onClicked: f.previous() }
    Button { at: f.pill ? 300 : 275; glyph: f.playing ? "pause" : "play"; tint: f.colors.textPrimary; onClicked: f.playPause() }
    Button { at: f.pill ? 345 : 335; glyph: "next"; tint: f.colors.textMuted; onClicked: f.next() }

    Glassy.EveryBar {
        s: f.s
        bx: f.pill ? 95 : 195
        by: f.pill ? 68 : 150
        bw: f.pill ? 265 : 175
        bh: f.pill ? 6 : 8
        radius: f.pill ? 3 : 4
        value: f.progress
        trackColor: f.track
        fillColor: f.colors.accent
    }
}

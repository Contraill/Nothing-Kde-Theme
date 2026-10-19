// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick

// The frame of a design adapted from EveryThing-UI: its size in the original
// Rainmeter pixels, scaled to fit the widget and centred, on the same glassy
// card as every other widget, 10 px in and with 20 px corners ("block"), or a
// "pill", a "circle", or "none" on the wallpaper. Children are placed on
// `canvas`; multiply design coordinates by `s`.
Item {
    id: frame
    required property QtObject colors
    property real designWidth: 190
    property real designHeight: 190
    property string card: "block"
    // The other widgets' card margin; settings miniatures set it to 0.
    property real inset: 10
    default property alias content: canvas.data
    readonly property alias canvas: canvas
    readonly property real s: Math.max(0, Math.min((width - 2 * inset) / designWidth, (height - 2 * inset) / designHeight))
    // EveryThing's grey (#404040 on its opaque #1A1D1C card). Our card is
    // translucent, so the grey is a veil of the text colour: it stays apart
    // from whatever wallpaper shows through.
    readonly property color track: colors.alpha(colors.textPrimary, 0.22)

    Item {
        id: canvas
        anchors.centerIn: parent
        width: frame.designWidth * frame.s
        height: frame.designHeight * frame.s
        GlassySurface {
            anchors.fill: parent
            visible: frame.card !== "none"
            cornerRadius: frame.card === "block" ? 20 * Math.min(1, frame.s) : Math.min(width, height) / 2
            backgroundColor: frame.colors.background
            foregroundColor: frame.colors.textPrimary
        }
    }
}

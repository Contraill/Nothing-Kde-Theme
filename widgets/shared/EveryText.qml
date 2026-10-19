// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick

// A Rainmeter string: (px, py) is its anchor in design pixels and `align`
// Rainmeter's StringAlign (LeftTop, CenterCenter, RightBottom, Center, …).
// Sizes are Rainmeter points; Nothing Dots is scaled to Ndot's digit height.
Text {
    id: label
    property real s: 1
    property real px: 0
    property real py: 0
    property real pt: 12
    property string align: "LeftTop"
    // Clip to this width in design pixels (Rainmeter's W with ClipString).
    property real clipWidth: 0
    property bool upper: false
    property string value: ""
    property bool dots: true
    readonly property string anchorName: align === "Center" ? "CenterTop" : align === "Right" ? "RightTop" : align === "Left" ? "LeftTop" : align
    readonly property real ax: anchorName.startsWith("Center") ? 0.5 : anchorName.startsWith("Right") ? 1 : 0
    readonly property real ay: anchorName.endsWith("Center") ? 0.5 : anchorName.endsWith("Bottom") ? 1 : 0

    text: upper ? value.toLocaleUpperCase(Qt.locale().name) : value
    width: clipWidth > 0 ? clipWidth * s : implicitWidth
    elide: clipWidth > 0 ? Text.ElideRight : Text.ElideNone
    horizontalAlignment: ax === 0.5 ? Text.AlignHCenter : ax === 1 ? Text.AlignRight : Text.AlignLeft
    x: px * s - ax * width
    y: py * s - ay * height
    font.pixelSize: Math.max(1, pt * 4 / 3 * s * (dots ? 0.928 : 0.85))
}

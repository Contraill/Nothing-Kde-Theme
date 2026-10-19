// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtQuick.Shapes
import "every.js" as Every

// A time drawn in one of our two big-clock faces ("blocks" or "bubbles",
// see every.js). Characters after the colon take `secondColor`; the colon
// takes `colonColor`; the bubble face lays `dotColor` dots over its cells.
Row {
    id: digits
    property string text: "00:00"
    property string face: "blocks"
    // Whole pixels keep the cell edges crisp.
    property real cell: 10
    property color color: "white"
    property color secondColor: color
    property color colonColor: color
    property color dotColor: "black"
    readonly property int colonAt: text.indexOf(":")
    readonly property real step: Math.round(cell)
    spacing: face === "bubbles" ? step * 0.5 : step

    Repeater {
        model: digits.text.split("")
        Shape {
            id: glyph
            required property string modelData
            required property int index
            readonly property var outline: Every.glyph(digits.face, modelData, digits.step)
            width: outline.width
            height: outline.height
            preferredRendererType: Shape.CurveRenderer
            ShapePath {
                strokeWidth: -1
                fillRule: ShapePath.WindingFill
                fillColor: glyph.modelData === ":" ? digits.colonColor
                    : digits.colonAt >= 0 && glyph.index > digits.colonAt ? digits.secondColor : digits.color
                PathSvg { path: glyph.outline.fill || "M0 0Z" }
            }
            ShapePath {
                strokeWidth: -1
                fillColor: glyph.modelData === ":" ? digits.colonColor : digits.dotColor
                PathSvg { path: glyph.outline.dots || "M0 0Z" }
            }
        }
    }
}

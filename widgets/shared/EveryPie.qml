// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtQuick.Shapes

// A pie on a grey disc, filled clockwise from the top to `value` (0 to 1).
Shape {
    id: pie
    property real s: 1
    property real cx: 47.5
    property real cy: 47.5
    property real radius: 32.5
    property real value: 0
    property color trackColor: "grey"
    property color fillColor: "white"
    readonly property real fraction: Math.max(0, Math.min(1, value))
    anchors.fill: parent
    preferredRendererType: Shape.CurveRenderer

    ShapePath {
        strokeWidth: -1
        fillColor: pie.trackColor
        PathAngleArc { centerX: pie.cx * pie.s; centerY: pie.cy * pie.s; radiusX: pie.radius * pie.s; radiusY: pie.radius * pie.s; sweepAngle: 360 }
    }
    ShapePath {
        strokeWidth: -1
        fillColor: pie.fraction > 0 ? pie.fillColor : "transparent"
        startX: pie.cx * pie.s
        startY: pie.cy * pie.s
        PathAngleArc {
            centerX: pie.cx * pie.s; centerY: pie.cy * pie.s; radiusX: pie.radius * pie.s; radiusY: pie.radius * pie.s
            startAngle: -90
            sweepAngle: 360 * pie.fraction
            moveToStart: false
        }
    }
}

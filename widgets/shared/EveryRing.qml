// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtQuick.Shapes

// A solid ring between two radii (Rainmeter's Roundline with Solid=1), filled
// clockwise from the top to `value` (0 to 1). Fills its parent canvas.
Shape {
    id: ring
    property real s: 1
    property real cx: 95
    property real cy: 95
    property real inner: 85
    property real outer: 95
    property real value: 0
    property color trackColor: "grey"
    property color fillColor: "white"
    readonly property real radius: (inner + outer) / 2 * s
    anchors.fill: parent
    preferredRendererType: Shape.CurveRenderer

    ShapePath {
        strokeWidth: (ring.outer - ring.inner) * ring.s
        strokeColor: ring.trackColor
        fillColor: "transparent"
        capStyle: ShapePath.FlatCap
        PathAngleArc { centerX: ring.cx * ring.s; centerY: ring.cy * ring.s; radiusX: ring.radius; radiusY: ring.radius; sweepAngle: 360 }
    }
    ShapePath {
        strokeWidth: (ring.outer - ring.inner) * ring.s
        strokeColor: ring.value > 0 ? ring.fillColor : "transparent"
        fillColor: "transparent"
        capStyle: ShapePath.FlatCap
        PathAngleArc {
            centerX: ring.cx * ring.s; centerY: ring.cy * ring.s; radiusX: ring.radius; radiusY: ring.radius
            startAngle: -90
            sweepAngle: 360 * Math.max(0, Math.min(1, ring.value))
        }
    }
}

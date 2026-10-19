// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtQuick.Shapes
import "../../../../../shared" as Glassy

// EveryThing-UI's visualizers (Prince-1652, MIT): twenty wedges around a
// circle, or rounded bars in a wide or a short pill. `levels` holds one
// value from 0 to 1 per band.
Glassy.EveryFrame {
    id: f
    // Unused; every design takes it so settings previews can pass it.
    property string family
    // "circle", "bars" or "pill"
    property string layout: "circle"
    property var levels: []
    readonly property int bands: layout === "circle" ? 20 : layout === "bars" ? 25 : 11
    designWidth: layout === "bars" ? 390 : 190
    designHeight: layout === "circle" ? 190 : 95
    card: layout === "circle" ? "block" : "pill"

    // Circle: a sector every 18 degrees between radii 50 and 85, opening up to 10 degrees with its level.
    Repeater {
        model: f.layout === "circle" ? f.bands : 0
        Shape {
            id: wedge
            required property int index
            readonly property real level: Math.max(0, Math.min(1, f.levels[index] ?? 0))
            anchors.fill: parent
            preferredRendererType: Shape.CurveRenderer
            ShapePath {
                strokeWidth: 35 * f.s
                strokeColor: f.colors.textPrimary
                fillColor: "transparent"
                capStyle: ShapePath.FlatCap
                PathAngleArc {
                    centerX: 95 * f.s; centerY: 95 * f.s
                    radiusX: 67.5 * f.s; radiusY: radiusX
                    startAngle: -90 + wedge.index * 18
                    // A sliver at rest, so the ring of bands still shows in silence.
                    sweepAngle: Math.max(1.2, 10 * wedge.level)
                }
            }
        }
    }
    // Bars: 8 px wide every 12 px, growing up from y 75, at least 8 px tall.
    Repeater {
        model: f.layout === "circle" ? 0 : f.bands
        Rectangle {
            required property int index
            readonly property real level: Math.max(0, Math.min(1, f.levels[index] ?? 0))
            readonly property real tall: Math.max(8, level * 55)
            x: ((f.layout === "bars" ? 47 : 31) + index * 12) * f.s
            y: (75 - tall) * f.s
            width: 8 * f.s
            height: tall * f.s
            radius: 4 * f.s
            color: f.colors.textPrimary
        }
    }
}

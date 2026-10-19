// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtQuick.Shapes
import QtQuick.Effects
import "../../../../shared" as Glassy

// One light of a glyph interface, after the Nothing Phone (1)'s back: the
// camera ring in four parts, an arc, a strip of eight lights, a slanted line
// or a dot. `light(n)` is the brightness of part n from 0 to 1; `fill` the
// share of the strip lit, and of the line and arc when `progress` is on.
// The ring, arc and dot keep their round shape; the line and the strip
// stretch with the widget: the line runs corner to corner (flat in a flat
// widget, upright in a tall one) and the strip gains lights as it grows.
// Round it all a margin as wide as the glow, so the glow fades out inside
// the widget instead of being cut at its edge.
Glassy.EveryFrame {
    id: f
    // "ring", "arc", "strip", "line", "dot", "corner" or "dots"
    property string shape: "ring"
    // Unused; every design takes it so settings previews can pass it.
    property string family
    property var light: n => 0
    property real fill: 0
    property bool progress: false
    // The arc's length in degrees; its gap stays at the lower right.
    property real sweep: 255
    // The line runs the other diagonal.
    property bool mirror: false
    // The corner: 0 top left, 1 top right, 2 bottom left, 3 bottom right.
    property int corner: 0

    // Each round shape's own box; the line and strip use the widget's pixels.
    readonly property bool stretch: ["line", "strip", "corner"].includes(shape)
    readonly property size box: shape === "dot" ? Qt.size(50, 50) : Qt.size(150, 150)
    // The glow's room on every side, as a share of the box's short side.
    readonly property real glowRoom: 0.16
    readonly property real room: Math.min(box.width, box.height) * glowRoom + (transparent ? 0 : Math.min(box.width, box.height) * 0.08)
    designWidth: stretch ? Math.max(1, width) : box.width + 2 * room
    designHeight: stretch ? Math.max(1, height) : box.height + 2 * room
    // A stretching light's thickness and glow room, in pixels.
    readonly property real shortSide: Math.min(canvas.width, canvas.height)
    readonly property real thickness: shape === "strip" ? Math.max(6, Math.min(22, shortSide * 0.42)) : Math.max(4, Math.min(16, shortSide * 0.25))
    readonly property real stretchRoom: thickness * 0.9 + (transparent ? 0 : thickness * 0.5)
    inset: transparent ? 0 : 10
    card: shape === "strip" ? "pill" : shape === "dot" || shape === "dots" ? "circle" : "block"

    readonly property color lit: colors.accent
    readonly property color unlit: colors.alpha(colors.textPrimary, 0.10)
    function tone(k) {
        k = Math.max(0, Math.min(1, k));
        return Qt.rgba(unlit.r + (lit.r - unlit.r) * k, unlit.g + (lit.g - unlit.g) * k, unlit.b + (lit.b - unlit.b) * k, 0.1 + 0.9 * k);
    }

    Item {
        id: lights
        x: f.stretch ? f.stretchRoom : f.room * f.s
        y: f.stretch ? f.stretchRoom : f.room * f.s
        width: f.stretch ? Math.max(1, f.canvas.width - 2 * f.stretchRoom) : f.box.width * f.s
        height: f.stretch ? Math.max(1, f.canvas.height - 2 * f.stretchRoom) : f.box.height * f.s
        readonly property real u: f.s
        // The software renderer draws no effects; the lights then go without the glow.
        layer.enabled: GraphicsInfo.api !== GraphicsInfo.Software
        layer.samples: 4
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: f.lit
            shadowBlur: 1.0
            blurMax: Math.max(4, Math.round(f.stretch ? f.stretchRoom : f.room * f.s))
            shadowHorizontalOffset: 0
            shadowVerticalOffset: 0
            shadowOpacity: 1.0
        }

        component Stroke: ShapePath {
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            strokeWidth: 14 * lights.u
        }

        // The camera ring: four arcs of 80 degrees.
        Repeater {
            model: f.shape === "ring" ? 4 : 0
            Shape {
                id: part
                required property int index
                anchors.fill: parent
                preferredRendererType: Shape.CurveRenderer
                Stroke {
                    strokeColor: f.tone(f.light(part.index))
                    PathAngleArc {
                        centerX: 75 * lights.u; centerY: 75 * lights.u
                        radiusX: 66 * lights.u; radiusY: radiusX
                        startAngle: -85 + part.index * 90
                        sweepAngle: 80
                    }
                }
            }
        }
        // An arc open at the lower right, as round the Phone (1)'s camera; as
        // a progress it lights from its start as far as the beat reaches.
        Shape {
            id: arcShape
            anchors.fill: parent
            visible: f.shape === "arc"
            preferredRendererType: Shape.CurveRenderer
            readonly property real start: 22.5 + (360 - f.sweep) / 2
            Stroke {
                strokeWidth: 16 * lights.u
                strokeColor: f.tone(f.progress ? 0 : f.light(0))
                PathAngleArc {
                    centerX: 75 * lights.u; centerY: 75 * lights.u
                    radiusX: 66 * lights.u; radiusY: radiusX
                    startAngle: arcShape.start
                    sweepAngle: f.sweep
                }
            }
            Stroke {
                strokeWidth: 16 * lights.u
                strokeColor: f.progress && f.fill > 0.01 ? f.tone(Math.max(0.55, f.light(0))) : "transparent"
                PathAngleArc {
                    centerX: 75 * lights.u; centerY: 75 * lights.u
                    radiusX: 66 * lights.u; radiusY: radiusX
                    startAngle: arcShape.start
                    sweepAngle: f.sweep * Math.max(0.001, Math.min(1, f.fill))
                }
            }
        }
        // The Phone (1)'s strip: one capsule cut by hairline gaps into
        // segments, filling from the bottom (or the left) with the beat, its
        // leading segment brightest; a flash of its zone lights it whole.
        Repeater {
            id: strip
            readonly property bool across: lights.width > lights.height
            readonly property real length: across ? lights.width : lights.height
            readonly property real gap: Math.max(1.5, f.thickness * 0.14)
            readonly property int count: Math.max(3, Math.round(length / (f.thickness * 1.8)))
            readonly property real piece: (length - (count - 1) * gap) / count
            readonly property real reach: f.fill * count
            model: f.shape === "strip" ? count : 0
            Rectangle {
                required property int index
                readonly property real along: index * (strip.piece + strip.gap)
                readonly property bool first: index === 0
                readonly property bool last: index === strip.count - 1
                readonly property real end: f.thickness / 2
                // Lit below the reach, the segment at the reach brightest.
                readonly property real filled: Math.max(0, Math.min(1, strip.reach - index))
                readonly property real head: filled > 0 && strip.reach - index < 1.6 ? 1 : 0.7
                x: strip.across ? along : (lights.width - f.thickness) / 2
                y: strip.across ? (lights.height - f.thickness) / 2 : lights.height - along - strip.piece
                width: strip.across ? strip.piece : f.thickness
                height: strip.across ? f.thickness : strip.piece
                // Round only the capsule's two ends.
                topLeftRadius: strip.across ? (first ? end : 0) : (last ? end : 0)
                bottomLeftRadius: first ? end : 0
                topRightRadius: last ? end : 0
                bottomRightRadius: strip.across ? (last ? end : 0) : (first ? end : 0)
                color: f.tone(Math.max(filled * head, f.light(0) > 0.45 ? f.light(0) : 0))
            }
        }
        // A line from corner to corner; as a progress it lights from its start.
        Shape {
            id: line
            anchors.fill: parent
            visible: f.shape === "line"
            preferredRendererType: Shape.CurveRenderer
            readonly property real cap: f.thickness / 2
            // Three times as long as it is wide or more: straight across, or straight up.
            readonly property bool flat: lights.width >= 3 * lights.height
            readonly property bool upright: lights.height >= 3 * lights.width
            readonly property real x0: upright ? lights.width / 2 : cap
            readonly property real y0: flat ? lights.height / 2 : f.mirror ? cap : lights.height - cap
            readonly property real x1: upright ? lights.width / 2 : lights.width - cap
            readonly property real y1: flat ? lights.height / 2 : f.mirror ? lights.height - cap : cap
            Stroke {
                strokeWidth: f.thickness
                strokeColor: f.tone(f.progress ? 0 : f.light(0))
                startX: line.x0; startY: line.y0
                PathLine { x: line.x1; y: line.y1 }
            }
            Stroke {
                id: lineFill
                readonly property real reach: Math.max(0.001, Math.min(1, f.fill))
                strokeWidth: f.thickness
                strokeColor: f.progress && f.fill > 0.01 ? f.tone(Math.max(0.55, f.light(0))) : "transparent"
                startX: line.x0; startY: line.y0
                PathLine { x: line.x0 + (line.x1 - line.x0) * lineFill.reach; y: line.y0 + (line.y1 - line.y0) * lineFill.reach }
            }
        }
        Rectangle {
            visible: f.shape === "dot"
            x: 3 * lights.u
            y: 3 * lights.u
            width: 44 * lights.u
            height: width
            radius: width / 2
            color: f.tone(f.light(0))
        }

        // A corner, its arms along the widget's edges; as a progress it
        // lights out from the corner along both arms.
        Shape {
            id: bend
            anchors.fill: parent
            visible: f.shape === "corner"
            opacity: shade.a
            preferredRendererType: Shape.CurveRenderer
            readonly property real cap: f.thickness / 2
            readonly property real cx: f.corner % 2 === 0 ? cap : lights.width - cap
            readonly property real cy: f.corner < 2 ? cap : lights.height - cap
            readonly property real ex: f.corner % 2 === 0 ? lights.width - cap : cap
            readonly property real ey: f.corner < 2 ? lights.height - cap : cap
            readonly property real reach: Math.max(0.001, Math.min(1, f.fill))
            // Solid in its own layer, faded whole, so the bend does not blend twice.
            readonly property color shade: f.tone(f.progress ? 0 : f.light(0))
            layer.enabled: true
            layer.samples: 4
            Stroke {
                strokeWidth: f.thickness
                strokeColor: Qt.rgba(bend.shade.r, bend.shade.g, bend.shade.b, 1)
                joinStyle: ShapePath.RoundJoin
                startX: bend.ex; startY: bend.cy
                PathLine { x: bend.cx; y: bend.cy }
                PathLine { x: bend.cx; y: bend.ey }
            }
        }
        // The corner's progress, lit out from the bend, in a layer of its own.
        Shape {
            id: bendFill
            anchors.fill: parent
            visible: f.shape === "corner" && f.progress && f.fill > 0.01
            preferredRendererType: Shape.CurveRenderer
            readonly property color shade: f.tone(Math.max(0.55, f.light(0)))
            opacity: shade.a
            layer.enabled: true
            layer.samples: 4
            Stroke {
                strokeWidth: f.thickness
                strokeColor: Qt.rgba(bendFill.shade.r, bendFill.shade.g, bendFill.shade.b, 1)
                joinStyle: ShapePath.RoundJoin
                startX: bend.cx + (bend.ex - bend.cx) * bend.reach; startY: bend.cy
                PathLine { x: bend.cx; y: bend.cy }
                PathLine { x: bend.cx; y: bend.cy + (bend.ey - bend.cy) * bend.reach }
            }
        }
        // Twelve dots round a circle.
        Repeater {
            model: f.shape === "dots" ? 12 : 0
            Rectangle {
                required property int index
                readonly property real angle: (index * 30 - 90) * Math.PI / 180
                width: 18 * lights.u
                height: width
                radius: width / 2
                x: (75 + 62 * Math.cos(angle)) * lights.u - width / 2
                y: (75 + 62 * Math.sin(angle)) * lights.u - height / 2
                color: f.tone(f.light(index))
            }
        }
    }
}

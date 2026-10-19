// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtQuick.Shapes
import QtQuick.Effects
import "../../../../shared" as Glassy

// One light of a glyph interface, after the Nothing Phone (1)'s back: the
// camera ring in four parts, an arc, a strip of eight lights, a slanted line
// or a dot. `light(n)` gives the brightness of part n from 0 to 1; several
// widgets in this style share one clock, so together they play as one.
Glassy.EveryFrame {
    id: f
    // "ring", "arc", "strip", "line" or "dot"
    property string shape: "ring"
    // Unused; every design takes it so settings previews can pass it.
    property string family
    // Brightness by part; a function so previews can pass a fixed one.
    property var light: n => 0
    designWidth: shape === "strip" ? 95 : 190
    designHeight: 190
    card: shape === "strip" ? "pill" : "block"

    readonly property color lit: colors.accent
    readonly property color unlit: colors.alpha(colors.textPrimary, 0.10)
    // A lit part's colour: the unlit glass brightening into the light.
    function tone(level) {
        const k = Math.max(0, Math.min(1, level));
        return Qt.rgba(unlit.r + (lit.r - unlit.r) * k, unlit.g + (lit.g - unlit.g) * k, unlit.b + (lit.b - unlit.b) * k, 0.1 + 0.9 * k);
    }

    component Stroke: ShapePath {
        strokeWidth: 14 * f.s
        fillColor: "transparent"
        capStyle: ShapePath.RoundCap
    }

    Item {
        id: lights
        width: f.canvas.width
        height: f.canvas.height
        // The software renderer draws no effects; the lights then go without the glow.
        layer.enabled: GraphicsInfo.api !== GraphicsInfo.Software
        layer.effect: MultiEffect {
            // The glow of the lights.
            shadowEnabled: true
            shadowColor: f.lit
            shadowBlur: 0.8
            shadowHorizontalOffset: 0
            shadowVerticalOffset: 0
            shadowOpacity: 0.7
        }

        // The camera ring: four arcs of 80 degrees, lighting in turn.
        Repeater {
            model: f.shape === "ring" ? 4 : 0
            Shape {
                id: arc
                required property int index
                anchors.fill: parent
                preferredRendererType: Shape.CurveRenderer
                Stroke {
                    strokeColor: f.tone(f.light(arc.index))
                    PathAngleArc {
                        centerX: 95 * f.s; centerY: 95 * f.s
                        radiusX: 66 * f.s; radiusY: radiusX
                        startAngle: -85 + arc.index * 90
                        sweepAngle: 80
                    }
                }
            }
        }
        // An arc open at the lower right, as round the Phone (1)'s camera.
        Shape {
            anchors.fill: parent
            visible: f.shape === "arc"
            preferredRendererType: Shape.CurveRenderer
            Stroke {
                strokeWidth: 16 * f.s
                strokeColor: f.tone(f.light(0))
                PathAngleArc {
                    centerX: 95 * f.s; centerY: 95 * f.s
                    radiusX: 56 * f.s; radiusY: radiusX
                    startAngle: 75
                    sweepAngle: 255
                }
            }
        }
        // A strip of eight lights filling from the bottom with the level.
        Repeater {
            model: f.shape === "strip" ? 8 : 0
            Rectangle {
                required property int index
                x: 37.5 * f.s
                y: (22 + (7 - index) * 19) * f.s
                width: 20 * f.s
                height: 13 * f.s
                radius: 6.5 * f.s
                color: f.tone(Math.max(0, Math.min(1, f.light(0) * 8 - index)))
            }
        }
        Shape {
            anchors.fill: parent
            visible: f.shape === "line"
            preferredRendererType: Shape.CurveRenderer
            Stroke {
                strokeWidth: 16 * f.s
                strokeColor: f.tone(f.light(0))
                startX: 50 * f.s; startY: 140 * f.s
                PathLine { x: 140 * f.s; y: 50 * f.s }
            }
        }
        Rectangle {
            visible: f.shape === "dot"
            x: (95 - 20) * f.s
            y: (95 - 20) * f.s
            width: 40 * f.s
            height: width
            radius: width / 2
            color: f.tone(f.light(0))
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtQuick.Shapes
import QtQuick.Effects
import "../../../../shared" as Glassy

// One light of a glyph interface, after the Nothing Phone (1)'s back: the
// camera ring in four parts, an arc, a strip of eight lights, a slanted line
// or a dot, filling the widget. It lights while `level` is over `threshold`
// (its zone's step), sharply, the way the phone's lights flash on a beat.
Glassy.EveryFrame {
    id: f
    // "ring", "arc", "strip", "line" or "dot"
    property string shape: "ring"
    // Unused; every design takes it so settings previews can pass it.
    property string family
    property real level: 0
    property real threshold: 0.25
    // Each shape's own box, so it fills the widget without margins.
    readonly property size box: shape === "strip" ? Qt.size(34, 170) : shape === "dot" ? Qt.size(50, 50) : Qt.size(150, 150)
    // With a card, the light sits inside it.
    readonly property real pad: transparent ? 0 : 0.14
    designWidth: box.width * (1 + 2 * pad)
    designHeight: box.height * (1 + 2 * pad)
    inset: transparent ? 2 : 10
    card: shape === "strip" ? "pill" : shape === "dot" ? "circle" : "block"

    readonly property color lit: colors.accent
    readonly property color unlit: colors.alpha(colors.textPrimary, 0.10)
    // A part's brightness: off below its step, full a little above it.
    function power(step) {
        return Math.max(0, Math.min(1, (level - step) / 0.12));
    }
    function tone(k) {
        return Qt.rgba(unlit.r + (lit.r - unlit.r) * k, unlit.g + (lit.g - unlit.g) * k, unlit.b + (lit.b - unlit.b) * k, 0.1 + 0.9 * k);
    }

    Item {
        id: lights
        x: f.box.width * f.pad * f.s
        y: f.box.height * f.pad * f.s
        width: f.box.width * f.s
        height: f.box.height * f.s
        readonly property real u: f.s
        // The software renderer draws no effects; the lights then go without the glow.
        layer.enabled: GraphicsInfo.api !== GraphicsInfo.Software
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: f.lit
            shadowBlur: 1.0
            shadowHorizontalOffset: 0
            shadowVerticalOffset: 0
            shadowOpacity: 0.9
            shadowScale: 1.04
        }

        // The camera ring: four arcs of 80 degrees, lighting further round the louder the beat.
        Repeater {
            model: f.shape === "ring" ? 4 : 0
            Shape {
                id: arc
                required property int index
                anchors.fill: parent
                preferredRendererType: Shape.CurveRenderer
                ShapePath {
                    strokeWidth: 14 * lights.u
                    strokeColor: f.tone(f.power(f.threshold + arc.index * 0.05))
                    fillColor: "transparent"
                    capStyle: ShapePath.RoundCap
                    PathAngleArc {
                        centerX: 75 * lights.u; centerY: 75 * lights.u
                        radiusX: 66 * lights.u; radiusY: radiusX
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
            ShapePath {
                strokeWidth: 16 * lights.u
                strokeColor: f.tone(f.power(f.threshold))
                fillColor: "transparent"
                capStyle: ShapePath.RoundCap
                PathAngleArc {
                    centerX: 75 * lights.u; centerY: 75 * lights.u
                    radiusX: 66 * lights.u; radiusY: radiusX
                    startAngle: 75
                    sweepAngle: 255
                }
            }
        }
        // A strip of eight lights rising from the bottom with the beat.
        Repeater {
            model: f.shape === "strip" ? 8 : 0
            Rectangle {
                required property int index
                x: 7 * lights.u
                y: (3 + (7 - index) * 21) * lights.u
                width: 20 * lights.u
                height: 17 * lights.u
                radius: 8.5 * lights.u
                color: f.tone(Math.max(0, Math.min(1, (f.level - f.threshold) / (1 - f.threshold) * 8 - index)))
            }
        }
        Shape {
            anchors.fill: parent
            visible: f.shape === "line"
            preferredRendererType: Shape.CurveRenderer
            ShapePath {
                strokeWidth: 16 * lights.u
                strokeColor: f.tone(f.power(f.threshold))
                fillColor: "transparent"
                capStyle: ShapePath.RoundCap
                startX: 10 * lights.u; startY: 140 * lights.u
                PathLine { x: 140 * lights.u; y: 10 * lights.u }
            }
        }
        Rectangle {
            visible: f.shape === "dot"
            x: 3 * lights.u
            y: 3 * lights.u
            width: 44 * lights.u
            height: width
            radius: width / 2
            color: f.tone(f.power(f.threshold))
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtQuick.Shapes
import "."

// Wi-Fi strength as a dot and three arcs, each lit from 25 %, 50 % and 75 %.
Item {
    id: root
    property int strength: -1
    readonly property int level: strength >= 75 ? 3 : strength >= 50 ? 2 : strength >= 25 ? 1 : 0
    property color activeColor: Theme.fg
    property color inactiveColor: Theme.fgDim
    implicitWidth: 18
    implicitHeight: 18
    Accessible.role: Accessible.StaticText
    Accessible.name: "Wi-Fi" + (strength >= 0 ? " · " + strength + "%" : "")

    // Drawn on an 18 px grid around a point near the bottom middle.
    readonly property real unit: Math.min(width, height) / 18
    component Wave: ShapePath {
        property int wave
        strokeWidth: 1.65 * root.unit
        strokeColor: wave <= root.level ? root.activeColor : root.inactiveColor
        fillColor: "transparent"
        capStyle: ShapePath.RoundCap
        PathAngleArc {
            centerX: 9 * root.unit
            centerY: 15 * root.unit
            radiusX: (2 + 3 * wave) * root.unit
            radiusY: radiusX
            startAngle: -135
            sweepAngle: 90
        }
    }
    // A Shape sizes itself from its paths; the item keeps the size instead.
    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer
        Wave { wave: 1 }
        Wave { wave: 2 }
        Wave { wave: 3 }
    }
    // The dot, lit once there is any reading.
    Rectangle {
        // Whole pixels keep a 2 px dot crisp at the panel's size.
        width: Math.round(2.4 * root.unit)
        height: width
        radius: width / 2
        x: Math.round(9 * root.unit - width / 2)
        y: Math.round(15 * root.unit - height / 2)
        color: root.strength >= 0 ? root.activeColor : root.inactiveColor
    }
}

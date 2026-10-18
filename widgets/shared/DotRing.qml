// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick

// A ring of dots, Nothing OS style: the first `value` share of them is lit,
// clockwise from the top.
Item {
    id: ring
    property real value: 0
    property int count: 32
    property color litColor: "white"
    property color dimColor: Qt.rgba(litColor.r, litColor.g, litColor.b, 0.16)
    property real dotSize: Math.max(2, Math.min(width, height) * 0.055)
    readonly property int lit: Math.round(Math.max(0, Math.min(1, value)) * count)

    Repeater {
        model: ring.count
        Rectangle {
            required property int index
            readonly property real angle: 2 * Math.PI * index / ring.count - Math.PI / 2
            readonly property real radiusPx: (Math.min(ring.width, ring.height) - ring.dotSize) / 2
            width: ring.dotSize
            height: width
            radius: width / 2
            x: ring.width / 2 + radiusPx * Math.cos(angle) - width / 2
            y: ring.height / 2 + radiusPx * Math.sin(angle) - height / 2
            color: index < ring.lit ? ring.litColor : ring.dimColor
            Behavior on color { ColorAnimation { duration: 180 } }
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick

// A rounded bar filled from the left to `value` (0 to 1); the fill keeps the
// bar's rounded left end and is cut straight on the right, as in Rainmeter's
// container clipping. Children are laid over it in design pixels relative to
// the bar.
Item {
    id: bar
    property real s: 1
    property real bx: 0
    property real by: 0
    property real bw: 150
    property real bh: 65
    property real radius: 15
    property real value: 0
    property color trackColor: "grey"
    property color fillColor: "white"
    default property alias overlay: over.data
    x: bx * s
    y: by * s
    width: bw * s
    height: bh * s

    Rectangle {
        anchors.fill: parent
        radius: bar.radius * bar.s
        color: bar.trackColor
    }
    Item {
        width: bar.width * Math.max(0, Math.min(1, bar.value))
        height: bar.height
        clip: true
        Rectangle {
            width: bar.width
            height: bar.height
            radius: bar.radius * bar.s
            color: bar.fillColor
        }
    }
    Item {
        id: over
        anchors.fill: parent
    }
}

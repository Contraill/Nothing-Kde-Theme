// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick

// A rounded bar filled from the left to `value` (0 to 1); the fill keeps the
// bar's rounded left end and is cut straight on the right, as in Rainmeter's
// container clipping. `overlay` is drawn twice in design pixels relative to
// the bar, cut along the fill's edge: its root reads `parent.ink`, the track's
// ink over the track and a contrasting ink over the fill.
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
    property color ink: "white"
    readonly property color fillInk: (0.2126 * fillColor.r + 0.7152 * fillColor.g + 0.0722 * fillColor.b) > 0.6 ? "#111111" : "#ffffff"
    property Component overlay
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
        id: filled
        width: bar.width * Math.max(0, Math.min(1, bar.value))
        height: bar.height
        clip: true
        Rectangle {
            width: bar.width
            height: bar.height
            radius: bar.radius * bar.s
            color: bar.fillColor
        }
        Item {
            id: fillLayer
            width: bar.width
            height: bar.height
            readonly property color ink: bar.fillInk
        }
    }
    Item {
        x: filled.width
        width: bar.width - filled.width
        height: bar.height
        clip: true
        Item {
            id: trackLayer
            x: -parent.x
            width: bar.width
            height: bar.height
            readonly property color ink: bar.ink
        }
    }
    // Not Loaders: they would stretch the overlay to the bar.
    Component.onCompleted: if (overlay) {
        overlay.createObject(fillLayer);
        overlay.createObject(trackLayer);
    }
}

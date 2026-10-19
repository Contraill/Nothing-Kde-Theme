// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import "."

// The island's switch, drawn on an inverted card when on: the knob grows
// and slides right.
Rectangle {
    id: track
    property bool on: false
    width: 44
    height: 24
    radius: 12
    color: on ? Theme.invertedFg : Theme.surfaceHigh
    border.width: on ? 0 : 2
    border.color: Theme.outline
    Behavior on color { ColorAnimation { duration: Theme.durMedium } }
    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        width: track.on ? 18 : 14
        height: width
        radius: width / 2
        x: track.on ? track.width - width - 3 : 4
        color: track.on ? Theme.inverted : Theme.fgFaint
        Behavior on x { NumberAnimation { duration: Theme.durMedium; easing.type: Easing.Bezier; easing.bezierCurve: Theme.emphasized } }
        Behavior on width { NumberAnimation { duration: Theme.durShort } }
        Behavior on color { ColorAnimation { duration: Theme.durMedium } }
    }
}

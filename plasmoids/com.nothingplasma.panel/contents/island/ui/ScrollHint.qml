// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import "."

// A thin scroll position line at the right edge of a list, brighter while
// it moves. Place it next to the Flickable, in the same parent.
Rectangle {
    property Flickable flickable
    readonly property real overflow: flickable.contentHeight - flickable.height
    anchors.right: flickable.right
    anchors.rightMargin: 1
    visible: overflow > 0
    width: 3
    radius: 1.5
    height: Math.max(24, flickable.height * flickable.height / flickable.contentHeight)
    y: flickable.y + (overflow > 0 ? flickable.contentY / overflow * (flickable.height - height) : 0)
    color: Theme.fgFaint
    opacity: flickable.moving ? 0.9 : 0.25
    Behavior on opacity { NumberAnimation { duration: Theme.durMedium } }
}

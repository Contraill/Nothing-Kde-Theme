// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import "."

// The closed island's volume: icon and level. Click mutes, scroll changes it.
MouseArea {
    id: root
    implicitWidth: row.implicitWidth
    implicitHeight: row.implicitHeight
    cursorShape: Qt.PointingHandCursor
    onClicked: Audio.toggleMute()
    onWheel: wheel => Audio.wheel(wheel)

    Row {
        id: row
        spacing: 4
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: Audio.muted || Audio.percent === 0 ? Icons.volMute : Audio.percent > 50 ? Icons.volHigh : Icons.volLow
            // Red above 100 %.
            color: Audio.muted ? Theme.fgFaint : Audio.percent > 100 ? Theme.alert : Theme.fg
            font.family: Theme.fontIcons
            font.pixelSize: 18
        }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: Audio.percent
            color: Theme.fgDim
            font.family: Theme.font
            font.pixelSize: Theme.labelMedium
        }
    }
}

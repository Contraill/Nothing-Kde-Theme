// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import "."

// The panels' round button: an icon, or a short label when `label` is set.
// `on` fills it; `flat` drops the chip until hovered (or `held`).
Rectangle {
    id: button
    property string icon: ""
    property string label: ""
    property bool on: false
    property bool flat: false
    property bool held: false
    property int iconSize: 15
    signal clicked
    width: label ? caption.implicitWidth + 20 : height
    height: 26
    radius: height / 2
    color: on ? Theme.inverted
        : flat ? Qt.alpha(Theme.fg, area.containsMouse || held ? Theme.stateHover : 0)
        : area.containsMouse ? Theme.surfaceHigh : Theme.surfaceAlt
    Behavior on color { ColorAnimation { duration: Theme.durShort } }
    Accessible.role: Accessible.Button
    Accessible.name: label || icon
    Accessible.onPressAction: button.clicked()
    Text {
        id: caption
        anchors.centerIn: parent
        text: button.label || button.icon
        color: button.on ? Theme.invertedFg : area.containsMouse ? Theme.fg : Theme.fgDim
        font.family: button.label ? Theme.font : Theme.fontIcons
        font.pixelSize: button.label ? Theme.labelSmall : button.iconSize
        font.letterSpacing: button.label ? Theme.labelSpacing : 0
    }
    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: button.clicked()
    }
}

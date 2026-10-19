// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import "."

// A small rounded text button. tone: "plain" (outlined), "strong" (filled
// with the inverted colour), "danger" (outlined in red) or "alert" (filled red).
Rectangle {
    id: button
    property string label
    property string tone: "plain"
    property int padding: 22
    signal clicked
    readonly property bool filled: tone === "strong" || tone === "alert"
    readonly property color base: tone === "strong" ? Theme.inverted : tone === "alert" ? Theme.alert : "transparent"
    width: caption.implicitWidth + padding
    height: 28
    radius: 14
    color: filled ? (area.containsMouse ? Qt.lighter(base, tone === "alert" ? 1.15 : 1.1) : base)
        : area.containsMouse ? Qt.alpha(tone === "danger" ? Theme.alert : Theme.fg, Theme.stateHover) : "transparent"
    border.width: filled ? 0 : 1
    border.color: tone === "danger" ? Theme.alert : Theme.outline
    Behavior on color { ColorAnimation { duration: Theme.durShort } }
    Accessible.role: Accessible.Button
    Accessible.name: label
    Accessible.onPressAction: button.clicked()
    Text {
        id: caption
        anchors.centerIn: parent
        text: button.label
        color: button.tone === "strong" ? Theme.invertedFg : button.tone === "danger" ? Theme.alert : Theme.fg
        font.family: Theme.font
        font.pixelSize: Theme.labelSmall
        font.weight: Font.Medium
        font.letterSpacing: Theme.labelSpacing
    }
    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: button.clicked()
    }
}

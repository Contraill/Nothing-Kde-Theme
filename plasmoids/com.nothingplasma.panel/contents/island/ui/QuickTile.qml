import QtQuick
import QtQuick.Controls as QQC2
import "."

// A Nothing OS style quick setting: filled while on.
QQC2.AbstractButton {
    id: tile
    property bool on: false
    property bool busy: false
    property string glyph: ""
    property string label: ""
    property string stateText: ""

    height: 36
    Accessible.name: label + (stateText ? " · " + stateText : "")
    background: Rectangle {
        radius: 11
        color: tile.on ? Theme.inverted : tile.hovered ? Theme.surfaceTop : Theme.surfaceHigh
        Behavior on color { ColorAnimation { duration: Theme.durShort } }
    }
    contentItem: Row {
        spacing: 5
        opacity: tile.enabled || tile.busy ? 1 : 0.3
        leftPadding: 8
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: tile.glyph
            font.family: Theme.fontIcons
            font.pixelSize: 17
            color: tile.on ? Theme.invertedFg : Theme.fgDim
        }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            width: tile.width - 38
            text: tile.busy ? "…" : tile.label
            font.family: Theme.font
            font.pixelSize: 10
            color: tile.on ? Theme.invertedFg : Theme.fgDim
            elide: Text.ElideRight
        }
    }
}

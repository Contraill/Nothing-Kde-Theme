// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import "."

// A panel's first row: its name on the left; on the right, any buttons
// placed inside the header, then close.
Item {
    id: header
    property string title
    default property alias buttons: extra.data
    signal closed
    width: parent ? parent.width : 0
    height: 26
    Text {
        anchors.verticalCenter: parent.verticalCenter
        text: header.title
        color: Theme.fgFaint
        font.family: Theme.font
        font.pixelSize: Theme.labelSmall
        font.letterSpacing: Theme.labelSpacing
    }
    Row {
        anchors.right: parent.right
        spacing: 6
        Row {
            id: extra
            spacing: 6
            visible: children.length > 0
        }
        RoundButton {
            icon: "close"
            Accessible.name: Cfg.t("CLOSE")
            onClicked: header.closed()
        }
    }
}

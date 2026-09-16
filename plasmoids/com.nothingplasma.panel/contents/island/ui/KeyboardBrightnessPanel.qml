import QtQuick
import QtQuick.Controls as QQC2

Item {
    id: root
    signal closed
    implicitHeight: 100
    Text {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.topMargin: 7
        text: Cfg.t("KEYBOARD LIGHTING")
        color: Theme.fgFaint
        font.family: Theme.font
        font.pixelSize: Theme.labelSmall
        font.letterSpacing: Theme.labelSpacing
    }
    QQC2.AbstractButton {
        id: closeButton
        anchors.right: parent.right
        anchors.top: parent.top
        width: 26
        height: 26
        Accessible.name: Cfg.t("CLOSE")
        onClicked: root.closed()
        background: Rectangle {
            radius: 13
            color: closeButton.hovered ? Theme.surfaceHigh : Theme.surfaceAlt
        }
        contentItem: Text {
            text: "close"
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            font.family: Theme.fontIcons
            font.pixelSize: 15
            color: Theme.fgDim
        }
    }
    BrightnessCard {
        anchors.left: parent.left
        anchors.right: parent.right
        y: 36
        height: 56
        keyboardMode: true
    }
}

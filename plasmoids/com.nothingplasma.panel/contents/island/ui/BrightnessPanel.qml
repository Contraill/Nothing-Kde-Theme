import QtQuick
import QtQuick.Controls as QQC2

// Every display PowerDevil can dim (external monitors included) and the
// keyboard backlight; the main card only drives the built-in display.
Item {
    id: root
    signal closed
    readonly property var controls: Backend.controls
    implicitHeight: list.y + list.implicitHeight

    Text {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.topMargin: 7
        text: Cfg.t("DISPLAYS AND KEYBOARD")
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
    Column {
        id: list
        anchors.left: parent.left
        anchors.right: parent.right
        y: 36
        spacing: 8
        Repeater {
            model: root.controls?.displays ?? []
            BrightnessCard {
                required property var modelData
                width: list.width
                height: 56
                display: modelData
            }
        }
        BrightnessCard {
            visible: root.controls?.keyboardBrightnessAvailable ?? false
            width: list.width
            height: 56
            keyboardMode: true
        }
    }
}

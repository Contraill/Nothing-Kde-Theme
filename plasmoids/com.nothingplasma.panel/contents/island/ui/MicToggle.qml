import QtQuick
import "."

// Software mute of the default microphone. Unlike the privacy block it needs no
// administrator approval; the filled state shows a muted microphone at a glance.
Rectangle {
    id: root
    property int size: 24

    visible: Audio.inputAvailable
    width: size
    height: size
    radius: size / 2
    color: Audio.inputMuted ? Theme.inverted : ma.containsMouse ? Theme.surfaceHigh : "transparent"
    Accessible.role: Accessible.Button
    Accessible.name: Audio.inputMuted ? Cfg.t("UNMUTE MICROPHONE") : Cfg.t("MUTE MICROPHONE")
    Accessible.onPressAction: Audio.toggleInputMute()

    Behavior on color {
        ColorAnimation {
            duration: Theme.durShort
        }
    }

    Text {
        anchors.centerIn: parent
        text: Audio.inputMuted ? "mic_off" : "mic"
        color: Audio.inputMuted ? Theme.invertedFg : Theme.fgVariant
        font.family: Theme.fontIcons
        font.pixelSize: Math.round(root.size * 0.62)
    }

    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: Audio.toggleInputMute()
    }
}

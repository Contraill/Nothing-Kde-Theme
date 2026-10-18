import QtQuick
import "."

// Software mute of the default microphone. Unlike the privacy block it needs no
// administrator approval; the filled state shows a muted microphone at a glance.
Rectangle {
    id: root
    property int size: 24
    // An ALSA block from the retired privacy button outlives the software
    // mute; show it here so it can still be lifted.
    readonly property bool systemBlocked: ControlHub.microphoneBlocked || ControlHub.microphonePartial

    visible: Audio.inputAvailable || systemBlocked
    width: size
    height: size
    radius: size / 2
    color: systemBlocked ? Theme.alert : Audio.inputMuted ? Theme.inverted : ma.containsMouse ? Theme.surfaceHigh : "transparent"
    Accessible.role: Accessible.Button
    Accessible.name: systemBlocked ? Cfg.t("MIC BLOCKED") : Audio.inputMuted ? Cfg.t("UNMUTE MICROPHONE") : Cfg.t("MUTE MICROPHONE")
    Accessible.onPressAction: root.activate()
    function activate() {
        if (systemBlocked) ControlHub.toggleMicrophone();
        else Audio.toggleInputMute();
    }

    Behavior on color {
        ColorAnimation {
            duration: Theme.durShort
        }
    }

    Text {
        anchors.centerIn: parent
        text: Audio.inputMuted || root.systemBlocked ? "mic_off" : "mic"
        color: root.systemBlocked || Audio.inputMuted ? Theme.invertedFg : Theme.fgVariant
        font.family: Theme.fontIcons
        font.pixelSize: Math.round(root.size * 0.62)
    }

    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.activate()
    }
}

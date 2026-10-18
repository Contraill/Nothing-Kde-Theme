import QtQuick
import "."

// Volume and microphone changes, shown in the compact island in place of the
// clock; Plasma's own audio OSD is turned off while this is enabled.
Item {
    id: root
    property bool shown: false
    property string icon: ""
    property real level: 0
    property bool showLevel: true
    property string label: ""
    // Startup and device switches also change the volume; ignore those.
    property bool armed: false
    property var lastSink: null

    implicitWidth: row.implicitWidth
    implicitHeight: 24
    opacity: shown ? 1 : 0
    visible: opacity > 0
    Behavior on opacity {
        NumberAnimation {
            duration: Theme.durShort
        }
    }

    function show(icon, level, label, showLevel) {
        if (!root.armed || !Cfg.audioOsd || Backend.expanded || Backend.preview) return;
        root.icon = icon;
        root.level = level;
        root.label = label;
        root.showLevel = showLevel;
        root.shown = true;
        hideTimer.restart();
    }
    function showVolume() {
        // The bar says enough; a text label would run under the mini player.
        root.show(Audio.muted ? Icons.volMute : Audio.volume > 0.5 ? Icons.volHigh : Icons.volLow,
                  Audio.volume, Audio.muted ? Cfg.t("MUTED") : "", !Audio.muted);
    }
    Timer { id: hideTimer; interval: 1500; onTriggered: root.shown = false }
    Timer { interval: 3000; running: true; onTriggered: { root.lastSink = Audio.sink; root.armed = true; } }
    Connections {
        target: Audio
        function onVolumeChanged() {
            if (Audio.sink !== root.lastSink) { root.lastSink = Audio.sink; return; }
            root.showVolume();
        }
        function onMutedChanged() { root.showVolume(); }
        function onInputMutedChanged() {
            root.show(Audio.inputMuted ? "mic_off" : "mic", 0, Audio.inputMuted ? Cfg.t("MUTED") : Cfg.t("ON"), false);
        }
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 8
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.icon
            color: Theme.fg
            font.family: Theme.fontIcons
            font.pixelSize: 18
        }
        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            visible: root.showLevel
            width: 64
            height: 4
            radius: 2
            color: Theme.surfaceHigh
            Rectangle {
                width: parent.width * Math.min(1, root.level / Audio.maxVolume)
                height: parent.height
                radius: parent.radius
                color: root.level > 1 ? Theme.alert : Theme.fg
                Behavior on width {
                    NumberAnimation {
                        duration: Theme.durShort
                    }
                }
            }
        }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            visible: root.label.length > 0
            text: root.label
            color: Theme.fgVariant
            font.family: Theme.font
            font.pixelSize: Theme.labelMedium
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import org.kde.plasma.private.volume as PA
import "."

// Sound: output and microphone levels (with what the microphone hears now),
// then every output and input; clicking one makes it the default.
Item {
    id: root

    signal closed
    implicitHeight: content.implicitHeight + 44

    // The monitoring stream exists only while this panel is open.
    PA.VolumeMonitor {
        id: heard
        target: Audio.source
    }

    function deviceName(device): string {
        return device?.description || device?.name || Cfg.t("Unknown");
    }
    // Headsets, headphones (Bluetooth counts) and screens get their own icon.
    function deviceIcon(device, output) {
        const name = (device?.name ?? "").toLowerCase();
        const form = String(device?.formFactor ?? "");
        if (form === "headset" || form === "hands-free") return "headset_mic";
        if (form === "headphone" || name.includes("bluez")) return "headphones";
        if (form === "tv" || name.includes("hdmi")) return "tv";
        return output ? "speaker" : "mic";
    }

    // A level card: a control on the left (`lead`), the slider, the number.
    component LevelCard: Rectangle {
        id: card
        property Item lead
        property int gap: 12
        property alias track: slider
        property bool alert: false
        width: parent.width
        height: 56
        radius: Theme.shapeLg
        color: Theme.surfaceAlt
        VolumeTrack {
            id: slider
            anchors.left: card.lead ? card.lead.right : card.left
            anchors.leftMargin: card.gap
            anchors.right: number.left
            anchors.rightMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            maxValue: Audio.maxVolume
        }
        Text {
            id: number
            anchors.right: parent.right
            anchors.rightMargin: 14
            anchors.verticalCenter: parent.verticalCenter
            width: 36
            horizontalAlignment: Text.AlignRight
            text: Math.round(slider.shown * 100)
            color: slider.muted ? Theme.fgFaint : card.alert ? Theme.alert : Theme.fg
            font.family: Theme.fontDots
            font.pixelSize: 17
            font.weight: Font.Bold
        }
    }

    component DeviceRow: Rectangle {
        id: row
        property var device: null
        property bool output: true
        readonly property bool current: device !== null && device === (output ? Audio.sink : Audio.source)
        width: content.width
        height: 42
        radius: Theme.shapeMd
        color: current ? Theme.inverted : Qt.alpha(Theme.fg, area.containsMouse ? Theme.stateHover : 0)
        Behavior on color { ColorAnimation { duration: Theme.durShort } }
        Text {
            id: icon
            x: 10
            anchors.verticalCenter: parent.verticalCenter
            text: root.deviceIcon(row.device, row.output)
            color: row.current ? Theme.invertedFg : Theme.fgFaint
            font.family: Theme.fontIcons
            font.pixelSize: 18
        }
        Text {
            anchors.left: icon.right
            anchors.right: tick.left
            anchors.leftMargin: 10
            anchors.rightMargin: 6
            anchors.verticalCenter: parent.verticalCenter
            text: root.deviceName(row.device)
            color: row.current ? Theme.invertedFg : Theme.fg
            font.family: Theme.font
            font.pixelSize: Theme.bodySmall
            font.weight: row.current ? Font.Medium : Font.Normal
            elide: Text.ElideRight
        }
        Text {
            id: tick
            anchors.right: parent.right
            anchors.rightMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            visible: row.current
            text: "check"
            color: Theme.invertedFg
            font.family: Theme.fontIcons
            font.pixelSize: 16
        }
        MouseArea {
            id: area
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: Audio.setDefault(row.device)
        }
    }

    // A list of devices under a heading, or a line saying there are none.
    component DeviceList: Column {
        id: list
        property string title
        property string empty
        property var model
        property bool output: true
        width: parent.width
        spacing: 10
        Text {
            text: Cfg.t(list.title)
            color: Theme.fgFaint
            font.family: Theme.font
            font.pixelSize: Theme.labelSmall
            font.weight: Font.Medium
            font.letterSpacing: 0.6
        }
        Column {
            width: parent.width
            spacing: 2
            Repeater {
                id: rows
                model: list.model
                DeviceRow {
                    required property var model
                    device: model.PulseObject
                    output: list.output
                }
            }
            Text {
                width: parent.width
                visible: rows.count === 0
                horizontalAlignment: Text.AlignHCenter
                topPadding: 8
                bottomPadding: 8
                text: Cfg.t(list.empty)
                color: Theme.fgDim
                font.family: Theme.font
                font.pixelSize: Theme.bodySmall
            }
        }
    }

    Column {
        id: content
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: 10

        PanelHeader {
            title: Cfg.t("SOUND")
            onClosed: root.closed()
        }
        // Output: the speaker mutes; red above 100 %.
        LevelCard {
            lead: speaker
            alert: track.shown > 1
            track.value: Audio.volume
            track.muted: Audio.muted
            track.accessibleName: Cfg.t("OUTPUT")
            track.onMoved: value => Audio.setVolume(value)
            Text {
                id: speaker
                x: 14
                anchors.verticalCenter: parent.verticalCenter
                text: Audio.muted ? "volume_off" : "volume_up"
                color: Audio.muted ? Theme.fgFaint : Audio.volume > 1 ? Theme.alert : Theme.fg
                font.family: Theme.fontIcons
                font.pixelSize: 20
                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -6
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Audio.toggleMute()
                }
            }
        }
        // The microphone, with a thin bar of what it hears under the level.
        LevelCard {
            id: microphone
            visible: Audio.inputAvailable
            lead: microphoneMute
            gap: 8
            track.value: Audio.inputVolume
            track.muted: Audio.inputMuted
            track.accessibleName: Cfg.t("MICROPHONE")
            track.onMoved: value => Audio.setInputVolume(value)
            MicToggle {
                id: microphoneMute
                x: 10
                anchors.verticalCenter: parent.verticalCenter
                size: 30
            }
            Rectangle {
                anchors.left: microphone.track.left
                anchors.top: microphone.track.bottom
                anchors.topMargin: 4
                width: microphone.track.width * Math.min(1, heard.volume) / microphone.track.maxValue
                height: 2
                radius: 1
                visible: heard.available && !Audio.inputMuted
                color: Theme.primary
            }
        }
        DeviceList {
            title: "OUTPUT"
            empty: "No outputs"
            model: Audio.sinkModel
            output: true
        }
        DeviceList {
            title: "INPUT"
            empty: "No inputs"
            model: Audio.sourceModel
            output: false
        }
    }
}

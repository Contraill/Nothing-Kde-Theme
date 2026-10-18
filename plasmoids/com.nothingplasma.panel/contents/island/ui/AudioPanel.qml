import QtQuick
import org.kde.plasma.private.volume as PA
import "."
Item {
    id: popup

    signal closed

    implicitHeight: col.implicitHeight + 44

    // Live microphone level; the monitoring stream exists only while this panel is open.
    PA.VolumeMonitor {
        id: inputLevel
        target: Audio.source
    }

    function label(node): string {
        return node?.description || node?.name || Cfg.t("Unknown");
    }

    Column {
        id: col
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        spacing: 10
        Item {
            width: parent.width
            height: 26

            Text {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                text: Cfg.t("SOUND")
                color: Theme.fgFaint
                font.family: Theme.font
                font.pixelSize: Theme.labelSmall
                font.letterSpacing: Theme.labelSpacing
            }

            Rectangle {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                width: 26
                height: 26
                radius: height / 2
                color: closeMa.containsMouse ? Theme.surfaceHigh : Theme.surfaceAlt

                Behavior on color {
                    ColorAnimation {
                        duration: Theme.durShort
                    }
                }

                Text {
                    anchors.centerIn: parent
                    text: "close"
                    color: closeMa.containsMouse ? Theme.fg : Theme.fgDim
                    font.family: Theme.fontIcons
                    font.pixelSize: 15
                }

                MouseArea {
                    id: closeMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: popup.closed()
                }
            }
        }
        Rectangle {
            id: volCard
            width: parent.width
            height: 56
            radius: Theme.shapeLg
            color: Theme.surfaceAlt

            readonly property real vol: Audio.volume
            readonly property bool muted: Audio.muted
            readonly property real maxVolume: Audio.maxVolume

            Text {
                id: volIcon
                anchors.left: parent.left
                anchors.leftMargin: 14
                anchors.verticalCenter: parent.verticalCenter
                text: volCard.muted ? "volume_off" : "volume_up"
                color: volCard.muted ? Theme.outline : volCard.vol > 1 ? Theme.alert : Theme.fg
                font.family: Theme.fontIcons
                font.pixelSize: 20

                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -6
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Audio.toggleMute()
                }
            }

            Text {
                id: volNum
                anchors.right: parent.right
                anchors.rightMargin: 14
                anchors.verticalCenter: parent.verticalCenter
                width: 36
                horizontalAlignment: Text.AlignRight
                text: Math.round(volTrack.shown * 100)
                color: volCard.muted ? Theme.outline : volTrack.shown > 1 ? Theme.alert : Theme.fg
                font.family: Theme.fontDots
                font.pixelSize: 17
                font.weight: Font.Bold
            }

            VolumeTrack {
                id: volTrack
                anchors.left: volIcon.right
                anchors.leftMargin: 12
                anchors.right: volNum.left
                anchors.rightMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                value: volCard.vol
                maxValue: volCard.maxVolume
                muted: volCard.muted
                accessibleName: Cfg.t("OUTPUT")
                onMoved: value => Audio.setVolume(value)
            }
        }
        Rectangle {
            id: micCard
            visible: Audio.inputAvailable
            width: parent.width
            height: 56
            radius: Theme.shapeLg
            color: Theme.surfaceAlt

            MicToggle {
                id: micMute
                anchors.left: parent.left
                anchors.leftMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                size: 30
            }

            Text {
                id: micNum
                anchors.right: parent.right
                anchors.rightMargin: 14
                anchors.verticalCenter: parent.verticalCenter
                width: 36
                horizontalAlignment: Text.AlignRight
                text: Math.round(micTrack.shown * 100)
                color: Audio.inputMuted ? Theme.outline : Theme.fg
                font.family: Theme.fontDots
                font.pixelSize: 17
                font.weight: Font.Bold
            }

            VolumeTrack {
                id: micTrack
                anchors.left: micMute.right
                anchors.leftMargin: 8
                anchors.right: micNum.left
                anchors.rightMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                value: Audio.inputVolume
                maxValue: Audio.maxVolume
                muted: Audio.inputMuted
                accessibleName: Cfg.t("MICROPHONE")
                onMoved: value => Audio.setInputVolume(value)
            }
            // What the microphone hears right now, under its level control.
            Rectangle {
                anchors.left: micTrack.left
                anchors.top: micTrack.bottom
                anchors.topMargin: 4
                width: micTrack.width * Math.min(1, inputLevel.volume) / micTrack.maxValue
                height: 2
                radius: 1
                visible: inputLevel.available && !Audio.inputMuted
                color: Theme.primary
            }
        }
        component DeviceRow: Rectangle {
            id: dr
            property var node: null
            property bool isOutput: true

            readonly property bool current: dr.node !== null && dr.node === (dr.isOutput ? Audio.sink : Audio.source)

            width: col.width
            height: 42
            radius: Theme.shapeMd
            color: dr.current ? Theme.inverted : drMa.containsMouse ? Qt.alpha(Theme.fg, Theme.stateHover) : Qt.alpha(Theme.fg, 0)

            Behavior on color {
                ColorAnimation {
                    duration: Theme.durShort
                }
            }

            Text {
                id: drIcon
                anchors.left: parent.left
                anchors.leftMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                text: {
                    const n = (dr.node?.name ?? "").toLowerCase();
                    const form = String(dr.node?.formFactor ?? "");
                    if (form === "headset" || form === "hands-free")
                        return "headset_mic";
                    if (form === "headphone" || n.includes("bluez"))
                        return "headphones";
                    if (form === "tv" || n.includes("hdmi"))
                        return "tv";
                    return dr.isOutput ? "speaker" : "mic";
                }
                color: dr.current ? Theme.invertedFg : Theme.fgFaint
                font.family: Theme.fontIcons
                font.pixelSize: 18
            }

            Text {
                anchors.left: drIcon.right
                anchors.leftMargin: 10
                anchors.right: drCheck.left
                anchors.rightMargin: 6
                anchors.verticalCenter: parent.verticalCenter
                text: popup.label(dr.node)
                color: dr.current ? Theme.invertedFg : Theme.fg
                font.family: Theme.font
                font.pixelSize: Theme.bodySmall
                font.weight: dr.current ? Font.Medium : Font.Normal
                elide: Text.ElideRight
            }

            Text {
                id: drCheck
                anchors.right: parent.right
                anchors.rightMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                visible: dr.current
                text: "check"
                color: Theme.invertedFg
                font.family: Theme.fontIcons
                font.pixelSize: 16
            }

            MouseArea {
                id: drMa
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: Audio.setDefault(dr.node)
            }
        }

        component SectionLabel: Text {
            color: Theme.outline
            font.family: Theme.font
            font.pixelSize: Theme.labelSmall
            font.weight: Font.Medium
            font.letterSpacing: 0.6
        }
        SectionLabel {
            text: Cfg.t("OUTPUT")
        }

        Column {
            width: parent.width
            spacing: 2

            Repeater {
                id: sinkRows
                model: Audio.sinkModel

                DeviceRow {
                    required property var model
                    node: model.PulseObject
                    isOutput: true
                }
            }

            Text {
                width: parent.width
                visible: sinkRows.count === 0
                horizontalAlignment: Text.AlignHCenter
                topPadding: 8
                bottomPadding: 8
                text: Cfg.t("No outputs")
                color: Theme.outline
                font.family: Theme.font
                font.pixelSize: Theme.bodySmall
            }
        }
        SectionLabel {
            text: Cfg.t("INPUT")
        }

        Column {
            width: parent.width
            spacing: 2

            Repeater {
                id: sourceRows
                model: Audio.sourceModel

                DeviceRow {
                    required property var model
                    node: model.PulseObject
                    isOutput: false
                }
            }

            Text {
                width: parent.width
                visible: sourceRows.count === 0
                horizontalAlignment: Text.AlignHCenter
                topPadding: 8
                bottomPadding: 8
                text: Cfg.t("No inputs")
                color: Theme.outline
                font.family: Theme.font
                font.pixelSize: Theme.bodySmall
            }
        }
    }
}

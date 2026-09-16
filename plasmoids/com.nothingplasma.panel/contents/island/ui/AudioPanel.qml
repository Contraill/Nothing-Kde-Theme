import QtQuick
import "."
Item {
    id: popup

    signal closed

    implicitHeight: col.implicitHeight + 44

    readonly property var sinks: Audio.sinks
    readonly property var sources: Audio.sources
    Component.onCompleted: {
        Audio.watchers++;
        Audio.refreshDevices();
    }
    Component.onDestruction: Audio.watchers--

    function label(node): string {
        return node?.description ?? node?.name ?? Cfg.t("Unknown");
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
                text: volCard.muted ? "0" : Math.round(volCard.vol * 100)
                color: volCard.vol > 1 && !volCard.muted ? Theme.alert : Theme.fg
                font.family: Theme.fontDots
                font.pixelSize: 17
                font.weight: Font.Bold
            }

            Rectangle {
                id: track
                anchors.left: volIcon.right
                anchors.leftMargin: 12
                anchors.right: volNum.left
                anchors.rightMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                height: 6
                radius: 3
                color: Theme.surfaceHigh

                Rectangle {
                    width: track.width * (volCard.muted ? 0 : Math.min(volCard.vol, 1) / volCard.maxVolume)
                    height: parent.height
                    radius: parent.radius
                    color: Theme.fg
                }
                Rectangle {
                    anchors.right: parent.right
                    width: track.width * (volCard.muted ? 0 : Math.max(volCard.vol - 1, 0) / volCard.maxVolume)
                    height: parent.height
                    radius: parent.radius
                    color: Theme.alert
                }

                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -8
                    cursorShape: Qt.PointingHandCursor

                    function apply(mx) {
                        Audio.setVolume((mx / track.width) * volCard.maxVolume);
                    }

                    onPressed: mouse => {
                        Audio.holding = true;
                        apply(mouse.x);
                    }
                    onPositionChanged: mouse => {
                        if (pressed)
                            apply(mouse.x);
                    }
                    onReleased: Audio.holding = false
                }
            }
        }
        component DeviceRow: Rectangle {
            id: dr
            property var node: null
            property bool isOutput: true

            readonly property bool current: dr.isOutput ? Audio.defaultSink === dr.node?.name : Audio.defaultSource === dr.node?.name

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
                    if (n.includes("bluez"))
                        return "headphones";
                    if (n.includes("hdmi"))
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
                onClicked: {
                    if (!dr.node)
                        return;
                    if (dr.isOutput)
                        Audio.setDefaultSink(dr.node.name);
                    else
                        Audio.setDefaultSource(dr.node.name);
                }
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
                model: popup.sinks

                DeviceRow {
                    required property var modelData
                    node: modelData
                    isOutput: true
                }
            }

            Text {
                width: parent.width
                visible: popup.sinks.length === 0
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
                model: popup.sources

                DeviceRow {
                    required property var modelData
                    node: modelData
                    isOutput: false
                }
            }

            Text {
                width: parent.width
                visible: popup.sources.length === 0
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

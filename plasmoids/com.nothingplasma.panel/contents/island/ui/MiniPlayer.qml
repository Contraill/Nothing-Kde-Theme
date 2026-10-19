// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import org.kde.kirigami as Kirigami
import org.kde.plasma.private.mpris as Mpris
import "."

// The compact pill's player: the cover and three transport buttons in a
// capsule tinted by the cover's dominant colour.
Item {
    id: root

    readonly property var player: Media.player
    readonly property int playback: player?.playbackStatus ?? Mpris.PlaybackStatus.Stopped
    readonly property bool isPlaying: playback === Mpris.PlaybackStatus.Playing
    readonly property bool active: Cfg.showMini && player !== null && playback !== Mpris.PlaybackStatus.Stopped
    readonly property string artUrl: player?.artUrl ?? ""

    // The tint waits for the cover; the ink takes whichever side reads on it.
    readonly property color tint: coverSample.status === Image.Ready ? Theme.mix(Theme.surfaceAlt, coverColours.dominant, 0.30) : Theme.surfaceAlt
    readonly property color ink: 0.2126 * tint.r + 0.7152 * tint.g + 0.0722 * tint.b > 0.55 ? "#393A37" : "#F2F2EF"

    implicitWidth: buttons.implicitWidth + 10
    implicitHeight: 28

    // A small hidden copy of the cover, only for its colours.
    Image {
        id: coverSample
        source: root.artUrl
        asynchronous: true
        cache: true
        sourceSize.width: 64
        sourceSize.height: 64
        visible: false
    }
    Kirigami.ImageColors {
        id: coverColours
        source: coverSample.status === Image.Ready ? coverSample : null
    }

    component TransportButton: Rectangle {
        id: button
        property string icon: ""
        property int iconSize: 16
        signal clicked
        anchors.verticalCenter: parent.verticalCenter
        width: 24
        height: 24
        radius: 12
        color: area.containsMouse ? Qt.alpha(root.ink, 0.20) : "transparent"
        scale: area.pressed ? 0.88 : 1.0
        Behavior on color { ColorAnimation { duration: Theme.durShort } }
        Behavior on scale { NumberAnimation { duration: Theme.durShort; easing.type: Easing.Bezier; easing.bezierCurve: Theme.emphasizedDecel } }
        Text {
            anchors.centerIn: parent
            text: button.icon
            color: root.ink
            font.family: Theme.fontIcons
            font.pixelSize: button.iconSize
        }
        MouseArea {
            id: area
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: button.clicked()
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: root.tint
        Behavior on color { ColorAnimation { duration: Theme.durLong } }

        Row {
            id: buttons
            anchors.centerIn: parent
            spacing: 2
            // The cover in a circle, or a note while there is none.
            Item {
                anchors.verticalCenter: parent.verticalCenter
                width: 22
                height: 22
                Rectangle {
                    anchors.fill: parent
                    radius: width / 2
                    color: Qt.alpha(root.ink, 0.18)
                }
                Kirigami.ShadowedImage {
                    anchors.fill: parent
                    radius: width / 2
                    source: root.artUrl
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    sourceSize.width: 44
                    sourceSize.height: 44
                    visible: status === Image.Ready
                }
                Text {
                    anchors.centerIn: parent
                    visible: root.artUrl === ""
                    text: Icons.music
                    color: root.ink
                    font.family: Theme.fontIcons
                    font.pixelSize: 13
                }
            }
            TransportButton {
                icon: Icons.prev
                onClicked: root.player?.Previous()
            }
            TransportButton {
                icon: root.isPlaying ? Icons.pause : Icons.play
                iconSize: 18
                onClicked: root.player?.PlayPause()
            }
            TransportButton {
                icon: Icons.next
                onClicked: root.player?.Next()
            }
        }
    }
}

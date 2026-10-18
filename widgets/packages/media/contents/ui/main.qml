// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.private.mpris as Mpris
import "../../../../shared" as Glassy
import "components"

// The active MPRIS player: a card with the cover, or a pill.
PlasmoidItem {
    id: root
    preferredRepresentation: fullRepresentation
    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground

    NothingColors {
        id: nColors
        themeMode: Plasmoid.configuration.themeMode
        useSystemAccent: Plasmoid.configuration.useSystemAccent
    }
    Glassy.DotFont { id: dots }

    readonly property int variant: Plasmoid.configuration.widgetVariant
    Mpris.Mpris2Model { id: players }
    readonly property var player: players.currentPlayer
    readonly property bool playing: player?.playbackStatus === Mpris.PlaybackStatus.Playing
    readonly property bool hasTrack: !!player && (player.track ?? "") !== ""
    readonly property string art: player?.artUrl ?? ""
    readonly property real progress: player && player.length > 0 ? Math.min(1, player.position / player.length) : 0
    Timer {
        interval: 1000
        repeat: true
        running: root.playing
        onTriggered: root.player?.updatePosition()
    }

    component Control: QQC2.AbstractButton {
        id: control
        property string iconName: ""
        property bool primary: false
        property real size: 32
        implicitWidth: size
        implicitHeight: size
        enabled: root.hasTrack
        opacity: enabled ? 1 : 0.4
        background: Rectangle {
            radius: width / 2
            color: control.primary ? nColors.textPrimary : control.hovered ? nColors.alpha(nColors.textPrimary, 0.12) : "transparent"
        }
        contentItem: Kirigami.Icon {
            source: control.iconName
            isMask: true
            color: control.primary ? nColors.background : nColors.textPrimary
            implicitWidth: control.size * 0.5
            implicitHeight: control.size * 0.5
        }
    }
    component Controls: Row {
        property real size: 32
        spacing: size * 0.2
        Control { size: parent.size; iconName: "media-skip-backward-symbolic"; Accessible.name: i18n("Previous"); onClicked: root.player.Previous() }
        Control { size: parent.size * 1.2; primary: true; iconName: root.playing ? "media-playback-pause-symbolic" : "media-playback-start-symbolic"; Accessible.name: root.playing ? i18n("Pause") : i18n("Play"); onClicked: root.player.PlayPause() }
        Control { size: parent.size; iconName: "media-skip-forward-symbolic"; Accessible.name: i18n("Next"); onClicked: root.player.Next() }
    }
    // A row of dots that fills with the track's position.
    component Progress: Row {
        id: bar
        property int count: 24
        spacing: (width - count * dotSize) / Math.max(1, count - 1)
        readonly property real dotSize: Math.max(2, height)
        Repeater {
            model: bar.count
            Rectangle {
                required property int index
                width: bar.dotSize
                height: width
                radius: width / 2
                color: index < Math.round(root.progress * bar.count) ? nColors.accent : nColors.divider
            }
        }
    }
    component Cover: Item {
        id: coverItem
        property bool round: false
        readonly property real corner: round ? Math.min(width, height) / 2 : Math.min(width, height) * 0.16
        Rectangle {
            anchors.fill: parent
            radius: coverItem.corner
            color: nColors.alpha(nColors.textPrimary, 0.06)
        }
        Glassy.DotGlyph {
            anchors.centerIn: parent
            width: parent.width * 0.4
            height: width
            visible: cover.status !== Image.Ready
            name: "note"
            color: nColors.textMuted
        }
        Image {
            id: cover
            anchors.fill: parent
            source: root.art
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            sourceSize.width: width * 2
            sourceSize.height: height * 2
            visible: false
        }
        Kirigami.ShadowedTexture {
            anchors.fill: parent
            radius: coverItem.corner
            color: "transparent"
            source: cover
            visible: cover.status === Image.Ready
        }
    }

    fullRepresentation: Item {
        Layout.preferredWidth: root.variant === 1 ? 320 : 220
        Layout.preferredHeight: root.variant === 1 ? 96 : 240
        Layout.minimumWidth: root.variant === 1 ? 220 : 160
        Layout.minimumHeight: root.variant === 1 ? 72 : 180

        Glassy.GlassySurface {
            id: card
            anchors.fill: parent
            anchors.margins: 10
            cornerRadius: root.variant === 1 ? height / 2 : 22
            backgroundColor: nColors.background
            foregroundColor: nColors.textPrimary
        }

        // 0: cover, title, dotted progress and controls.
        ColumnLayout {
            anchors.fill: card
            anchors.margins: 14
            visible: root.variant !== 1
            spacing: 8
            Cover {
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: Math.min(card.width - 28, card.height - 120)
                Layout.preferredHeight: Layout.preferredWidth
            }
            Marquee {
                Layout.fillWidth: true
                text: root.hasTrack ? root.player.track : i18n("Nothing playing")
                color: nColors.textPrimary
                fontSize: 14
            }
            Text {
                Layout.fillWidth: true
                text: root.player?.artist ?? ""
                visible: text !== ""
                color: nColors.textSecondary
                font.pixelSize: 11
                elide: Text.ElideRight
            }
            Progress {
                Layout.fillWidth: true
                Layout.preferredHeight: 3
                visible: root.hasTrack
            }
            Controls {
                Layout.alignment: Qt.AlignHCenter
                size: 30
            }
        }

        // 1: a pill, the cover round on the left.
        RowLayout {
            anchors.fill: card
            anchors.leftMargin: 12
            anchors.rightMargin: 16
            visible: root.variant === 1
            spacing: 10
            Cover {
                round: true
                Layout.preferredWidth: card.height - 24
                Layout.preferredHeight: card.height - 24
            }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2
                Marquee {
                    Layout.fillWidth: true
                    text: root.hasTrack ? root.player.track : i18n("Nothing playing")
                    color: nColors.textPrimary
                    fontSize: 13
                }
                Text {
                    Layout.fillWidth: true
                    text: root.player?.artist ?? ""
                    visible: text !== ""
                    color: nColors.accent
                    font.pixelSize: 10
                    elide: Text.ElideRight
                }
                Progress {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 2
                    count: 18
                    visible: root.hasTrack
                }
            }
            Controls { size: 26 }
        }
    }
}

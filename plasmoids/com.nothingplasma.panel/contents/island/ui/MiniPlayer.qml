import QtQuick
import org.kde.kirigami as Kirigami
import org.kde.plasma.private.mpris as Mpris
import "."
Item {
    id: root

    readonly property var player: Media.player

    readonly property int estado: player?.playbackStatus ?? Mpris.PlaybackStatus.Stopped
    readonly property bool isPlaying: estado === Mpris.PlaybackStatus.Playing
    readonly property bool active: Cfg.showMini && player !== null && estado !== Mpris.PlaybackStatus.Stopped

    readonly property string artUrl: player?.artUrl ?? ""

    implicitWidth: fila.implicitWidth + 10
    implicitHeight: 28
    Image {
        id: cover
        anchors.fill: parent
        source: root.artUrl
        asynchronous: true
        cache: true
        sourceSize.width: 64
        sourceSize.height: 64
        visible: false
    }

    Kirigami.ImageColors {
        id: paleta
        source: cover.status === Image.Ready ? cover : null
    }
    readonly property color tono: cover.status === Image.Ready ? Theme.mezcla(Theme.surfaceAlt, paleta.dominant, 0.30) : Theme.surfaceAlt
    readonly property color tinta: {
        const c = root.tono;
        const luz = 0.2126 * c.r + 0.7152 * c.g + 0.0722 * c.b;
        return luz > 0.55 ? "#393A37" : "#F2F2EF";
    }

    Rectangle {
        id: capsula
        anchors.fill: parent
        radius: height / 2
        color: root.tono
        Behavior on color {
            ColorAnimation {
                duration: Theme.durLong
            }
        }

        Row {
            id: fila
            anchors.centerIn: parent
            spacing: 2
            Item {
                anchors.verticalCenter: parent.verticalCenter
                width: 22
                height: 22

                Rectangle {
                    anchors.fill: parent
                    radius: width / 2
                    color: Qt.alpha(root.tinta, 0.18)
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
                    color: root.tinta
                    font.family: Theme.fontIcons
                    font.pixelSize: 13
                }
            }

            component MiniBtn: Rectangle {
                id: mb
                property string icono: ""
                property int tam: 16
                signal apretado

                anchors.verticalCenter: parent.verticalCenter
                width: 24
                height: 24
                radius: height / 2
                color: mbMa.containsMouse ? Qt.alpha(root.tinta, 0.20) : "transparent"
                scale: mbMa.pressed ? 0.88 : 1.0

                Behavior on color {
                    ColorAnimation {
                        duration: Theme.durShort
                    }
                }
                Behavior on scale {
                    NumberAnimation {
                        duration: Theme.durShort
                        easing.type: Easing.Bezier
                        easing.bezierCurve: Theme.emphasizedDecel
                    }
                }

                Text {
                    anchors.centerIn: parent
                    text: mb.icono
                    color: root.tinta
                    font.family: Theme.fontIcons
                    font.pixelSize: mb.tam
                }

                MouseArea {
                    id: mbMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: mb.apretado()
                }
            }

            MiniBtn {
                icono: Icons.prev
                onApretado: root.player?.Previous()
            }

            MiniBtn {
                icono: root.isPlaying ? Icons.pause : Icons.play
                tam: 18
                onApretado: root.player?.PlayPause()
            }

            MiniBtn {
                icono: Icons.next
                onApretado: root.player?.Next()
            }
        }
    }
}

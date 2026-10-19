import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.private.mpris as Mpris
import org.kde.kirigami as Kirigami
import "components" as Components
import "everything"
import "../../../../shared" as Glassy

PlasmoidItem {
    id: root

    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground
    preferredRepresentation: fullRepresentation

    Components.NothingColors {
        id: nColors
        themeMode: Plasmoid.configuration.themeMode
        useSystemAccent: Plasmoid.configuration.useSystemAccent
        monochrome: Plasmoid.configuration.monochrome
    }

    // MPRIS2 Model
    Mpris.Mpris2Model {
        id: mpris2Model
    }

    // Media properties
    readonly property string track: mpris2Model.currentPlayer?.track ?? ""
    readonly property string artist: mpris2Model.currentPlayer?.artist ?? ""
    readonly property string album: mpris2Model.currentPlayer?.album ?? ""
    readonly property string albumArt: mpris2Model.currentPlayer?.artUrl ?? ""
    readonly property string playerIconName: mpris2Model.currentPlayer?.iconName ?? ""
    readonly property int playbackStatus: mpris2Model.currentPlayer?.playbackStatus ?? 0
    readonly property bool isPlaying: root.playbackStatus === Mpris.PlaybackStatus.Playing
    readonly property bool canGoPrevious: mpris2Model.currentPlayer?.canGoPrevious ?? false
    readonly property bool canGoNext: mpris2Model.currentPlayer?.canGoNext ?? false
    readonly property bool canPlay: mpris2Model.currentPlayer?.canPlay ?? false
    readonly property bool canPause: mpris2Model.currentPlayer?.canPause ?? false
    readonly property real length: mpris2Model.currentPlayer?.length ?? 0

    // Tracked position property that updates during playback
    property real position: 0

    // Sync position from MPRIS when it changes
    Connections {
        target: mpris2Model.currentPlayer
        function onPositionChanged() {
            root.position = mpris2Model.currentPlayer?.position ?? 0
        }
    }

    // Track position during playback
    Timer {
        id: positionTimer
        interval: 250 // Update every 250ms for smooth progress
        running: root.isPlaying && root.length > 0
        repeat: true
        onTriggered: {
            // Increment position by the interval time (in microseconds)
            if (root.position < root.length) {
                root.position += interval * 1000
            }
        }
    }

    // Reset position when track changes
    onTrackChanged: {
        root.position = mpris2Model.currentPlayer?.position ?? 0
    }

    // Sync position when playback starts/stops
    onIsPlayingChanged: {
        root.position = mpris2Model.currentPlayer?.position ?? 0
    }

    // Control functions
    function togglePlaying() {
        if (mpris2Model.currentPlayer) {
            mpris2Model.currentPlayer.PlayPause();
        }
    }

    function next() {
        if (mpris2Model.currentPlayer) {
            mpris2Model.currentPlayer.Next();
        }
    }

    function previous() {
        if (mpris2Model.currentPlayer) {
            mpris2Model.currentPlayer.Previous();
        }
    }

    readonly property int variant: Plasmoid.configuration.widgetVariant
    Glassy.DotFont { id: everyFont }

    fullRepresentation: Item {
        Layout.preferredWidth: root.variant > 0 ? 400 : 200
        Layout.preferredHeight: root.variant === 2 ? 110 : 200
        Layout.minimumWidth: root.variant > 0 ? 300 : 200
        Layout.minimumHeight: root.variant === 2 ? 80 : 200

        // EveryThing-UI's players.
        EveryPlayer {
            anchors.fill: parent
            visible: root.variant > 0
            colors: nColors
            family: everyFont.name
            pill: root.variant === 2
            title: root.track
            artist: root.artist
            artUrl: root.albumArt
            playing: root.isPlaying
            progress: root.length > 0 ? root.position / root.length : 0
            onPrevious: root.previous()
            onPlayPause: root.togglePlaying()
            onNext: root.next()
        }

        // SwipeView container
        QQC2.SwipeView {
            id: swipeView
            visible: root.variant === 0
            anchors.fill: parent
            currentIndex: 0
            clip: true

            // PAGE 1: Album cover carousel design
            Components.AlbumCoverCarousel {
                colors: nColors
                albumArt: root.albumArt
                isPlaying: root.isPlaying
                canGoPrevious: root.canGoPrevious
                canGoNext: root.canGoNext
                canPlay: root.canPlay
                canPause: root.canPause

                onPreviousClicked: root.previous()
                onNextClicked: root.next()
                onPlayPauseClicked: root.togglePlaying()
            }

            // PAGE 2: Compact media player layout
            Components.CompactPlayer {
                colors: nColors
                albumArt: root.albumArt
                track: root.track
                artist: root.artist
                playerIconName: root.playerIconName
                position: root.position
                length: root.length
            }
        }

        // Horizontal Page Indicator (bottom)
        Row {
            visible: root.variant === 0
            anchors {
                bottom: parent.bottom
                bottomMargin: 16
                horizontalCenter: parent.horizontalCenter
            }
            spacing: 8
            z: 100

            Repeater {
                model: swipeView.count

                Rectangle {
                    width: 6
                    height: 6
                    radius: 3
                    color: swipeView.currentIndex === index ? nColors.indicatorActive : nColors.indicatorInactive
                    opacity: swipeView.currentIndex === index ? 0.95 : 0.45

                    Behavior on color {
                        ColorAnimation { duration: 200 }
                    }

                    Behavior on opacity {
                        NumberAnimation { duration: 200 }
                    }

                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -4
                        cursorShape: Qt.PointingHandCursor
                        onClicked: swipeView.currentIndex = index
                    }
                }
            }
        }

        // Mouse wheel support for page navigation
        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.NoButton
            z: 5
            onWheel: {
                if (wheel.angleDelta.y < 0) {
                    swipeView.incrementCurrentIndex()
                } else if (wheel.angleDelta.y > 0) {
                    swipeView.decrementCurrentIndex()
                }
            }
        }
    }
}

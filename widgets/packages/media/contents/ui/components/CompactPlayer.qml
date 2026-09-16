import QtQuick
import "../../../../../shared" as Glassy
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Item {
    id: compactRoot

    // NothingColors reference
    required property QtObject colors

    // Public properties - Media data
    property string albumArt: ""
    property string track: ""
    property string artist: ""
    property string playerIconName: ""
    property real position: 0
    property real length: 0

    Glassy.GlassySurface {
        anchors.fill: parent
        anchors.margins: 10
        backgroundColor: compactRoot.colors.surfaceAlt
        foregroundColor: compactRoot.colors.textPrimary

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 6

            // Top row: Album art + player application icon
            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 80

                RowLayout {
                    anchors.fill: parent
                    spacing: 8

                    // Album artwork thumbnail
                    Rectangle {
                        Layout.preferredWidth: 80
                        Layout.preferredHeight: 80
                        color: compactRoot.colors.surface
                        radius: 12

                        AlbumArtwork {
                            anchors.fill: parent
                            colors: compactRoot.colors
                            artUrl: compactRoot.albumArt
                            cornerRadius: 12
                            backgroundColor: compactRoot.colors.surface
                        }
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    // Player application icon
                    Rectangle {
                        Layout.alignment: Qt.AlignTop | Qt.AlignRight
                        Layout.preferredWidth: 44
                        Layout.preferredHeight: 44
                        radius: 22
                        color: compactRoot.colors.surface
                        opacity: 0.8

                        Kirigami.Icon {
                            anchors.centerIn: parent
                            width: 28
                            height: 28
                            // MPRIS resolves this from the player's desktop-entry ID.
                            source: compactRoot.playerIconName || "media-player"
                            color: compactRoot.colors.textPrimary
                        }
                    }
                }
            }

            // Track title with marquee effect
            MarqueeText {
                Layout.fillWidth: true
                Layout.preferredHeight: 18 + 4
                Layout.topMargin: 4
                Layout.bottomMargin: -4
                text: compactRoot.track || "No Track"
                fontSize: 18
                bold: true
                textColor: compactRoot.colors.textPrimary
            }

            // Artist name
            Text {
                Layout.fillWidth: true
                text: compactRoot.artist || "Unknown Artist"
                font.pixelSize: 12
                Layout.preferredHeight: font.pixelSize + 4
                color: compactRoot.colors.textPlaceholder
                elide: Text.ElideRight
                maximumLineCount: 1
            }

            // Progress bar
            ProgressBar {
                Layout.fillWidth: true
                Layout.preferredHeight: 4
                position: compactRoot.position
                length: compactRoot.length
                backgroundColor: compactRoot.colors.surface
                progressColor: compactRoot.colors.textPrimary
            }

            Item {
                Layout.fillHeight: true
            }
        }
    }
}

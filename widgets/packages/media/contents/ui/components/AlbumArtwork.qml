import QtQuick
import QtQuick.Effects
import "../../../../../shared" as Glassy

Item {
    id: artworkRoot

    // NothingColors reference
    required property QtObject colors

    // Public properties
    property string artUrl: ""
    property int cornerRadius: 20
    property color backgroundColor: colors.background
    property color fallbackIconColor: colors.textMuted

    // Source image (hidden)
    Image {
        id: albumCover
        anchors.fill: parent
        source: artworkRoot.artUrl
        fillMode: Image.PreserveAspectCrop
        smooth: true
        mipmap: true
        visible: false
        layer.enabled: true
    }

    // Mask for rounded corners
    Item {
        id: roundedMask
        anchors.fill: parent
        layer.enabled: true
        visible: false

        Rectangle {
            anchors.fill: parent
            radius: artworkRoot.cornerRadius
            color: "white"
        }
    }

    // Back real artwork only. Empty/loading/failed artwork must not cover the
    // shared glass with a second opaque full-card fallback.
    Rectangle {
        anchors.fill: parent
        color: artworkRoot.backgroundColor
        radius: artworkRoot.cornerRadius
        visible: albumCover.status === Image.Ready
        z: 1
    }

    // MultiEffect with rounded corner mask
    MultiEffect {
        id: albumEffect
        anchors.fill: parent
        source: albumCover
        maskEnabled: true
        maskSource: roundedMask
        visible: albumCover.status === Image.Ready
        z: 2
    }

    // No cover (a browser video, say): the dot note, as on the other players.
    Glassy.DotGlyph {
        anchors.centerIn: parent
        width: Math.min(parent.width, parent.height) * 0.4
        height: width
        visible: albumCover.status !== Image.Ready
        z: 2
        name: "note"
        color: artworkRoot.fallbackIconColor
    }
}

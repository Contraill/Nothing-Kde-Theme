pragma ComponentBehavior: Bound

import QtQuick
import org.kde.kirigami as Kirigami
import "../../island/ui" as Island

FocusScope {
    id: root

    property color accentColor: Kirigami.Theme.highlightColor
    property real surfaceOpacity: 0.72
    property real borderStrength: 0.55
    property real noiseStrength: 0.035
    property bool islandStyle: false
    default property alias contentData: content.data

    NothingPalette { id: nothingPalette; accent: root.accentColor }

    focus: true
    activeFocusOnTab: true

    // Canvas paint commands are retained. Repaint the accent edge immediately
    // when the shared Nothing/KDE accent changes instead of keeping the color
    // that happened to be active when the popup was first created.
    onAccentColorChanged: accentEdge.requestPaint()

    Rectangle {
        id: glass
        anchors.fill: parent
        radius: root.islandStyle ? Island.Theme.expandedRadius : 14
        color: root.islandStyle ? Island.Theme.surface : Qt.rgba(
            nothingPalette.background.r,
            nothingPalette.background.g,
            nothingPalette.background.b,
            Math.max(0.18, Math.min(0.96, root.surfaceOpacity))
        )
        border.width: root.islandStyle ? 0 : 1
        border.color: Qt.rgba(
            nothingPalette.outlineStrong.r,
            nothingPalette.outlineStrong.g,
            nothingPalette.outlineStrong.b,
            Math.max(0.08, Math.min(1.0, root.borderStrength))
        )
        clip: true

        Rectangle {
            visible: !root.islandStyle
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.leftMargin: 14
            anchors.rightMargin: 14
            height: 1
            color: nothingPalette.text
            opacity: nothingPalette.lightMode ? 0.16 : 0.08
        }

        Canvas {
            id: grain
            visible: !root.islandStyle
            anchors.fill: parent
            opacity: root.noiseStrength
            onPaint: {
                const ctx = getContext("2d")
                ctx.clearRect(0, 0, width, height)
                ctx.fillStyle = nothingPalette.text
                const step = 13
                for (let y = 7; y < height; y += step) {
                    for (let x = 7; x < width; x += step) {
                        const phase = ((x / step) + (y / step)) % 3
                        ctx.globalAlpha = phase === 0 ? 0.42 : (phase === 1 ? 0.20 : 0.30)
                        ctx.fillRect(x, y, 1, 1)
                    }
                }
                ctx.globalAlpha = 1
            }
            onWidthChanged: requestPaint()
            onHeightChanged: requestPaint()
            Component.onCompleted: requestPaint()
        }

        Canvas {
            id: accentEdge
            visible: !root.islandStyle
            anchors.fill: parent
            z: 20
            onPaint: {
                const ctx = getContext("2d")
                ctx.clearRect(0, 0, width, height)
                const r = 14
                ctx.beginPath()
                ctx.lineWidth = 2
                ctx.strokeStyle = nothingPalette.accent
                ctx.moveTo(r, 1)
                ctx.quadraticCurveTo(1, 1, 1, r)
                ctx.lineTo(1, height - r)
                ctx.quadraticCurveTo(1, height - 1, r, height - 1)
                ctx.stroke()
            }
            onWidthChanged: requestPaint()
            onHeightChanged: requestPaint()
            Component.onCompleted: requestPaint()
        }

        Item {
            id: content
            anchors.fill: parent
            anchors.margins: 1
        }
    }
}

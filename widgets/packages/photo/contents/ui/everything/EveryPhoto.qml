// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import org.kde.kirigami as Kirigami
import "../../../../../shared" as Glassy

// EveryThing-UI's photo frames (Prince-1652, MIT): the picture inset 10 px
// in a square, a circle, a wide block or a wide pill.
Glassy.EveryFrame {
    id: f
    // Unused; every design takes it so settings previews can pass it.
    property string family
    // "square", "circle", "wide" or "wide-pill"
    property string shape: "square"
    property string source: ""
    property int fillMode: Image.PreserveAspectCrop
    property bool grayscale: false
    signal choose()
    designWidth: shape.startsWith("wide") ? 390 : 190
    designHeight: 190
    card: shape === "circle" ? "circle" : shape === "wide-pill" ? "pill" : "block"

    Rectangle {
        id: well
        x: 10 * f.s
        y: 10 * f.s
        width: parent.width - 20 * f.s
        height: parent.height - 20 * f.s
        radius: f.shape === "circle" || f.shape === "wide-pill" ? height / 2 : 20 * f.s
        color: f.track
        Text {
            anchors.centerIn: parent
            visible: picture.status !== Image.Ready
            width: parent.width * 0.8
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.Wrap
            text: i18n("Double-click to choose an image").toLocaleUpperCase(Qt.locale().name)
            color: f.colors.textPrimary
            font.pixelSize: Math.max(9, 12 * f.s)
        }
        Kirigami.ShadowedImage {
            id: picture
            anchors.fill: parent
            radius: well.radius
            source: f.source
            fillMode: f.fillMode
            visible: status === Image.Ready
        }
        MouseArea {
            anchors.fill: parent
            onDoubleClicked: f.choose()
        }
    }
}

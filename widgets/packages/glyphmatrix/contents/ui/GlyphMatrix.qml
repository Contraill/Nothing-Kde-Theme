// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import "../../../../shared" as Glassy
import "matrix.js" as Matrix

// The round 25 x 25 dot matrix, after the Nothing Phone (3)'s Glyph Matrix.
// It shows `frame` (625 values, see matrix.js), or with `picture` set an
// image or animation, each dot as bright as the picture under it.
Glassy.EveryFrame {
    id: f
    property var frame: Matrix.empty()
    property url picture
    // Unused; every design takes it so settings previews can pass it.
    property string family
    designWidth: 190
    designHeight: 190
    card: "circle"

    readonly property color lit: colors.textPrimary
    readonly property color unlit: colors.alpha(colors.textPrimary, 0.08)
    readonly property bool gpu: GraphicsInfo.api !== GraphicsInfo.Software
    readonly property bool showPicture: picture.toString() !== ""
    // The matrix inside the round card.
    readonly property real side: 160 * s

    Canvas {
        id: dots
        x: (f.canvas.width - f.side) / 2
        y: (f.canvas.height - f.side) / 2
        width: f.side
        height: f.side
        // The picture without graphics acceleration: its first frame, read once.
        visible: !f.showPicture || !f.gpu
        onWidthChanged: requestPaint()
        onPaint: {
            const ctx = getContext("2d");
            ctx.reset();
            const cell = width / Matrix.size, r = cell * 0.38;
            let values = f.frame;
            if (f.showPicture) {
                if (!isImageLoaded(f.picture)) return;
                ctx.drawImage(f.picture, 0, 0, Matrix.size, Matrix.size);
                const data = ctx.getImageData(0, 0, Matrix.size, Matrix.size).data;
                ctx.reset();
                values = [];
                for (let i = 0; i < Matrix.size * Matrix.size; ++i)
                    values.push((0.2126 * data[i * 4] + 0.7152 * data[i * 4 + 1] + 0.0722 * data[i * 4 + 2]) / 255 * data[i * 4 + 3] / 255);
            }
            for (let y = 0; y < Matrix.size; ++y)
                for (let x = 0; x < Matrix.size; ++x) {
                    if (!Matrix.inside(x, y)) continue;
                    const v = values[y * Matrix.size + x] ?? 0;
                    const k = Math.max(0, Math.min(1, v));
                    ctx.fillStyle = v === 2 ? f.colors.accent
                        : Qt.rgba(f.unlit.r + (f.lit.r - f.unlit.r) * k, f.unlit.g + (f.lit.g - f.unlit.g) * k,
                                  f.unlit.b + (f.lit.b - f.unlit.b) * k, f.unlit.a + (f.lit.a - f.unlit.a) * k);
                    ctx.beginPath();
                    ctx.arc((x + 0.5) * cell, (y + 0.5) * cell, r, 0, 2 * Math.PI);
                    ctx.fill();
                }
        }
        onImageLoaded: requestPaint()
        Connections {
            target: f
            function onFrameChanged() { dots.requestPaint() }
            function onLitChanged() { dots.requestPaint() }
            function onPictureChanged() { if (f.showPicture && !f.gpu) dots.loadImage(f.picture); dots.requestPaint() }
        }
        Component.onCompleted: if (f.showPicture && !f.gpu) loadImage(f.picture)
    }

    // The picture, live: a GIF keeps playing on the matrix.
    AnimatedImage {
        id: image
        width: f.side
        height: f.side
        // Drawn only into the sample below (hideSource).
        source: f.showPicture && f.gpu ? f.picture : ""
        fillMode: Image.PreserveAspectCrop
        playing: f.visible
    }
    ShaderEffectSource {
        id: sample
        sourceItem: image
        hideSource: true
        textureSize: Qt.size(Matrix.size * 2, Matrix.size * 2)
        visible: false
    }
    ShaderEffect {
        x: dots.x
        y: dots.y
        width: f.side
        height: f.side
        visible: f.showPicture && f.gpu
        property variant source: sample
        property color lit: f.lit
        property color unlit: f.unlit
        fragmentShader: Qt.resolvedUrl("../shaders/matrix.frag.qsb")
    }
}

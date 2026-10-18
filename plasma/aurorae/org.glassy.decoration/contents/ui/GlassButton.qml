// Original Glassy button artwork; native Aurorae actions.
import QtQuick
import org.kde.kwin.decoration
import "Glyphs.js" as Glyphs

DecorationButton {
    id: root
    property color ink
    property color hoverColor
    // 0 line glyphs, 1 dot-matrix glyphs, 2 traffic lights (Glassy setting).
    property int glyphStyle: 0
    readonly property color lightColor: buttonType === DecorationOptions.DecorationButtonClose ? "#ff5f57"
        : buttonType === DecorationOptions.DecorationButtonMinimize ? "#febc2e"
        : buttonType === DecorationOptions.DecorationButtonMaximizeRestore ? "#28c840" : "transparent"
    width: 30; height: 30
    readonly property var strokes: {
        switch (buttonType) {
        case DecorationOptions.DecorationButtonClose: return Glyphs.close;
        case DecorationOptions.DecorationButtonMinimize: return Glyphs.minimize;
        case DecorationOptions.DecorationButtonMaximizeRestore: return decoration.client.maximized ? Glyphs.restore : Glyphs.maximize;
        case DecorationOptions.DecorationButtonKeepAbove: return Glyphs.above;
        case DecorationOptions.DecorationButtonKeepBelow: return Glyphs.below;
        case DecorationOptions.DecorationButtonShade: return decoration.client.shaded ? Glyphs.below : Glyphs.above;
        case DecorationOptions.DecorationButtonOnAllDesktops: return Glyphs.desktops;
        case DecorationOptions.DecorationButtonQuickHelp: return Glyphs.help;
        default: return Glyphs.menu;
        }
    }
    Rectangle {
        anchors.fill: parent; anchors.margins: 2
        radius: 7
        color: root.hoverColor
        opacity: root.glyphStyle === 2 ? 0 : root.pressed || root.toggled ? 0.22 : root.hovered ? 0.12 : 0
        Behavior on opacity { NumberAnimation { duration: 100 } }
    }
    Canvas {
        id: glyph
        anchors.centerIn: parent
        width: Math.round(root.width * .6); height: width
        onWidthChanged: requestPaint()
        onPaint: {
            const ctx = getContext("2d"); ctx.reset();
            ctx.scale(width / 16, height / 16);
            if (root.glyphStyle === 2) {
                // Traffic light: coloured disc, glyph only while hovered.
                ctx.beginPath(); ctx.arc(8, 8, 6, 0, 2 * Math.PI);
                ctx.fillStyle = root.lightColor.a > 0 ? root.lightColor : Qt.rgba(root.ink.r, root.ink.g, root.ink.b, .35);
                ctx.globalAlpha = root.pressed ? .75 : 1;
                ctx.fill();
                if (!root.hovered) return;
                ctx.globalAlpha = 1;
                ctx.translate(8, 8); ctx.scale(.55, .55); ctx.translate(-8, -8);
                ctx.strokeStyle = Qt.rgba(0, 0, 0, .6);
            } else {
                ctx.strokeStyle = root.ink;
            }
            if (root.glyphStyle === 1) {
                // Dot matrix: the same strokes sampled every 3 units.
                ctx.fillStyle = root.ink;
                const seen = {};
                for (const line of root.strokes) {
                    for (let i = 0; i + 3 < line.length; i += 2) {
                        const length = Math.hypot(line[i+2] - line[i], line[i+3] - line[i+1]);
                        const steps = Math.max(1, Math.round(length / 3));
                        for (let step = 0; step <= steps; ++step) {
                            const x = Math.round(line[i] + (line[i+2] - line[i]) * step / steps);
                            const y = Math.round(line[i+1] + (line[i+3] - line[i+1]) * step / steps);
                            if (seen[x + ":" + y]) continue;
                            seen[x + ":" + y] = true;
                            ctx.beginPath(); ctx.arc(x, y, 1.15, 0, 2 * Math.PI); ctx.fill();
                        }
                    }
                }
                return;
            }
            ctx.lineWidth = 1.4;
            ctx.lineCap = "round"; ctx.lineJoin = "round";
            for (const line of root.strokes) {
                ctx.beginPath(); ctx.moveTo(line[0], line[1]);
                for (let i = 2; i < line.length; i += 2) ctx.lineTo(line[i], line[i+1]);
                ctx.stroke();
            }
        }
        Connections {
            target: root
            function onInkChanged() { glyph.requestPaint(); }
            function onStrokesChanged() { glyph.requestPaint(); }
            function onGlyphStyleChanged() { glyph.requestPaint(); }
            function onHoveredChanged() { if (root.glyphStyle === 2) glyph.requestPaint(); }
            function onPressedChanged() { if (root.glyphStyle === 2) glyph.requestPaint(); }
        }
    }
}

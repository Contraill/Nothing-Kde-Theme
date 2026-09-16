// Original Glassy button artwork; native Aurorae actions.
import QtQuick
import org.kde.kwin.decoration
import "Glyphs.js" as Glyphs

DecorationButton {
    id: root
    property color ink
    property color hoverColor
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
        opacity: root.pressed || root.toggled ? 0.22 : root.hovered ? 0.12 : 0
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
            ctx.strokeStyle = root.ink; ctx.lineWidth = 1.4;
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
        }
    }
}

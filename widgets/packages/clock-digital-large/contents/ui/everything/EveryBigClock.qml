// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtQuick.Shapes
import "../../../../../shared" as Glassy

// EveryThing-UI's big wallpaper clocks (Prince-1652, MIT), drawn with our
// own faces instead of their fonts: blocks (Clock 1, and its dual tone),
// big dots (Clock 2), bubbles with dots (Clock 3 and its inverse) and an
// outline (Clock 4). The colon always takes the accent.
Item {
    id: clock
    required property QtObject colors
    // "blocks", "blocks-dual", "dots", "bubbles", "bubbles-inverse", "outline"
    property string face: "blocks"
    property string time: "00:00"
    property string dotFamily
    // Settings previews pass the dot face here too.
    property string family
    property string outlineFamily

    readonly property bool gridFace: face.startsWith("blocks") || face.startsWith("bubbles")
    // Cells: 3 per block digit (+1 gap), 2 per bubble digit (+0.5 gap); five or three tall.
    readonly property real columns: face.startsWith("blocks") ? time.length * 4 - 1 - 2 : time.length * 2.5 - 0.5 - 1
    readonly property real rows: face.startsWith("blocks") ? 5 : 3
    readonly property real cell: Math.floor(Math.min(width / columns, height / rows))

    Glassy.EveryDigits {
        anchors.centerIn: parent
        visible: clock.gridFace
        text: clock.time
        face: clock.face.startsWith("blocks") ? "blocks" : "bubbles"
        cell: clock.cell
        color: clock.colors.textPrimary
        secondColor: clock.face === "blocks-dual" ? clock.colors.textMuted : color
        colonColor: clock.colors.accent
        dotColor: clock.face === "bubbles" ? clock.colors.background : clock.colors.accent
    }

    // Clock 2: the dot face, large, light build so the dots stay apart.
    Row {
        anchors.centerIn: parent
        visible: clock.face === "dots"
        Repeater {
            model: clock.time.split("")
            Text {
                required property string modelData
                text: modelData
                color: modelData === ":" ? clock.colors.accent : clock.colors.textPrimary
                font.family: clock.dotFamily || clock.family
                font.pixelSize: Math.min(clock.height * 1.15, clock.width / clock.time.length * 1.55)
            }
        }
    }

    // Clock 4: hollow figures, the colon filled. Hours, colon and minutes are
    // laid out in one path space so they share a baseline; the drawn outline
    // is centred by its own bounds, not by font metrics.
    Shape {
        id: outline
        visible: clock.face === "outline"
        readonly property int split: Math.max(0, clock.time.indexOf(":"))
        readonly property real size: Math.min(clock.height * 1.15, clock.width / clock.time.length * 1.6)
        x: (clock.width - boundingRect.width) / 2 - boundingRect.x
        y: (clock.height - boundingRect.height) / 2 - boundingRect.y
        preferredRendererType: Shape.CurveRenderer
        TextMetrics { id: before; font: hours.font; text: clock.time.slice(0, outline.split) }
        TextMetrics { id: through; font: hours.font; text: clock.time.slice(0, outline.split + 1) }
        ShapePath {
            strokeWidth: Math.max(2, outline.size * 0.035)
            strokeColor: clock.colors.textPrimary
            fillColor: "transparent"
            joinStyle: ShapePath.RoundJoin
            PathText {
                id: hours
                font.family: clock.outlineFamily
                font.pixelSize: outline.size
                text: clock.time.slice(0, outline.split)
            }
            PathText {
                x: through.advanceWidth
                font: hours.font
                text: clock.time.slice(outline.split + 1)
            }
        }
        ShapePath {
            strokeWidth: -1
            fillColor: clock.colors.accent
            PathText {
                x: before.advanceWidth
                font: hours.font
                text: ":"
            }
        }
    }
}

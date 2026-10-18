// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import "glyphs.js" as Glyphs

// A dot-matrix picture from glyphs.js, fitted into the item: "#" dots take
// `color`, "+" dots `accentColor`.
Item {
    id: glyph
    property string name: "cloudy"
    property color color: "white"
    property color accentColor: color
    property real dotRatio: 0.78

    readonly property var rows: Glyphs.rows(name)
    readonly property int columns: rows.length ? rows[0].length : 1
    readonly property real cell: Math.min(width / columns, height / Math.max(1, rows.length))
    implicitWidth: columns * 6
    implicitHeight: rows.length * 6

    Item {
        anchors.centerIn: parent
        width: glyph.columns * glyph.cell
        height: glyph.rows.length * glyph.cell
        Repeater {
            model: glyph.rows.length * glyph.columns
            Rectangle {
                required property int index
                readonly property string mark: glyph.rows[Math.floor(index / glyph.columns)][index % glyph.columns]
                visible: mark !== "."
                x: (index % glyph.columns) * glyph.cell + (glyph.cell - width) / 2
                y: Math.floor(index / glyph.columns) * glyph.cell + (glyph.cell - height) / 2
                width: glyph.cell * glyph.dotRatio
                height: width
                radius: width / 2
                color: mark === "+" ? glyph.accentColor : glyph.color
            }
        }
    }
}

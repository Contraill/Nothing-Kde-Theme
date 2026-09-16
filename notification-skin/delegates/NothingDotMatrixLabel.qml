import QtQuick
import org.kde.kirigami as Kirigami

Item {
    id: root

    property string text: "NOW"
    property color dotColor: Kirigami.Theme.textColor
    property color accentColor: Kirigami.Theme.highlightColor
    property real uiScale: 0.78

    readonly property real step: 2.75 * root.uiScale
    readonly property real glyphWidth: 3 * root.step
    readonly property real glyphGap: 2.2 * root.uiScale

    implicitWidth: Math.ceil(root.text.length * (root.glyphWidth + root.glyphGap) + root.glyphGap)
    implicitHeight: Math.ceil(5 * root.step + 4 * root.uiScale)

    Canvas {
        id: canvas
        anchors.fill: parent

        property var patterns: ({
            "A":["010","101","111","101","101"], "B":["110","101","110","101","110"],
            "C":["011","100","100","100","011"], "D":["110","101","101","101","110"],
            "E":["111","100","110","100","111"], "F":["111","100","110","100","100"],
            "G":["011","100","101","101","011"], "H":["101","101","111","101","101"],
            "I":["111","010","010","010","111"], "J":["001","001","001","101","010"],
            "K":["101","101","110","101","101"], "L":["100","100","100","100","111"],
            "M":["101","111","111","101","101"], "N":["101","111","111","111","101"],
            "O":["010","101","101","101","010"], "P":["110","101","110","100","100"],
            "Q":["010","101","101","111","011"], "R":["110","101","110","101","101"],
            "S":["011","100","010","001","110"], "T":["111","010","010","010","010"],
            "U":["101","101","101","101","111"], "V":["101","101","101","101","010"],
            "W":["101","101","111","111","101"], "X":["101","101","010","101","101"],
            "Y":["101","101","010","010","010"], "Z":["111","001","010","100","111"],
            "0":["111","101","101","101","111"], "1":["010","110","010","010","111"],
            "2":["111","001","111","100","111"], "3":["111","001","111","001","111"],
            "4":["101","101","111","001","001"], "5":["111","100","111","001","111"],
            "6":["111","100","111","101","111"], "7":["111","001","010","010","010"],
            "8":["111","101","111","101","111"], "9":["111","101","111","001","111"]
        })

        onPaint: {
            const ctx = getContext("2d")
            ctx.clearRect(0, 0, width, height)
            const value = root.text.toUpperCase()
            let x = root.glyphGap / 2
            const top = 1.7 * root.uiScale
            for (let i = 0; i < value.length; ++i) {
                const ch = value[i]
                if (ch === " ") {
                    x += root.glyphWidth * 0.65 + root.glyphGap
                    continue
                }
                const pattern = patterns[ch]
                if (pattern) {
                    for (let row = 0; row < 5; ++row) {
                        for (let col = 0; col < 3; ++col) {
                            if (pattern[row][col] !== "1") {
                                continue
                            }
                            ctx.beginPath()
                            ctx.fillStyle = root.dotColor
                            ctx.arc(x + col * root.step, top + row * root.step, Math.max(0.72, 0.9 * root.uiScale), 0, Math.PI * 2)
                            ctx.fill()
                        }
                    }
                }
                x += root.glyphWidth + root.glyphGap
            }
        }
    }

    onTextChanged: canvas.requestPaint()
    onDotColorChanged: canvas.requestPaint()
    onAccentColorChanged: canvas.requestPaint()
    onUiScaleChanged: canvas.requestPaint()
    Component.onCompleted: canvas.requestPaint()
}

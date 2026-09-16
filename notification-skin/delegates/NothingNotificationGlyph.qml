// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import org.kde.kirigami as Kirigami

Item {
    id: root
    property string glyph: "notification"
    property color color: "#f2f2ed"
    property color accentColor: color
    property bool lit: false
    readonly property int duration: 2600
    property real elapsed: duration
    property bool ready: false
    property bool played: false
    implicitWidth: 34
    implicitHeight: 40
    Accessible.ignored: true

    // The two arcs and stem answer the edge strips at different moments.
    // Once the arrival phrase ends, the original static symbol remains.
    function startArrival(): void {
        if (ready && lit && !played && Kirigami.Units.longDuration > 1) {
            played = true
            arrival.restart()
        }
    }
    onLitChanged: {
        if (lit) {
            startArrival()
        } else {
            arrival.stop()
            elapsed = duration
            played = false
        }
    }
    Component.onCompleted: {
        ready = true
        startArrival()
    }
    function partLevel(part): real {
        const baseline = 0.2 + 0.8 * Math.max(0, Math.min(1, (elapsed - 2200) / 400))
        const starts = [180, 1060, 620]
        const echoes = [1570, 1940, 1760]
        function pulse(start) {
            const t = elapsed - start
            if (t < 0 || t >= 440) return 0
            if (t < 70) return Math.sin(t / 70 * Math.PI / 2)
            if (t < 150) return 1
            const tail = 1 - (t - 150) / 290
            return tail * tail
        }
        return Math.max(baseline, pulse(starts[part]), pulse(echoes[part]))
    }
    NumberAnimation {
        id: arrival
        target: root
        property: "elapsed"
        from: 0
        to: root.duration
        duration: root.duration
        easing.type: Easing.Linear
    }
    onElapsedChanged: canvas.requestPaint()
    Connections {
        target: Kirigami.Units
        function onLongDurationChanged(): void {
            if (Kirigami.Units.longDuration <= 1) {
                arrival.stop()
                root.elapsed = root.duration
            }
        }
    }

    Canvas {
        id: canvas
        anchors.fill: parent
        onPaint: {
            const ctx = getContext("2d")
            ctx.clearRect(0, 0, width, height)
            ctx.strokeStyle = root.color
            ctx.lineWidth = 3
            ctx.lineCap = "round"
            const cx = width / 2
            const cy = 15
            ctx.globalAlpha = root.partLevel(0)
            ctx.beginPath()
            ctx.arc(cx, cy, 10, 0.12 * Math.PI, 0.86 * Math.PI)
            ctx.stroke()
            ctx.globalAlpha = root.partLevel(1)
            ctx.beginPath()
            ctx.arc(cx, cy, 10, 1.05 * Math.PI, 1.8 * Math.PI)
            ctx.stroke()
            ctx.globalAlpha = root.partLevel(2)
            ctx.beginPath()
            ctx.moveTo(cx, 30)
            ctx.lineTo(cx, 36)
            ctx.stroke()
            ctx.globalAlpha = 1
            if (root.glyph === "critical") {
                ctx.fillStyle = root.accentColor
                ctx.beginPath()
                ctx.arc(cx, cy, 2, 0, Math.PI * 2)
                ctx.fill()
            }
        }
    }
    onColorChanged: canvas.requestPaint()
    onAccentColorChanged: canvas.requestPaint()
    onGlyphChanged: canvas.requestPaint()
}

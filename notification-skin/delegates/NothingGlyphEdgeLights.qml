// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import org.kde.kirigami as Kirigami

Item {
    id: root
    objectName: "nothingGlyphEdgeLights"

    property bool active: false
    property bool lightMode: false
    readonly property bool playing: arrival.running
    readonly property int duration: 2600
    property real elapsed: duration
    property bool ready: false
    property bool played: false
    visible: playing
    Accessible.ignored: true

    function startArrival(): void {
        if (ready && active && !played && Kirigami.Units.longDuration > 1) {
            played = true
            arrival.restart()
        }
    }

    onActiveChanged: {
        if (active) {
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

    // A single spatial phrase, independent of notification expiry/hover.
    // Fast ignition, a brief hold, then a softer phosphor-like decay.
    function pulse(time, start, attack, hold, release): real {
        const t = time - start
        if (t < 0 || t >= attack + hold + release) return 0
        if (t < attack) return Math.sin(t / attack * Math.PI / 2)
        if (t < attack + hold) return 1
        const tail = 1 - (t - attack - hold) / release
        return tail * tail
    }

    function level(segment): real {
        const starts = [0, 430, 870, 1250, 690]
        const first = pulse(elapsed, starts[segment], 75, 100, 350)
        // Uneven echoes avoid a synchronized frame around the card.
        const echoes = [1760, 2050, 1640, 1870, 2140]
        const strengths = [0.65, 0.95, 0.82, 0.5, 0.75]
        const echo = pulse(elapsed, echoes[segment], 60, 55, 320)
        return Math.max(first, echo * strengths[segment])
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
    onElapsedChanged: strips.requestPaint()
    onLightModeChanged: strips.requestPaint()
    Connections {
        target: Kirigami.Units
        function onLongDurationChanged(): void {
            if (Kirigami.Units.longDuration <= 1) arrival.stop()
        }
    }

    Canvas {
        id: strips
        anchors.fill: parent
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()

        function path(ctx, segment): void {
            const inset = 5.5
            const radius = 15
            ctx.beginPath()
            // Each strip has its own silhouette and position: no mirrored
            // corners or centered dash. Coordinates adapt to taller popups.
            switch (segment) {
            case 0:
                ctx.moveTo(Math.min(width * 0.31, 110), inset)
                ctx.lineTo(inset + radius, inset)
                ctx.arcTo(inset, inset, inset, inset + radius, radius)
                ctx.lineTo(inset, Math.min(height * 0.46, 52))
                break
            case 1:
                ctx.moveTo(width - inset, height * 0.37)
                ctx.lineTo(width - inset, height * 0.59)
                break
            case 2:
                ctx.moveTo(width * 0.36, height - inset)
                ctx.lineTo(width * 0.73, height - inset)
                break
            case 3:
                ctx.moveTo(width * 0.76, inset)
                ctx.lineTo(width * 0.83, inset)
                break
            case 4:
                ctx.moveTo(inset, height * 0.73)
                ctx.lineTo(inset, height * 0.81)
                break
            }
        }

        onPaint: {
            const ctx = getContext("2d")
            ctx.clearRect(0, 0, width, height)
            ctx.lineCap = "round"
            ctx.lineJoin = "round"
            for (let segment = 0; segment < 5; ++segment) {
                const intensity = root.level(segment)
                if (intensity <= 0.005) continue
                // Invert the emitter on the light surface: a crisp charcoal
                // core with a restrained soft edge, not white on off-white.
                const widths = root.lightMode ? [9, 6, 3.5, 2.4] : [11, 7, 4, 2]
                const strengths = root.lightMode ? [0.012, 0.025, 0.10, 0.94] : [0.035, 0.08, 0.23, 1]
                const rgb = root.lightMode ? "18,18,16," : "255,255,249,"
                for (let layer = 0; layer < widths.length; ++layer) {
                    path(ctx, segment)
                    ctx.strokeStyle = "rgba(" + rgb + (strengths[layer] * intensity) + ")"
                    ctx.lineWidth = widths[layer]
                    ctx.stroke()
                }
            }
        }
    }
}

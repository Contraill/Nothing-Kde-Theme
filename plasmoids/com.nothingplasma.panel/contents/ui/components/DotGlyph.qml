import QtQuick

Item {
    id: root

    property string name: "apps"
    property color color: "white"
    property color accentColor: color
    property real dotRadius: 1.12
    property real step: 2.45

    implicitWidth: 18
    implicitHeight: 18

    Canvas {
        id: canvas
        anchors.fill: parent

        property var patterns: ({
            "apps": [
                "1000001",
                "0000000",
                "0010100",
                "0002000",
                "0010100",
                "0000000",
                "1000001"
            ],
            "launcher": [
                "0101010",
                "0000000",
                "1010101",
                "0002000",
                "1010101",
                "0000000",
                "0101010"
            ],
            "settings": [
                "001010100",
                "011111110",
                "110000011",
                "110111011",
                "111101111",
                "110111011",
                "110000011",
                "011111110",
                "001010100"
            ],
            "power": [
                "0001000",
                "0001000",
                "0101010",
                "1000001",
                "1000001",
                "0100010",
                "0011100"
            ],
            "wifi": [
                "001111100",
                "010000010",
                "100000001",
                "000111000",
                "001000100",
                "000010000",
                "000010000",
                "000000000",
                "000000000"
            ],
            "wifi-off": [
                "201111100",
                "020000010",
                "102000001",
                "000211000",
                "001020100",
                "000012000",
                "000010200",
                "000000020",
                "000000002"
            ],
            "bluetooth": [
                "0001000",
                "0001100",
                "1001010",
                "0101100",
                "0101100",
                "1001010",
                "0001100"
            ],
            "lock": [
                "0011100",
                "0100010",
                "0100010",
                "1111111",
                "1001001",
                "1001001",
                "1111111"
            ],
            "coffee": [
                "001010000",
                "000101000",
                "001010000",
                "000000000",
                "011111000",
                "010001110",
                "010001010",
                "011111100",
                "001110000"
            ],
            "sleep": [
                "000111000",
                "001000000",
                "010000000",
                "100000000",
                "100000010",
                "010000100",
                "001001000",
                "000110000",
                "000000000"
            ],
            "restart": [
                "000111000",
                "001000100",
                "010000010",
                "100000000",
                "100010000",
                "100111000",
                "010010000",
                "001000000",
                "000000000"
            ],
            "close": [
                "1000001",
                "0100010",
                "0010100",
                "0001000",
                "0010100",
                "0100010",
                "1000001"
            ],
            "shutdown": [
                "000010000",
                "000010000",
                "001010100",
                "010000010",
                "100000001",
                "100000001",
                "010000010",
                "001111100",
                "000000000"
            ],
            "volume": [
                "0001000",
                "0011001",
                "0111010",
                "1111010",
                "0111010",
                "0011001",
                "0001000"
            ],
            "brightness": [
                "1001001",
                "0010100",
                "0101010",
                "0011100",
                "0101010",
                "0010100",
                "1001001"
            ],
            "volume-mute": [
                "0001001",
                "0011010",
                "0111100",
                "1111000",
                "0111100",
                "0011010",
                "0001001"
            ],
            "keyboard-brightness": [
                "0010100",
                "0101010",
                "0011100",
                "1111111",
                "1000001",
                "1010101",
                "1111111"
            ],
            "battery": [
                "000000000",
                "011111100",
                "010000110",
                "010000011",
                "010000011",
                "010000110",
                "011111100",
                "000000000",
                "000000000"
            ],
            "battery-charge": [
                "000000000",
                "011111100",
                "010020110",
                "010200011",
                "012220011",
                "010020110",
                "011111100",
                "000000000",
                "000000000"
            ],
            "monitor": [
                "1111111",
                "1000001",
                "1010101",
                "1000001",
                "1111111",
                "0001000",
                "0011100"
            ],
            "calendar": [
                "0100010",
                "1111111",
                "1000001",
                "1010101",
                "1000001",
                "1010101",
                "1111111"
            ],
            "chevron-left": [
                "0000100",
                "0001000",
                "0010000",
                "0100000",
                "0010000",
                "0001000",
                "0000100"
            ],
            "chevron-right": [
                "0100000",
                "0010000",
                "0001000",
                "0000100",
                "0001000",
                "0010000",
                "0100000"
            ],
            "sun": [
                "1001001",
                "0010100",
                "0101010",
                "0011100",
                "0101010",
                "0010100",
                "1001001"
            ],
            "moon": [
                "0011100",
                "0100000",
                "1000000",
                "1001000",
                "1000100",
                "0100010",
                "0011100"
            ],
            "microphone": [
                "00100",
                "01110",
                "01010",
                "01010",
                "01110",
                "00100",
                "01110"
            ],
            "microphone-mute": [
                "10100",
                "01110",
                "01110",
                "01010",
                "11110",
                "00100",
                "01110"
            ],
            "menu": [
                "0000000",
                "0010100",
                "0000000",
                "0012100",
                "0000000",
                "0010100",
                "0000000"
            ],
            "media-prev": [
                "0000000",
                "0100100",
                "0110100",
                "0111100",
                "0110100",
                "0100100",
                "0000000"
            ],
            "media-play": [
                "0000000",
                "0100000",
                "0110000",
                "0111000",
                "0110000",
                "0100000",
                "0000000"
            ],
            "media-pause": [
                "0000000",
                "0110110",
                "0110110",
                "0110110",
                "0110110",
                "0110110",
                "0000000"
            ],
            "media-next": [
                "0000000",
                "0010010",
                "0011010",
                "0011110",
                "0011010",
                "0010010",
                "0000000"
            ],
            "cpu": [
                "0011100",
                "0111110",
                "1100011",
                "1101011",
                "1100011",
                "0111110",
                "0011100"
            ],
            "memory": [
                "0000000",
                "0111110",
                "0101010",
                "0101010",
                "0101010",
                "0111110",
                "0000000"
            ],
            "gpu": [
                "0000000",
                "0111110",
                "0100010",
                "0101110",
                "0101010",
                "0111110",
                "0000000"
            ],
            "network": [
                "0010000",
                "0111000",
                "1010100",
                "0010000",
                "0010101",
                "0001110",
                "0000100"
            ],
            "disk": [
                "0111110",
                "1100011",
                "1011101",
                "1010101",
                "1011101",
                "1100011",
                "0111110"
            ],
            "temperature": [
                "0011000",
                "0100100",
                "0100100",
                "0100100",
                "0100100",
                "0111100",
                "0011000"
            ],
            "search": [
                "0011100",
                "0100010",
                "1000001",
                "1000001",
                "0100010",
                "0011100",
                "0000110"
            ]
        })

        function drawDot(ctx, x, y, fill, radius) {
            ctx.beginPath()
            ctx.fillStyle = fill
            ctx.arc(x, y, radius, 0, Math.PI * 2)
            ctx.fill()
        }

        function drawArcDots(ctx, cx, cy, radius, startAngle, endAngle, count, fill, dotRadius) {
            if (count <= 1) return
            for (let i = 0; i < count; ++i) {
                const t = i / (count - 1)
                const angle = startAngle + (endAngle - startAngle) * t
                canvas.drawDot(ctx,
                               cx + Math.cos(angle) * radius,
                               cy + Math.sin(angle) * radius,
                               fill,
                               dotRadius)
            }
        }

        function drawLauncher(ctx) {
            const w = width
            const h = height
            const r = Math.max(0.8, root.dotRadius)
            const xs = [w * 0.28, w * 0.50, w * 0.72]
            const ys = [h * 0.28, h * 0.50, h * 0.72]
            for (let y = 0; y < 3; ++y) {
                for (let x = 0; x < 3; ++x) {
                    canvas.drawDot(ctx, xs[x], ys[y], (x === 1 && y === 1) ? root.accentColor : root.color, r)
                }
            }
        }

        function drawWifi(ctx, disabled) {
            const m = Math.min(width, height)
            const cx = width / 2
            const cy = height * 0.73
            const r = Math.max(0.78, root.dotRadius * 0.92)
            const start = Math.PI * 1.17
            const end = Math.PI * 1.83
            canvas.drawArcDots(ctx, cx, cy, m * 0.39, start, end, 11, root.color, r)
            canvas.drawArcDots(ctx, cx, cy, m * 0.27, start, end, 8, root.color, r)
            canvas.drawArcDots(ctx, cx, cy, m * 0.15, start, end, 5, root.color, r)
            canvas.drawDot(ctx, cx, cy, disabled ? root.accentColor : root.color, r * 1.15)
            if (disabled) {
                for (let i = 0; i < 7; ++i) {
                    const t = i / 6
                    canvas.drawDot(ctx,
                                   width * (0.22 + 0.56 * t),
                                   height * (0.20 + 0.60 * t),
                                   root.accentColor,
                                   r)
                }
            }
        }


        function drawPower(ctx) {
            // Nothing OS uses the familiar IEC power mark: one vertical stem
            // entering an open circular ring. Draw it as dots, with the ring
            // intentionally reaching slightly lower than the old glyph so it
            // does not look vertically squashed.
            const m = Math.min(width, height)
            const cx = width / 2
            const cy = height * 0.585
            const r = Math.max(0.76, root.dotRadius * 0.88)
            canvas.drawArcDots(ctx, cx, cy, m * 0.29, -Math.PI * 0.20, Math.PI * 1.20, 15, root.color, r)
            const stemTop = height * 0.14
            const stemBottom = height * 0.48
            for (let i = 0; i < 5; ++i) {
                const t = i / 4
                canvas.drawDot(ctx, cx, stemTop + (stemBottom - stemTop) * t, root.color, r)
            }
        }

        function drawRestart(ctx) {
            // Circular arrow matching the visual language used by Nothing OS
            // power menus, but rendered with the island's dotted treatment.
            const m = Math.min(width, height)
            const cx = width / 2
            const cy = height / 2
            const r = Math.max(0.76, root.dotRadius * 0.88)
            const ring = m * 0.29
            canvas.drawArcDots(ctx, cx, cy, ring, -Math.PI * 0.47, Math.PI * 1.12, 14, root.color, r)
            canvas.drawDot(ctx, cx + ring * 0.84, cy - ring * 0.73, root.color, r)
            canvas.drawDot(ctx, cx + ring * 0.96, cy - ring * 0.35, root.color, r)
            canvas.drawDot(ctx, cx + ring * 0.58, cy - ring * 0.44, root.color, r)
        }

        function drawSleep(ctx) {
            // Nothing OS represents sleep with a crescent moon. Keep the same
            // silhouette while translating it into a sparse dot matrix.
            const r = Math.max(0.76, root.dotRadius * 0.88)
            const pts = [
                [0.61,0.17],[0.46,0.20],[0.34,0.29],[0.27,0.42],
                [0.25,0.56],[0.31,0.70],[0.42,0.80],[0.57,0.84],
                [0.70,0.79],[0.78,0.70],[0.66,0.70],[0.56,0.65],
                [0.49,0.56],[0.47,0.46],[0.50,0.35],[0.55,0.26]
            ]
            for (let i = 0; i < pts.length; ++i) {
                canvas.drawDot(ctx, width * pts[i][0], height * pts[i][1], root.color, r)
            }
        }

        function drawCoffee(ctx) {
            // User-selected Stay Awake metaphor: compact cup + handle + steam.
            const r = Math.max(0.74, root.dotRadius * 0.86)
            const pts = [
                [0.34,0.18],[0.39,0.27],[0.35,0.36],
                [0.55,0.14],[0.60,0.23],[0.56,0.32],
                [0.24,0.45],[0.37,0.45],[0.50,0.45],[0.63,0.45],
                [0.24,0.57],[0.24,0.69],[0.34,0.78],[0.47,0.80],[0.60,0.74],[0.63,0.62],
                [0.70,0.50],[0.78,0.53],[0.80,0.62],[0.76,0.69],[0.68,0.70],
                [0.31,0.86],[0.44,0.86],[0.57,0.86],[0.69,0.86]
            ]
            for (let i = 0; i < pts.length; ++i) {
                canvas.drawDot(ctx, width * pts[i][0], height * pts[i][1], root.color, r)
            }
        }

        function drawBattery(ctx, charging) {
            const w = width
            const h = height
            const r = Math.max(0.75, root.dotRadius * 0.86)
            const left = w * 0.16
            const right = w * 0.76
            const top = h * 0.31
            const bottom = h * 0.69
            const xCount = 6
            const yCount = 4
            for (let i = 0; i < xCount; ++i) {
                const x = left + (right - left) * i / (xCount - 1)
                canvas.drawDot(ctx, x, top, root.color, r)
                canvas.drawDot(ctx, x, bottom, root.color, r)
            }
            for (let j = 1; j < yCount - 1; ++j) {
                const y = top + (bottom - top) * j / (yCount - 1)
                canvas.drawDot(ctx, left, y, root.color, r)
                canvas.drawDot(ctx, right, y, root.color, r)
            }
            canvas.drawDot(ctx, w * 0.84, h * 0.43, root.color, r)
            canvas.drawDot(ctx, w * 0.84, h * 0.57, root.color, r)
            if (charging) {
                const pts = [[0.50,0.36],[0.43,0.50],[0.51,0.50],[0.45,0.65],[0.60,0.46],[0.52,0.46]]
                for (let k = 0; k < pts.length; ++k) {
                    canvas.drawDot(ctx, w * pts[k][0], h * pts[k][1], root.accentColor, r)
                }
            }
        }

        onPaint: {
            const ctx = getContext("2d")
            ctx.clearRect(0, 0, width, height)

            if (root.name === "launcher") {
                canvas.drawLauncher(ctx)
                return
            }
            if (root.name === "wifi" || root.name === "wifi-off") {
                canvas.drawWifi(ctx, root.name === "wifi-off")
                return
            }
            if (root.name === "battery" || root.name === "battery-charge") {
                canvas.drawBattery(ctx, root.name === "battery-charge")
                return
            }
            if (root.name === "power" || root.name === "shutdown") {
                canvas.drawPower(ctx)
                return
            }
            if (root.name === "restart") {
                canvas.drawRestart(ctx)
                return
            }
            if (root.name === "sleep") {
                canvas.drawSleep(ctx)
                return
            }
            if (root.name === "coffee") {
                canvas.drawCoffee(ctx)
                return
            }

            const pattern = patterns[root.name] || patterns["apps"]
            const size = pattern.length
            const dynamicStep = size > 7 ? Math.min(root.step, (Math.min(width, height) - root.dotRadius * 2) / (size - 1)) : root.step
            const total = (size - 1) * dynamicStep
            const ox = (width - total) / 2
            const oy = (height - total) / 2

            for (let row = 0; row < size; ++row) {
                for (let col = 0; col < pattern[row].length; ++col) {
                    const bit = pattern[row][col]
                    if (bit === "0") continue
                    canvas.drawDot(ctx,
                                 ox + col * dynamicStep,
                                 oy + row * dynamicStep,
                                 bit === "2" ? root.accentColor : root.color,
                                 root.dotRadius)
                }
            }
        }
    }

    onNameChanged: canvas.requestPaint()
    onColorChanged: canvas.requestPaint()
    onAccentColorChanged: canvas.requestPaint()
    onDotRadiusChanged: canvas.requestPaint()
    onStepChanged: canvas.requestPaint()
    Component.onCompleted: canvas.requestPaint()
}

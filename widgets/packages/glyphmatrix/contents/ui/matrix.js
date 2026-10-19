// SPDX-License-Identifier: GPL-3.0-or-later
.pragma library

// The round 25 x 25 matrix of a glyph interface. A frame is 625 values, row by
// row: 0 to 1 a dot's brightness, 2 the accent. Drawings are kept as 625
// characters: "." off, "#" on, "+" the accent.
var size = 25;

function inside(x, y) {
    var dx = x + 0.5 - size / 2, dy = y + 0.5 - size / 2;
    return dx * dx + dy * dy <= (size / 2) * (size / 2);
}

function empty() {
    var f = [];
    for (var i = 0; i < size * size; ++i) f.push(0);
    return f;
}

function fromDrawing(text) {
    var f = empty();
    for (var i = 0; i < f.length; ++i) {
        var c = text ? text.charAt(i) : ".";
        f[i] = c === "#" ? 1 : c === "+" ? 2 : 0;
    }
    return f;
}

function toDrawing(frame) {
    var s = "";
    for (var i = 0; i < size * size; ++i) s += frame[i] === 2 ? "+" : frame[i] > 0.5 ? "#" : ".";
    return s;
}

// 3 x 5 digits, the big clock's block face.
var digits = {
    "0": ["###", "#.#", "#.#", "#.#", "###"], "1": [".#.", "##.", ".#.", ".#.", "###"],
    "2": ["###", "..#", "###", "#..", "###"], "3": ["###", "..#", ".##", "..#", "###"],
    "4": ["#.#", "#.#", "###", "..#", "..#"], "5": ["###", "#..", "###", "..#", "###"],
    "6": ["###", "#..", "###", "#.#", "###"], "7": ["###", "..#", "..#", "..#", "..#"],
    "8": ["###", "#.#", "###", "#.#", "###"], "9": ["###", "#.#", "###", "..#", "###"]
};

function put(f, x, y, v) {
    if (x >= 0 && y >= 0 && x < size && y < size) f[y * size + x] = Math.max(f[y * size + x] === 2 ? 2 : f[y * size + x], v);
}

// Hours over minutes, twice the digit size; the seconds run round the edge.
function clock(now, clock24) {
    var f = empty();
    var h = now.getHours();
    if (!clock24) h = h % 12 || 12;
    var text = [(h < 10 ? "0" : "") + h, (now.getMinutes() < 10 ? "0" : "") + now.getMinutes()];
    for (var row = 0; row < 2; ++row)
        for (var d = 0; d < 2; ++d) {
            var g = digits[text[row].charAt(d)];
            for (var gy = 0; gy < 5; ++gy)
                for (var gx = 0; gx < 3; ++gx)
                    if (g[gy].charAt(gx) === "#") {
                        var x0 = 6 + d * 7 + gx * 2, y0 = 2 + row * 11 + gy * 2;
                        put(f, x0, y0, 1); put(f, x0 + 1, y0, 1); put(f, x0, y0 + 1, 1); put(f, x0 + 1, y0 + 1, 1);
                    }
        }
    var a = now.getSeconds() / 60 * 2 * Math.PI - Math.PI / 2;
    var sx = Math.round(12 + Math.cos(a) * 11.6), sy = Math.round(12 + Math.sin(a) * 11.6);
    if (inside(sx, sy)) f[sy * size + sx] = 2;
    return f;
}

// Rings opening out from the middle.
function pulse(t) {
    var f = empty();
    for (var y = 0; y < size; ++y)
        for (var x = 0; x < size; ++x) {
            var r = Math.sqrt((x - 12) * (x - 12) + (y - 12) * (y - 12));
            var wave = (r - t * 7) % 7;
            if (wave < 0) wave += 7;
            f[y * size + x] = Math.max(0, 1 - wave / 2.2) * Math.max(0.15, 1 - r / 14);
        }
    f[12 * size + 12] = 2;
    return f;
}

// A sweeping line with its fading trail.
function radar(t) {
    var f = empty();
    var a = (t * 2.2) % (2 * Math.PI);
    for (var y = 0; y < size; ++y)
        for (var x = 0; x < size; ++x) {
            var behind = (a - Math.atan2(y - 12, x - 12) + 4 * Math.PI) % (2 * Math.PI);
            var r = Math.sqrt((x - 12) * (x - 12) + (y - 12) * (y - 12));
            if (r > 0.5) f[y * size + x] = Math.max(0, 1 - behind / 1.6);
        }
    f[12 * size + 12] = 2;
    return f;
}

// Drops falling at their own pace down each column.
function rain(t) {
    var f = empty();
    for (var x = 0; x < size; ++x) {
        var speed = 6 + (x * 7919 % 11);
        var head = (t * speed + x * 37) % (size + 8) - 4;
        for (var k = 0; k < 6; ++k) {
            var y = Math.floor(head) - k;
            if (y >= 0 && y < size) f[y * size + x] = k === 0 ? 1 : 0.6 - k * 0.1;
        }
    }
    return f;
}

// Conway's game of life on the round matrix; null starts a new one.
function life(cells) {
    var next = [];
    if (!cells) {
        for (var i = 0; i < size * size; ++i) next.push(inside(i % size, Math.floor(i / size)) && Math.random() < 0.3 ? 1 : 0);
        return next;
    }
    for (var y = 0; y < size; ++y)
        for (var x = 0; x < size; ++x) {
            var n = 0;
            for (var dy = -1; dy <= 1; ++dy)
                for (var dx = -1; dx <= 1; ++dx) {
                    if (!dx && !dy) continue;
                    var nx = (x + dx + size) % size, ny = (y + dy + size) % size;
                    n += cells[ny * size + nx] ? 1 : 0;
                }
            var alive = cells[y * size + x];
            next.push(inside(x, y) && (n === 3 || (alive && n === 2)) ? 1 : 0);
        }
    return next;
}

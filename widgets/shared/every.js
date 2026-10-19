// SPDX-License-Identifier: GPL-3.0-or-later
.pragma library

// Helpers for the designs adapted from EveryThing-UI (Prince-1652, MIT):
// Rainmeter points to pixels, and our own two digit faces for the big clocks
// (drawn as SVG paths: one path per glyph, so cells never show seams).

// Rainmeter sizes text in points at 96 dpi.
function px(points, scale) {
    return points * 4 / 3 * scale;
}

// "Blocks": 3x5 cells, every outer corner cut at 45 degrees.
var blocks = {
    "0": ["###", "#.#", "#.#", "#.#", "###"],
    "1": [".##", "..#", "..#", "..#", "..#"],
    "2": ["###", "..#", "###", "#..", "###"],
    "3": ["###", "..#", ".##", "..#", "###"],
    "4": ["#.#", "#.#", "###", "..#", "..#"],
    "5": ["###", "#..", "###", "..#", "###"],
    "6": ["###", "#..", "###", "#.#", "###"],
    "7": ["###", "..#", "..#", "..#", "..#"],
    "8": ["###", "#.#", "###", "#.#", "###"],
    "9": ["###", "#.#", "###", "..#", "###"],
    ":": [".", "#", ".", "#", "."]
};

// "Bubbles": 2x3 cells of squares (#) and quarter discs rounded at the
// top-left (a), top-right (b), bottom-right (c) or bottom-left (d), with
// round dots laid over some cells.
var bubbles = {
    "0": {cells: ["ab", "#.", "dc"], dots: [[1, 1]]},
    "1": {cells: [".#", ".#", ".#"], dots: [[0, 0]]},
    "2": {cells: [".b", "ac", "##"], dots: [[0, 0]]},
    "3": {cells: [".b", ".#", ".c"], dots: [[0, 0], [0, 2]]},
    "4": {cells: ["#.", "d#", ".#"], dots: [[1, 0]]},
    "5": {cells: ["##", "#b", ".c"], dots: [[0, 2]]},
    "6": {cells: ["a.", "#b", "dc"], dots: [[0, 1]]},
    "7": {cells: ["#b", "..", ".#"], dots: [[1, 1]]},
    "8": {cells: [".b", "##", "dc"], dots: [[0, 0]]},
    "9": {cells: ["ab", "d#", ".c"], dots: [[1, 1]]},
    ":": {cells: [".", ".", "."], dots: [[0, 0.5], [0, 1.5]]}
};

function n(v) {
    return Math.round(v * 100) / 100;
}

function square(x, y, c) {
    return "M" + n(x) + " " + n(y) + "H" + n(x + c) + "V" + n(y + c) + "H" + n(x) + "Z";
}

function dot(cx, cy, r) {
    return "M" + n(cx - r) + " " + n(cy) + "A" + n(r) + " " + n(r) + " 0 1 1 " + n(cx + r) + " " + n(cy)
        + "A" + n(r) + " " + n(r) + " 0 1 1 " + n(cx - r) + " " + n(cy) + "Z";
}

// A filled cell of the block face; corners whose two neighbours are empty are cut.
function blockCell(rows, row, col, c) {
    var filled = function(r, k) { return r >= 0 && r < rows.length && k >= 0 && k < rows[0].length && rows[r][k] === "#"; };
    var up = !filled(row - 1, col), down = !filled(row + 1, col), left = !filled(row, col - 1), right = !filled(row, col + 1);
    var x = col * c, y = row * c, k = c / 2, p = [];
    if (up && left) p.push([x, y + k], [x + k, y]); else p.push([x, y]);
    if (up && right) p.push([x + c - k, y], [x + c, y + k]); else p.push([x + c, y]);
    if (down && right) p.push([x + c, y + c - k], [x + c - k, y + c]); else p.push([x + c, y + c]);
    if (down && left) p.push([x + k, y + c], [x, y + c - k]); else p.push([x, y + c]);
    return "M" + p.map(function(q) { return n(q[0]) + " " + n(q[1]); }).join("L") + "Z";
}

function bubbleCell(code, x, y, c) {
    var a = " " + n(c) + " " + n(c) + " 0 0 1 ";
    switch (code) {
    case "#": return square(x, y, c);
    case "a": return "M" + n(x + c) + " " + n(y + c) + "L" + n(x) + " " + n(y + c) + "A" + a + n(x + c) + " " + n(y) + "Z";
    case "b": return "M" + n(x) + " " + n(y + c) + "L" + n(x) + " " + n(y) + "A" + a + n(x + c) + " " + n(y + c) + "Z";
    case "c": return "M" + n(x) + " " + n(y) + "L" + n(x + c) + " " + n(y) + "A" + a + n(x) + " " + n(y + c) + "Z";
    case "d": return "M" + n(x + c) + " " + n(y) + "L" + n(x + c) + " " + n(y + c) + "A" + a + n(x) + " " + n(y) + "Z";
    }
    return "";
}

// {width, height, fill, dots} in pixels for one character at cell size c.
function glyph(face, ch, c) {
    if (face === "bubbles") {
        var g = bubbles[ch];
        if (!g) return {width: c, height: 3 * c, fill: "", dots: ""};
        var fill = "", dots = "";
        for (var r = 0; r < g.cells.length; ++r)
            for (var k = 0; k < g.cells[r].length; ++k)
                if (g.cells[r][k] !== ".") fill += bubbleCell(g.cells[r][k], k * c, r * c, c);
        for (var i = 0; i < g.dots.length; ++i)
            dots += dot((g.dots[i][0] + 0.5) * c, (g.dots[i][1] + 0.5) * c, c / 2);
        return {width: g.cells[0].length * c, height: 3 * c, fill: fill, dots: dots};
    }
    var rows = blocks[ch];
    if (!rows) return {width: c, height: 5 * c, fill: "", dots: ""};
    var path = "";
    for (var row = 0; row < rows.length; ++row)
        for (var col = 0; col < rows[row].length; ++col)
            if (rows[row][col] === "#") path += blockCell(rows, row, col, c);
    return {width: rows[0].length * c, height: 5 * c, fill: path, dots: ""};
}

// Good morning until noon, afternoon until six, evening after.
function greetingKey(hour) {
    return hour < 12 ? "GOOD MORNING" : hour < 18 ? "GOOD AFTERNOON" : "GOOD EVENING";
}

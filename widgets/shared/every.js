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

// The block face's cells as one outline per connected part, holes running the
// other way: cells drawn one by one leave gaps along their shared edges on
// the GPU's curve renderer. Corners turning outward are cut at 45 degrees.
function blockOutline(rows, c) {
    // Every filled cell's edges, clockwise (y down); an edge two cells share cancels out.
    var edges = {};
    var point = function(x, y) { return x + "," + y; };
    var add = function(x0, y0, x1, y1) {
        var back = point(x1, y1) + ">" + point(x0, y0);
        if (back in edges) delete edges[back];
        else edges[point(x0, y0) + ">" + point(x1, y1)] = [x0, y0, x1, y1];
    };
    for (var r = 0; r < rows.length; ++r)
        for (var k = 0; k < rows[r].length; ++k)
            if (rows[r][k] === "#") {
                add(k, r, k + 1, r); add(k + 1, r, k + 1, r + 1);
                add(k + 1, r + 1, k, r + 1); add(k, r + 1, k, r);
            }
    var from = {};
    for (var e in edges) from[point(edges[e][0], edges[e][1])] = edges[e];
    var path = "";
    for (var start in from) {
        if (!from[start]) continue;
        // Walk one loop, keeping only the points where it turns.
        var loop = [], at = start;
        do {
            var edge = from[at]; from[at] = null;
            loop.push([edge[0], edge[1], edge[2] - edge[0], edge[3] - edge[1]]);
            at = point(edge[2], edge[3]);
        } while (at !== start);
        var turns = loop.filter(function(q, i) {
            var p = loop[(i + loop.length - 1) % loop.length];
            return p[2] !== q[2] || p[3] !== q[3];
        });
        var out = [];
        for (var i = 0; i < turns.length; ++i) {
            var q = turns[i], p = turns[(i + turns.length - 1) % turns.length];
            var dx0 = Math.sign(p[2]), dy0 = Math.sign(p[3]), dx1 = Math.sign(q[2]), dy1 = Math.sign(q[3]);
            // Turning right (y down) is an outer corner: cut it by half a cell each way.
            if (dx0 * dy1 - dy0 * dx1 > 0) out.push([q[0] - dx0 / 2, q[1] - dy0 / 2], [q[0] + dx1 / 2, q[1] + dy1 / 2]);
            else out.push([q[0], q[1]]);
        }
        // Two cuts on one cell's side meet in a point: draw it once.
        out = out.filter(function(q, i) {
            var p = out[(i + out.length - 1) % out.length];
            return p[0] !== q[0] || p[1] !== q[1];
        });
        path += "M" + out.map(function(q) { return n(q[0] * c) + " " + n(q[1] * c); }).join("L") + "Z";
    }
    return path;
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
    return {width: rows[0].length * c, height: 5 * c, fill: blockOutline(rows, c), dots: ""};
}

// Good morning until noon, afternoon until six, evening after.
function greetingKey(hour) {
    return hour < 12 ? "GOOD MORNING" : hour < 18 ? "GOOD AFTERNOON" : "GOOD EVENING";
}

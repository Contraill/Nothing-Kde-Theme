import QtQuick
import QtTest
import "../../widgets/shared/every.js" as Every

// The block face is one outline per part: no point drawn twice in a row, and
// holes as their own loops, so the GPU renderer meets no seams between cells.
TestCase {
    name: "EveryBlocks"

    function test_outlines() {
        const loops = {"0": 2, "1": 1, "2": 1, "3": 1, "4": 1, "5": 1, "6": 2, "7": 1, "8": 3, "9": 2, ":": 2};
        for (const ch in loops) {
            const fill = Every.glyph("blocks", ch, 20).fill;
            compare(fill.split("M").length - 1, loops[ch], "loops of " + ch);
            for (const loop of fill.split("M").slice(1)) {
                const points = loop.replace("Z", "").split("L");
                verify(points.length >= 4, "points of " + ch);
                for (let i = 0; i < points.length; ++i)
                    verify(points[i] !== points[(i + 1) % points.length], "a point twice in " + ch);
            }
        }
    }

    function test_one_has_its_flag() {
        // The flag's left side, cut from both ends, meets in one point.
        verify(Every.glyph("blocks", "1", 20).fill.includes("20 10"));
    }
}

#!/usr/bin/env python3
"""Build "Doto Nothing" from Google Fonts' variable Doto (SIL OFL 1.1).

Source: https://github.com/google/fonts/raw/main/ofl/doto/Doto%5BROND,wght%5D.ttf
Doto declares no Reserved Font Name; the family is still renamed so a system
Doto never shadows the bundled one.

  - a static instance with round, heavy dots (ROND 100, wght 900), close to
    the dot-matrix look the theme had before
  - Doto draws the dots of ":" "." ";" as five-dot crosses and "%" from small
    rings, which read as "※" at panel sizes; they get single dots instead
"""
import sys
from fontTools.ttLib import TTFont
from fontTools.ttLib.tables._g_l_y_f import Glyph, GlyphCoordinates
from fontTools.varLib import instancer

FAMILY = 'Doto Nothing'


# 5x7 dot patterns, top row first; one column/row is 100 units, row 0 is the baseline.
PATTERNS = {
    'colon': ['.....', '.....', '..#..', '.....', '..#..', '.....', '.....'],
    'percent': ['##...', '##..#', '...#.', '..#..', '.#...', '#..##', '...##'],
}


def single_dot(font):
    glyf = font['glyf']
    dot = glyf['periodcentered']
    assert dot.numberOfContours == 1, 'periodcentered is no longer one dot'
    coords, ends, flags = dot.getCoordinates(glyf)
    return glyf, dot, list(coords), list(flags)


def set_dots(font, name, centers):
    """Replaces a glyph with single dots at the given (x, y) centres."""
    glyf, dot, coords, flags = single_dot(font)
    cx, cy = 250, 350  # periodcentered sits in the middle column and row
    points, ends = [], []
    for x, y in centers:
        points += [(px + x - cx, py + y - cy) for px, py in coords]
        ends.append(len(points) - 1)
    glyph = Glyph()
    glyph.numberOfContours = len(centers)
    glyph.coordinates = GlyphCoordinates(points)
    glyph.endPtsOfContours = ends
    glyph.flags = bytearray(flags) * len(centers)
    glyph.program = dot.program
    glyf[name] = glyph
    glyph.recalcBounds(glyf)
    font['hmtx'][name] = (font['hmtx'][name][0], glyph.xMin)


def contour_centers(glyf, name):
    glyph = glyf[name]
    coords, start, out = glyph.getCoordinates(glyf)[0], 0, []
    for end in glyph.endPtsOfContours:
        xs = [p[0] for p in coords[start:end + 1]]
        ys = [p[1] for p in coords[start:end + 1]]
        out.append(((min(xs) + max(xs)) // 2, (min(ys) + max(ys)) // 2))
        start = end + 1
    return out


def collapse_crosses(font, name):
    """Keeps the centre of every five-dot cross and drops its four arms."""
    glyf = font['glyf']
    centers = contour_centers(glyf, name)
    present = set(centers)
    arms = ((100, 0), (-100, 0), (0, 100), (0, -100))
    crosses = [c for c in centers if all((c[0] + dx, c[1] + dy) in present for dx, dy in arms)]
    assert crosses, name + ' has no five-dot cross'
    dropped = {(c[0] + dx, c[1] + dy) for c in crosses for dx, dy in arms}
    set_dots(font, name, [c for c in centers if c not in dropped])


def draw_patterns(font):
    for name, rows in PATTERNS.items():
        set_dots(font, name, [(50 + 100 * col, 50 + 100 * (6 - row))
                              for row, line in enumerate(rows) for col, cell in enumerate(line) if cell == '#'])


def rename(font):
    name = font['name']
    for record in list(name.names):
        if record.nameID in (1, 4, 6, 16, 17, 21, 22, 25):
            name.removeNames(nameID=record.nameID)
    name.setName(FAMILY, 1, 3, 1, 0x409)
    name.setName('Regular', 2, 3, 1, 0x409)
    name.setName(FAMILY, 4, 3, 1, 0x409)
    name.setName(FAMILY.replace(' ', '') + '-Regular', 6, 3, 1, 0x409)
    name.setName('Modified by Nothing KDE: round heavy static instance, single-dot colon.', 5, 3, 1, 0x409)
    font['OS/2'].usWeightClass = 400
    font['OS/2'].fsSelection = (font['OS/2'].fsSelection & ~0b1100001) | 0b1000000  # REGULAR
    font['head'].macStyle = 0


def main(source, target):
    font = instancer.instantiateVariableFont(TTFont(source), {'ROND': 100, 'wght': 900})
    for table in ('STAT', 'HVAR', 'MVAR', 'avar', 'fvar', 'gvar'):
        if table in font: del font[table]
    for name in ('period', 'semicolon'):
        collapse_crosses(font, name)
    draw_patterns(font)
    rename(font)
    font.save(target)
    check = TTFont(target)
    assert check['glyf']['colon'].numberOfContours == 2
    assert check['glyf']['period'].numberOfContours == 1
    assert 'fvar' not in check
    print('wrote', target)


if __name__ == '__main__':
    if len(sys.argv) != 3:
        sys.exit('usage: build-doto.py Doto[ROND,wght].ttf DotoNothing.ttf')
    main(sys.argv[1], sys.argv[2])

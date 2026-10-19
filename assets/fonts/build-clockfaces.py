#!/usr/bin/env python3
"""Build the large clock's three grid faces, drawn for Nothing KDE (SIL OFL 1.1).

  build-clockfaces.py OUTPUT_DIR

  Nothing Dotted   4x5 dots that run into each other
  Nothing Tiles    3x5 tiles with hairline gaps and rounded outer corners
  Nothing Stencil  two narrow columns split by a slit, cut where strokes end

Digits only (and a colon for the dots); one em is 1000 units, the glyphs fill
the whole line from the descender to the ascender, as the faces they replace.
"""
import math
import sys
from pathlib import Path
from fontTools.fontBuilder import FontBuilder
from fontTools.pens.ttGlyphPen import TTGlyphPen
from fontTools.misc.timeTools import timestampFromString
from fontTools.ttLib import TTFont

TOP, BOTTOM = 800, -200
COPYRIGHT = 'Copyright 2026 The Nothing KDE Authors'
LICENSE = 'This Font Software is licensed under the SIL Open Font License, Version 1.1.'

DOTTED = {
    '0': ['.##.', '#..#', '#..#', '#..#', '.##.'],
    '1': ['.#', '##', '.#', '.#', '.#'],
    '2': ['###.', '...#', '.##.', '#...', '####'],
    '3': ['###.', '...#', '.##.', '...#', '###.'],
    '4': ['#..#', '#..#', '####', '...#', '...#'],
    '5': ['####', '#...', '###.', '...#', '###.'],
    '6': ['.##.', '#...', '###.', '#..#', '.##.'],
    '7': ['####', '...#', '..#.', '.#..', '.#..'],
    '8': ['.##.', '#..#', '.##.', '#..#', '.##.'],
    '9': ['.##.', '#..#', '.###', '...#', '.##.'],
    ':': ['.', '#', '.', '#', '.'],
}
# "#" a tile; a, b, c, d one rounded corner (top left, top right, bottom right,
# bottom left); "r" a triangle filling the lower right half.
TILES = {
    '0': ['a#b', '#.#', '#.#', '#.#', 'd#c'],
    '1': ['r#.', '.#.', '.#.', '.#.', '###'],
    '2': ['a#b', '..#', 'a#c', '#..', '###'],
    '3': ['##b', '..#', '.##', '..#', '##c'],
    '4': ['#.#', '#.#', 'd##', '..#', '..#'],
    '5': ['###', '#..', '##b', '..#', '##c'],
    '6': ['a#b', '#..', '##b', '#.#', 'd#c'],
    '7': ['###', '..#', '..#', '..#', '..#'],
    '8': ['a#b', '#.#', '###', '#.#', 'd#c'],
    '9': ['a#b', '#.#', 'd##', '..#', '##c'],
}
# Bars per column, top to bottom in tenths of the height; None is one bar in
# the middle, round at both ends.
STENCIL = {
    '0': ([(0, 10)], [(0, 10)]),
    '1': None,
    '2': ([(0, 2), (5, 10)], [(0, 5), (8, 10)]),
    '3': ([(0, 2), (4, 6), (8, 10)], [(0, 5), (5, 10)]),
    '4': ([(0, 6)], [(0, 10)]),
    '5': ([(0, 5), (8, 10)], [(0, 2), (5, 10)]),
    '6': ([(0, 10)], [(0, 2), (5, 10)]),
    '7': ([(0, 2)], [(0, 10)]),
    '8': ([(0, 5), (5, 10)], [(0, 5), (5, 10)]),
    '9': ([(0, 5), (8, 10)], [(0, 10)]),
}


def arc(cx, cy, r, start, end):
    """Off- and on-curve points of a clockwise arc, in quadratic steps of at most 45 degrees."""
    steps = max(1, math.ceil(abs(end - start) / 45))
    step = (end - start) / steps
    points = []
    for i in range(steps):
        a, b = math.radians(start + i * step), math.radians(start + (i + 1) * step)
        middle, reach = (a + b) / 2, r / math.cos((b - a) / 2)
        points.append(('off', (cx + reach * math.cos(middle), cy + reach * math.sin(middle))))
        points.append(('on', (cx + r * math.cos(b), cy + r * math.sin(b))))
    return points


def draw(pen, outline):
    """outline: ('on', point) and ('off', point) items of one closed, clockwise contour."""
    rounded = [(kind, (round(x), round(y))) for kind, (x, y) in outline]
    pen.moveTo(rounded[0][1])
    pending = []
    for kind, point in rounded[1:]:
        if kind == 'off':
            pending.append(point)
        elif pending:
            pen.qCurveTo(*pending, point); pending = []
        else:
            pen.lineTo(point)
    if pending: pen.qCurveTo(*pending, rounded[0][1])
    pen.closePath()


def circle(cx, cy, r):
    return [('on', (cx + r, cy))] + arc(cx, cy, r, 0, -360)[:-1]


def box(x0, y0, x1, y1, radii=(0, 0, 0, 0)):
    """A rectangle, clockwise from its top left; radii: top left, top right, bottom right, bottom left."""
    tl, tr, br, bl = radii
    out = [('on', (x0, y1 - tl))]
    out += arc(x0 + tl, y1 - tl, tl, 180, 90) if tl else []
    out += [('on', (x1 - tr, y1))]
    out += arc(x1 - tr, y1 - tr, tr, 90, 0) if tr else []
    out += [('on', (x1, y0 + br))]
    out += arc(x1 - br, y0 + br, br, 0, -90) if br else []
    out += [('on', (x0 + bl, y0))]
    out += arc(x0 + bl, y0 + bl, bl, -90, -180) if bl else []
    # Drop the repeated start point, and points a zero radius left doubled.
    deduped = []
    for item in out:
        if not deduped or item != deduped[-1]: deduped.append(item)
    if deduped[-1] == deduped[0]: deduped.pop()
    return deduped


def dotted():
    d, sx, sy = 200, 178, 200
    glyphs = {}
    for ch, rows in DOTTED.items():
        pen = TTGlyphPen(None)
        for r, row in enumerate(rows):
            for c, mark in enumerate(row):
                if mark == '#': draw(pen, circle(d / 2 + c * sx, TOP - d / 2 - r * sy, d / 2))
        glyphs[ch] = (pen.glyph(), d + (len(rows[0]) - 1) * sx + 98)
    return glyphs


def tiles():
    gap, cell = 16, (1000 - 4 * 16) / 5
    radius = cell * 0.75
    glyphs = {}
    for ch, rows in TILES.items():
        pen = TTGlyphPen(None)
        for r, row in enumerate(rows):
            for c, mark in enumerate(row):
                x0, y1 = c * (cell + gap), TOP - r * (cell + gap)
                x1, y0 = x0 + cell, y1 - cell
                if mark == 'r':
                    draw(pen, [('on', (x1, y1)), ('on', (x1, y0)), ('on', (x0, y0))])
                elif mark != '.':
                    corner = 'abcd'.find(mark)
                    draw(pen, box(x0, y0, x1, y1, tuple(radius if i == corner else 0 for i in range(4))))
        glyphs[ch] = (pen.glyph(), round(3 * cell + 2 * gap) + 87)
    return glyphs


def stencil():
    slit, cut, width = 15, 30, 110
    glyphs = {}
    for ch, columns in STENCIL.items():
        pen = TTGlyphPen(None)
        if columns is None:
            x0 = (width + slit) / 2
            draw(pen, box(x0, BOTTOM, x0 + width, TOP, (width / 2,) * 4))
        for side, bars in enumerate(columns or ()):
            x0 = side * (width + slit)
            for top, bottom in bars:
                y1 = TOP - top * 100 - (cut / 2 if top else 0)
                y0 = TOP - bottom * 100 + (cut / 2 if bottom < 10 else 0)
                # Only the glyph's own ends are round, on the outer side.
                outer = width if top == 0 else 0, width if bottom == 10 else 0
                radii = (outer[0], 0, 0, outer[1]) if side == 0 else (0, outer[0], outer[1], 0)
                draw(pen, box(x0, y0, x0 + width, y1, radii))
        glyphs[ch] = (pen.glyph(), 2 * width + slit + 20)
    return glyphs


FACES = {
    'NothingDotted.ttf': ('Nothing Dotted', dotted),
    'NothingTiles.ttf': ('Nothing Tiles', tiles),
    'NothingStencil.ttf': ('Nothing Stencil', stencil),
}


def build(family, glyphs, target):
    names = {ch: 'colon' if ch == ':' else 'zero one two three four five six seven eight nine'.split()[int(ch)]
             for ch in glyphs}
    order = ['.notdef', 'space'] + [names[ch] for ch in glyphs]
    empty = TTGlyphPen(None).glyph()
    glyf = {'.notdef': empty, 'space': empty, **{names[ch]: g for ch, (g, _) in glyphs.items()}}
    fb = FontBuilder(1000, isTTF=True)
    fb.setupGlyphOrder(order)
    fb.setupCharacterMap({0x20: 'space', **{ord(ch): names[ch] for ch in glyphs}})
    fb.setupGlyf(glyf)
    table = fb.font['glyf']
    metrics = {'.notdef': (500, 0), 'space': (300, 0)}
    for ch, (_, advance) in glyphs.items():
        g = table[names[ch]]; g.recalcBounds(table)
        metrics[names[ch]] = (advance, g.xMin)
    fb.setupHorizontalMetrics(metrics)
    fb.setupHorizontalHeader(ascent=TOP, descent=BOTTOM, lineGap=90)
    fb.setupNameTable({'familyName': family, 'styleName': 'Regular', 'copyright': COPYRIGHT,
                       'uniqueFontIdentifier': family.replace(' ', '') + '-Regular;1.000',
                       'fullName': family, 'version': 'Version 1.000', 'psName': family.replace(' ', '') + '-Regular',
                       'licenseDescription': LICENSE, 'licenseInfoURL': 'https://openfontlicense.org'})
    fb.setupOS2(sTypoAscender=TOP, sTypoDescender=BOTTOM, sTypoLineGap=90, usWinAscent=TOP, usWinDescent=-BOTTOM,
                sxHeight=0, sCapHeight=TOP, achVendID='NKDE', fsType=0)
    fb.setupPost()
    fb.font.recalcTimestamp = False
    # A fixed date keeps the build reproducible.
    fb.font['head'].created = fb.font['head'].modified = timestampFromString('Tue Oct 20 00:00:00 2026')
    fb.save(target)
    font = TTFont(target)
    assert all(ord(c) in font.getBestCmap() for c in '0123456789'), family
    for name in glyf:
        assert name in ('.notdef', 'space') or font['glyf'][name].numberOfContours > 0, (family, name)


if __name__ == '__main__':
    if len(sys.argv) != 2:
        sys.exit(__doc__)
    for filename, (family, make) in FACES.items():
        build(family, make(), Path(sys.argv[1]) / filename)
        print('wrote', filename)

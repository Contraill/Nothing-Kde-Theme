#!/usr/bin/env python3
"""Build the theme's dot-matrix face, "Nothing Dots", from a variable font.

  build-dotfont.py bitcount BitcountSingle[CRSV,ELSH,ELXP,slnt,wght].ttf NothingDots.ttf
  build-dotfont.py doto Doto[ROND,wght].ttf NothingDots.ttf

Sources (SIL OFL 1.1, no Reserved Font Name), from github.com/google/fonts:
  bitcount  ofl/bitcountsingle  light, with stylistic set 2 baked in: 5x7 digits and
                                capitals instead of 5x6, the colon centred on them (in use)
  doto      ofl/doto            round heavy dots; its ":" "." ";" use five-dot
                                crosses and "%" small rings, which read as "※"
                                at panel sizes, so they get single dots
The family is renamed so a system copy of the source never shadows it.
"""
import sys
from fontTools.ttLib import TTFont
from fontTools.ttLib.tables._g_l_y_f import Glyph, GlyphCoordinates
from fontTools.varLib import instancer

FAMILY = 'Nothing Dots'
FONTS = {
    'bitcount': {'wght': 250, 'ELSH': 0, 'ELXP': 0, 'slnt': 0, 'CRSV': 0},
    'doto': {'ROND': 100, 'wght': 900},
}


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


def bake_single_substitution(font, tag):
    """Points the character map at the feature's alternates, then drops GSUB
    so no contextual rule swaps them back."""
    gsub = font['GSUB'].table
    mapping = {}
    for record in gsub.FeatureList.FeatureRecord:
        if record.FeatureTag != tag: continue
        for index in record.Feature.LookupListIndex:
            for table in gsub.LookupList.Lookup[index].SubTable:
                mapping.update(getattr(getattr(table, 'ExtSubTable', table), 'mapping', None) or {})
    assert mapping, tag + ' not found'
    for subtable in font['cmap'].tables:
        if subtable.isUnicode():
            subtable.cmap = {code: mapping.get(glyph, glyph) for code, glyph in subtable.cmap.items()}
    del font['GSUB']


def centre_colon(font, rows):
    """Bitcount's colon is two element components; place them on the given rows."""
    colon = font['glyf']['colon']
    assert colon.isComposite() and len(colon.components) == len(rows)
    for component, row in zip(colon.components, rows):
        component.y = 100 * row


def rename(font):
    name = font['name']
    for record in list(name.names):
        if record.nameID in (1, 4, 6, 16, 17, 21, 22, 25):
            name.removeNames(nameID=record.nameID)
    name.setName(FAMILY, 1, 3, 1, 0x409)
    # The only face is marked bold: QML asks the dot font for Font.Bold in many
    # places, and synthetic bolding would swell the dots until they touch.
    name.setName('Bold', 2, 3, 1, 0x409)
    name.setName(FAMILY, 4, 3, 1, 0x409)
    name.setName(FAMILY.replace(' ', '') + '-Bold', 6, 3, 1, 0x409)
    name.setName('Static instance built by Nothing KDE (assets/fonts/build-dotfont.py).', 5, 3, 1, 0x409)
    font['OS/2'].usWeightClass = 700
    font['OS/2'].fsSelection = (font['OS/2'].fsSelection & ~0b1100001) | 0b0100000  # BOLD
    font['head'].macStyle = 1


def main(kind, source, target):
    font = instancer.instantiateVariableFont(TTFont(source), FONTS[kind])
    for table in ('STAT', 'HVAR', 'MVAR', 'avar', 'fvar', 'gvar'):
        if table in font: del font[table]
    if kind == 'doto':
        for name in ('period', 'semicolon'):
            collapse_crosses(font, name)
        draw_patterns(font)
    if kind == 'bitcount':
        bake_single_substitution(font, 'ss02')
        centre_colon(font, (2, 4))
    rename(font)
    font.save(target)
    check = TTFont(target)
    assert 'fvar' not in check
    assert all(ord(c) in check.getBestCmap() for c in '0123456789:%.çğıöşüÇĞİÖŞÜ')
    print('wrote', target)


if __name__ == '__main__':
    if len(sys.argv) != 4 or sys.argv[1] not in FONTS:
        sys.exit('usage: build-dotfont.py bitcount|doto SOURCE.ttf NothingDots.ttf')
    main(*sys.argv[1:])

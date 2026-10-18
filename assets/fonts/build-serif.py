#!/usr/bin/env python3
"""Build "Nothing Serif" from Google Fonts' variable Fraunces (SIL OFL 1.1).

Source: https://github.com/google/fonts/raw/main/ofl/fraunces/Fraunces%5BSOFT%2CWONK%2Copsz%2Cwght%5D.ttf
Two static display instances with plain (not "wonky") shapes, renamed so a
system Fraunces never shadows them:

  build-serif.py Fraunces[SOFT,WONK,opsz,wght].ttf OUTPUT_DIR
"""
import sys
from pathlib import Path
from fontTools.ttLib import TTFont
from fontTools.varLib import instancer

INSTANCES = {
    'NothingSerif.ttf': ('Nothing Serif', {'opsz': 144, 'wght': 500, 'SOFT': 0, 'WONK': 0}),
    'NothingSerifLight.ttf': ('Nothing Serif Light', {'opsz': 72, 'wght': 300, 'SOFT': 0, 'WONK': 0}),
}


def build(source, target, family, axes):
    font = instancer.instantiateVariableFont(TTFont(source), axes)
    for table in ('STAT', 'HVAR', 'MVAR', 'avar', 'fvar', 'gvar'):
        if table in font: del font[table]
    name = font['name']
    for record in list(name.names):
        if record.nameID in (1, 2, 4, 6, 16, 17, 21, 22, 25):
            name.removeNames(nameID=record.nameID)
    name.setName(family, 1, 3, 1, 0x409)
    name.setName('Regular', 2, 3, 1, 0x409)
    name.setName(family, 4, 3, 1, 0x409)
    name.setName(family.replace(' ', '') + '-Regular', 6, 3, 1, 0x409)
    name.setName('Static instance of Fraunces built by Nothing KDE (assets/fonts/build-serif.py).', 5, 3, 1, 0x409)
    font['OS/2'].usWeightClass = 400
    font['OS/2'].fsSelection = (font['OS/2'].fsSelection & ~0b1100001) | 0b1000000
    font['head'].macStyle = 0
    font.recalcTimestamp = False
    font.save(target)
    assert all(ord(c) in TTFont(target).getBestCmap() for c in '0123456789çğıöşüÇĞİÖŞÜ')


if __name__ == '__main__':
    if len(sys.argv) != 3:
        sys.exit(__doc__)
    for filename, (family, axes) in INSTANCES.items():
        build(sys.argv[1], Path(sys.argv[2]) / filename, family, axes)
        print('wrote', filename)

#!/usr/bin/env python3
"""Render the settings previews of the styles drawn in main.qml, dark and light.

The styles that live in contents/ui/everything/ preview themselves; these
render with real Plasma (isolated config, and no session bus so no media,
phone or service shows up) into contents/ui/previews/style-<n>-<dark|light>.png.
"""
import argparse
import os
from pathlib import Path
import re
import subprocess
import sys
import tempfile

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'widgets'))
from prepare import prepare

# package: (config key, {style: render size})
STYLES = {
    'weather': ('widgetVariant', {0: '200x200', 1: '200x200', 2: '200x200'}),
    'clock-analog': ('widgetVariant', {0: '200x200', 1: '200x200'}),
    'clock-digital': ('widgetVariant', {0: '200x200', 1: '200x200'}),
    'clock-digital-large': ('fontStyle', {n: '400x200' for n in (0, 2, 3, 4)}),
    'date': ('widgetVariant', {0: '200x200'}),
    'phone': ('widgetVariant', {0: '220x220', 1: '220x220'}),
    'media': ('widgetVariant', {0: '200x200'}),
    'system': ('widgetVariant', {0: '220x220', 1: '220x220', 2: '260x96'}),
    'note': ('widgetVariant', {0: '240x220', 1: '260x64'}),
    'progress': ('widgetVariant', {0: '200x200', 1: '200x200'}),
    'toggles': ('widgetVariant', {0: '270x170', 1: '190x84'}),
}
# Faces a click shows, rendered by starting the widget on them: package:
# [(file name, config key, value, size, staged file, text, replacement)].
TURNED = {
    'date': [('calendar-0', 'widgetVariant', 0, '200x200', 'contents/ui/components/DatePages.qml',
              'property int page: 0\n', 'property int page: 1\n')],
}
# Clocks shown at a fixed time, as the EveryThing faces' previews (10:09).
PINNED = {
    'clock-digital-large': ('contents/ui/main.qml', 'var now = new Date()\n', 'var now = new Date(2026, 9, 19, 10, 9)\n'),
}
# Their numbers come from ksystemstats on the session bus; nothing personal shows.
SESSION_BUS = {'system'}
# Twice the 120 x 76 preview area of a settings card.
BOX = (240, 152)


def photo_frame(out):
    # The frame masks the photo with MultiEffect, which the software renderer
    # skips: draw it as the widget does, the default photo with 20/200 corners.
    from PIL import ImageDraw
    image = Image.open(ROOT / 'widgets/packages/photo/contents/default/nothing.png').convert('RGBA')
    image = image.resize((BOX[1], BOX[1]), Image.LANCZOS)
    mask = Image.new('L', image.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, image.width - 1, image.height - 1), round(BOX[1] * 20 / 200), fill=255)
    image.putalpha(mask)
    image.save(out, optimize=True)


def render(renderer, package, key, style, size, mode, out, patch=None):
    with tempfile.TemporaryDirectory(prefix='nothing-preview-') as td:
        staged = prepare(ROOT / 'widgets/packages' / package, Path(td) / 'applet')
        if patch:
            path, text, replacement = patch
            source = (staged / path).read_text()
            assert text in source, (package, path, text)
            (staged / path).write_text(source.replace(text, replacement))
        config = staged / 'contents/config/main.xml'
        text = config.read_text()
        for name, value in ((key, style), ('themeMode', mode)):
            text, n = re.subn(r'(<entry name="' + name + r'"[^>]*>\s*<default>)-?\d+', lambda m: m[1] + str(value), text)
            assert n == 1, (package, name)
        config.write_text(text)
        raw = Path(td) / 'raw.png'
        env = dict(os.environ, XDG_CONFIG_HOME=td + '/config', XDG_DATA_HOME=td + '/data', XDG_CACHE_HOME=td + '/cache',
                   QT_QPA_PLATFORM='offscreen', QT_QUICK_BACKEND='software', QT_QPA_PLATFORMTHEME='kde',
                   LANG='en_US.UTF-8', LANGUAGE='en', LC_ALL='en_US.UTF-8',
                   NOTHING_RENDER_SIZE=size, NOTHING_RENDER_BACKGROUND='transparent',
                   **({} if package in SESSION_BUS else {'DBUS_SESSION_BUS_ADDRESS': 'unix:path=' + td + '/no-bus'}))
        subprocess.run(['timeout', '-k', '5s', '15s', str(renderer), str(staged), str(raw)],
                       env=env, capture_output=True, check=True)
        image = Image.open(raw).convert('RGBA')
        image = image.crop(image.getbbox())
        image.thumbnail(BOX, Image.LANCZOS)
        image.save(out, optimize=True)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--renderer', type=Path, required=True)
    parser.add_argument('packages', nargs='*', help='only these widgets (default: all)')
    args = parser.parse_args()
    wanted = lambda package: not args.packages or package in args.packages
    # The devices widget reads Bluetooth on the system bus: their names would land in the pictures.
    connected = subprocess.run(['bluetoothctl', 'devices', 'Connected'], capture_output=True, text=True).stdout.strip()
    if connected:
        sys.exit('Disconnect Bluetooth devices first; their names would show in the previews.')
    for package, (key, styles) in STYLES.items():
        if not wanted(package): continue
        folder = ROOT / 'widgets/packages' / package / 'contents/ui/previews'
        folder.mkdir(exist_ok=True)
        for style, size in styles.items():
            for mode, name in ((0, 'dark'), (1, 'light')):
                out = folder / f'style-{style}-{name}.png'
                render(args.renderer, package, key, style, size, mode, out, PINNED.get(package))
                print(out.relative_to(ROOT), flush=True)
    for name in ('dark', 'light') if wanted('photo') else ():
        photo_frame(ROOT / f'widgets/packages/photo/contents/ui/previews/style-0-{name}.png')
    for package, faces in TURNED.items():
        if not wanted(package): continue
        for file, key, value, size, path, text, replacement in faces:
            for mode, name in ((0, 'dark'), (1, 'light')):
                out = ROOT / 'widgets/packages' / package / 'contents/ui/previews' / f'{file}-{name}.png'
                render(args.renderer, package, key, value, size, mode, out, (path, text, replacement))
                print(out.relative_to(ROOT), flush=True)

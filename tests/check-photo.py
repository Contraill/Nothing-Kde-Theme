#!/usr/bin/env python3
"""Render bundled/legacy/custom photo paths through the real shader backend."""
import argparse
import os
from pathlib import Path
import re
import subprocess
import sys
import tempfile
import xml.etree.ElementTree as ET
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'widgets'))
from prepare import prepare


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--renderer', type=Path, required=True)
    args = parser.parse_args()
    for path in ('default/nothing.png', 'default/sample.jpeg', 'custom'):
        for mode in (0, 1):
            with tempfile.TemporaryDirectory(prefix='nothing-photo-check-') as td:
                home = Path(td)
                package = prepare(ROOT / 'widgets/packages/photo', home / 'applet')
                custom = home / 'user photo.png'
                Image.new('RGB', (80, 80), '#d03020').save(custom)
                config = package / 'contents/config/main.xml'
                ET.register_namespace('', 'http://www.kde.org/standards/kcfg/1.0')
                tree = ET.parse(config)
                ns = {'k': 'http://www.kde.org/standards/kcfg/1.0'}
                for entry in tree.findall('.//k:entry', ns):
                    if entry.get('name') == 'imagePath':
                        entry.find('k:default', ns).text = str(custom) if path == 'custom' else path
                    if entry.get('name') == 'themeMode':
                        entry.find('k:default', ns).text = str(mode)
                tree.write(config, encoding='utf-8', xml_declaration=True)
                capture = home / 'photo.png'
                # MultiEffect requires shaders: the Qt Quick software backend omits it.
                env = dict(os.environ, QT_FORCE_STDERR_LOGGING='1', QT_QPA_PLATFORM='offscreen',
                           QT_QPA_PLATFORMTHEME='generic', QT_QUICK_BACKEND='rhi',
                           QSG_RHI_BACKEND='opengl', QSG_RENDER_LOOP='basic', LIBGL_ALWAYS_SOFTWARE='1',
                           XDG_CONFIG_HOME=str(home / 'config'), XDG_DATA_HOME=str(home / 'data'),
                           XDG_CACHE_HOME=str(home / 'cache'))
                result = subprocess.run([str(args.renderer.resolve()), str(package), str(capture)],
                                        env=env, capture_output=True, text=True, timeout=15)
                log = result.stdout + result.stderr
                assert result.returncode == 0, log
                assert not re.search(r'Binding loop|recursive rearrange|ReferenceError|TypeError|Cannot assign|Error loading', log, re.I), log
                image = Image.open(capture).convert('RGB')
                center = image.crop((80, 175, 320, 225))
                if path == 'custom':
                    r, g, b = image.getpixel((200, 200))
                    assert r > 150 and g < 80 and b < 80, (r, g, b)
                else:
                    assert sum(min(rgb) > 180 for rgb in (center.getpixel((x, y)) for x in range(center.width) for y in range(center.height))) > 700, 'Default logo is missing'
                    assert max(image.getpixel((200, 100))) < 10, 'Default black background changed'
                print('PASS photo', path, 'mode', mode, flush=True)


if __name__ == '__main__':
    main()

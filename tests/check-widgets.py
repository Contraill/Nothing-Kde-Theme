#!/usr/bin/env python3
"""Load each standalone applet with real Plasma and isolated config (no desktop edits)."""
from concurrent.futures import ThreadPoolExecutor
import argparse
import os
from pathlib import Path
import re
import subprocess
import tempfile
import sys

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'widgets'))
from prepare import prepare


def check(job):
    package, variant, mode, renderer, screenshots = job
    with tempfile.TemporaryDirectory(prefix='nothing-widget-check-') as td:
        directory = Path(td)
        copied = directory / 'applet'
        prepare(package, copied)
        config = copied / 'contents/config/main.xml'
        text = config.read_text()
        text = re.sub(r'(<entry name="widgetVariant"[^>]*>\s*<default>)-?\d+', lambda m: m[1] + str(variant), text)
        text = re.sub(r'(<entry name="themeMode"[^>]*>\s*<default>)\d+', lambda m: m[1] + str(mode), text)
        config.write_text(text)
        name = package.name + '-' + str(variant) + '-' + ('dark' if mode == 0 else 'light')
        screenshot = screenshots / (name + '.png')
        env = dict(os.environ, XDG_CONFIG_HOME=td + '/config', XDG_DATA_HOME=td + '/data',
                   XDG_CACHE_HOME=td + '/cache',
                   QT_FORCE_STDERR_LOGGING='1', QT_QPA_PLATFORM='offscreen', QT_QUICK_BACKEND='software', QT_QPA_PLATFORMTHEME='kde',
                   QT_LOGGING_RULES='qml.info=true')
        extra = ['--calendar'] if package.name == 'date' and variant == 0 else []
        result = subprocess.run(['timeout', '15s', str(renderer), str(copied), str(screenshot)] + extra,
                                env=env, capture_output=True, text=True)
        output = result.stdout + result.stderr
        bad = [line for line in output.splitlines() if re.search(
            r'Binding loop|Polish loop|recursive rearrange|Error loading|is not a type|Type .* unavailable|ReferenceError|TypeError|Cannot assign|module .*not installed|No such file.*\.(qml|ttf|otf)', line, re.I)]
        return name, result.returncode == 0 and not bad and screenshot.exists() and 'NOTHING_WIDGET_RENDERED 1' in output, '\n'.join(bad), output


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--renderer', type=Path, required=True)
    parser.add_argument('--screenshots', type=Path, required=True)
    args = parser.parse_args()
    args.screenshots.mkdir(parents=True, exist_ok=True)
    jobs = []
    for package in sorted((ROOT / 'widgets/packages').iterdir()):
        styles = {'weather': 4, 'clock-analog': 4, 'clock-digital': 5, 'date': 4, 'phone': 4, 'media': 3, 'photo': 5,
                  'system': 8, 'note': 3, 'progress': 6, 'toggles': 10, 'greeting': 2, 'visualizer': 3, 'glyphmatrix': 7, 'glyph': 9}
        variants = range(styles.get(package.name, 1))
        jobs.extend((package, variant, mode, args.renderer, args.screenshots) for variant in variants for mode in (0, 1))
    failed = False
    with ThreadPoolExecutor(max_workers=4) as pool:
        for name, ok, errors, output in pool.map(check, jobs):
            print(('PASS ' if ok else 'FAIL ') + name + ('\n' + errors if errors else ''), flush=True)
            if not ok: print(output[-6000:], flush=True)
            failed |= not ok
    raise SystemExit(int(failed))

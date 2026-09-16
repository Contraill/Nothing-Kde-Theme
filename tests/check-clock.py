#!/usr/bin/env python3
"""Native clock resize/config-reload regression; all state stays in a temp home."""
import argparse
from concurrent.futures import ThreadPoolExecutor
import json
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
    style, date, mode, renderer, output, package = job
    name = f'font-{style}-date-{date}-mode-{mode}'
    with tempfile.TemporaryDirectory(prefix='nothing-clock-check-') as directory:
        home = Path(directory)
        copied = home / 'applet'
        prepare(package, copied)
        qml = copied / 'contents/ui/main.qml'
        # Freeze only the fixture's clock, so geometry comparisons survive midnight.
        qml.write_text(qml.read_text().replace('new Date()', 'new Date(2026, 8, 15, 12, 34)'))
        env = dict(os.environ, XDG_CONFIG_HOME=str(home / 'config'),
                   XDG_DATA_HOME=str(home / 'data'), XDG_CACHE_HOME=str(home / 'cache'),
                   QT_FORCE_STDERR_LOGGING='1', QT_QPA_PLATFORM='offscreen', QT_QUICK_BACKEND='software', QT_QPA_PLATFORMTHEME='generic')
        for key in ('NOTHING_CLOCK_STYLE', 'NOTHING_CLOCK_DATE', 'NOTHING_CLOCK_MODE'):
            env.pop(key, None)
        first = None
        for phase in ('save', 'reload'):
            # The second process loads the saved KConfig with no preference injection.
            launch = dict(env, NOTHING_CLOCK_STYLE=str(style), NOTHING_CLOCK_DATE=str(date),
                          NOTHING_CLOCK_MODE=str(mode)) if phase == 'save' else env
            capture = output / f'{name}-{phase}.png'
            result = subprocess.run([str(renderer), str(copied), str(capture), '--clock-probe'],
                                    env=launch, capture_output=True, text=True, timeout=15)
            log = result.stdout + result.stderr
            (output / f'{name}-{phase}.log').write_text(log)
            assert result.returncode == 0, log
            assert not re.search(r'Binding loop|Polish loop|recursive rearrange|ReferenceError|TypeError|Cannot assign|Error loading', log, re.I), log
            samples = json.loads(Path(str(capture) + '.json').read_text())
            assert len(samples) == 5
            visible = []
            for sample in samples:
                labels = sample['labels']
                assert len(labels) == 2, labels
                assert labels[0]['visible'] == bool(date), labels
                available_height = sample['height'] - 40 - (10 if date else 0)
                available_width = sample['width'] - 80
                expected = min(available_height * (0.6 if style in (0, 1, 3) else 0.7),
                               available_width / (3.5 if style in (0, 1) else 4 if style == 3 else 2.5))
                assert abs(labels[1]['pixelSize'] - expected) <= 0.5, labels
                assert labels[1]['x'] == 20 and labels[1]['width'] == sample['width'] - 40, labels
                rgb = [int(labels[1]['color'][i:i + 2], 16) / 255 for i in (1, 3, 5)]
                luminance = sum(c * w for c, w in zip(rgb, (0.2126, 0.7152, 0.0722)))
                assert (luminance > 0.5) == (mode == 0), labels
                if date:
                    assert labels[0]['height'] == 10
                    assert abs(labels[0]['pixelSize'] - min(available_height, available_width) * 0.1) <= 0.5
                    assert abs(labels[0]['x'] + labels[0]['width'] / 2 - sample['width'] / 2) <= 0.5
                visible.append([label for label in labels if label['visible']])
            assert visible[0] == visible[-1], 'Resize round-trip changed geometry'
            if first is not None:
                assert visible == first, 'Saved config did not survive a fresh applet process'
            first = visible
    return name


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--renderer', type=Path, required=True)
    parser.add_argument('--output', type=Path, required=True)
    parser.add_argument('--package', type=Path, default=ROOT / 'widgets/packages/clock-digital-large')
    args = parser.parse_args()
    args.output.mkdir(parents=True, exist_ok=True)
    jobs = [(style, date, mode, args.renderer.resolve(), args.output, args.package)
            for style in range(5) for date in (0, 1) for mode in (0, 1)]
    with ThreadPoolExecutor(max_workers=4) as pool:
        for name in pool.map(check, jobs):
            print('PASS', name, flush=True)

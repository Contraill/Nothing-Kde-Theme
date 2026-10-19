#!/usr/bin/env python3
"""Stage self-contained applets from shared sources; never edit source packages."""
import argparse
import os
from pathlib import Path
import shutil

ROOT = Path(__file__).resolve().parent


def prepare(package, output):
    package, output = Path(package), Path(output)
    shutil.copytree(package, output)  # Refuse to overwrite an existing destination.
    shared = output / 'contents/ui/glassy'
    shutil.copytree(ROOT / 'shared', shared)
    for source in package.rglob('*.qml'):
        old = os.path.relpath(ROOT / 'shared', source.parent)
        target = output / source.relative_to(package)
        new = os.path.relpath(shared, target.parent)
        text = target.read_text()
        # The shared directory itself and files in it (import "../shared/every.js").
        updated = text.replace(f'import "{old}"', f'import "{new}"').replace(f'import "{old}/', f'import "{new}/')
        if updated != text:
            target.write_text(updated)
    return output


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    for package in sorted((ROOT / 'packages').iterdir()):
        prepare(package, args.output / package.name)

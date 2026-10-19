#!/usr/bin/env python3
"""Set the release version: VERSION, and every package's metadata.json that carries it.

  packaging/set-version.py 0.6.0        # or 0.7.0-rc1

The scripts and tests read VERSION; KPackage reads metadata.json, so those are
rewritten. Glassy's window decoration keeps its own version.
"""
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
# SemVer, with -rcN for release candidates.
PATTERN = r'\d+\.\d+\.\d+(-rc\d+)?'


def metadata_files():
    listed = subprocess.run(['git', 'ls-files', '*metadata.json'], cwd=ROOT, capture_output=True, text=True, check=True).stdout.split()
    return [ROOT / path for path in listed if 'upstream-cache' not in path]


def main():
    if len(sys.argv) != 2 or not re.fullmatch(PATTERN, sys.argv[1]):
        sys.exit(__doc__)
    old, new = (ROOT / 'VERSION').read_text().strip(), sys.argv[1]
    changed = 0
    for path in metadata_files():
        text = path.read_text()
        updated = text.replace(f'"Version": "{old}"', f'"Version": "{new}"')
        if updated != text:
            path.write_text(updated); changed += 1
    (ROOT / 'VERSION').write_text(new + '\n')
    print(f'{old} -> {new}: VERSION and {changed} metadata.json files')


if __name__ == '__main__':
    main()

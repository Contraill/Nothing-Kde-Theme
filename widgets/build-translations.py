#!/usr/bin/env python3
"""Compile native KDE gettext catalogs; English remains the source language."""
import json
from pathlib import Path
import re
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parent


def messages(package):
    return {json.loads(match) for qml in package.rglob('*.qml') for match in
            re.findall(r'\bi18n\(\s*("(?:\\.|[^"\\])*")', qml.read_text())}


def main():
    translations = json.loads((ROOT / 'translations/tr.json').read_text())
    missing = set()
    for package in sorted((ROOT / 'packages').iterdir()):
        strings = messages(package)
        missing.update(strings - translations.keys())
        domain = 'plasma_applet_org.nothingkde.widget.' + package.name
        header = 'Project-Id-Version: Nothing KDE\nLanguage: tr\nContent-Type: text/plain; charset=UTF-8\nPlural-Forms: nplurals=2; plural=(n > 1);\n'
        text = '# Turkish translations for Nothing KDE. GPL-3.0.\nmsgid ""\nmsgstr ' + json.dumps(header) + '\n\n'
        for source in sorted(strings):
            text += 'msgid ' + json.dumps(source, ensure_ascii=False) + '\nmsgstr ' + json.dumps(translations.get(source, source), ensure_ascii=False) + '\n\n'
        target = package / 'contents/locale/tr/LC_MESSAGES' / (domain + '.mo')
        target.parent.mkdir(parents=True, exist_ok=True)
        with tempfile.TemporaryDirectory(prefix='nothing-kde-i18n-') as temp:
            po = Path(temp) / (package.name + '.po')
            po.write_text(text)
            subprocess.run(['msgfmt', '--check-format', '-o', str(target), str(po)], check=True)
    if missing:
        print(json.dumps(sorted(missing), ensure_ascii=False, indent=2))
        raise SystemExit('Missing Turkish translations')
    print('Eight Turkish KDE catalogs compiled; English source fallback retained.')


if __name__ == '__main__': main()

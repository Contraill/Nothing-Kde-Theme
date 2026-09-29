import json
import os
import gettext
from pathlib import Path
import re
import unittest
import xml.etree.ElementTree as ET
import zipfile

ROOT = Path(__file__).resolve().parents[1]
PACKAGES = ROOT / 'widgets/packages'


class WidgetTests(unittest.TestCase):
    def test_eight_desktop_only_packages(self):
        self.assertEqual(len(list(PACKAGES.iterdir())), 8)
        for package in PACKAGES.iterdir():
            metadata = json.loads((package / 'metadata.json').read_text())
            self.assertEqual(metadata['X-Plasma-FormFactors'], ['planar'])
            self.assertEqual(metadata['KPlugin']['Id'], 'org.nothingkde.widget.' + package.name)
            self.assertTrue(metadata['KPlugin']['Name'].startswith('Nothing KDE'))
            self.assertNotIn('X-Plasma-ContainmentType', metadata)
            self.assertTrue((package / 'LICENSE').exists())
            for qml in package.rglob('*.qml'):
                text = qml.read_text()
                for removed in ('compactRepresentation:', 'Plasmoid.formFactor', 'plasmoid.configuration', 'evaluateScript', 'systemctl'):
                    self.assertNotIn(removed, text, str(qml))

    def test_default_mode_and_accent_follow_kde(self):
        for package in PACKAGES.iterdir():
            entries = {e.attrib['name']: e.findtext('{*}default') for e in ET.parse(package / 'contents/config/main.xml').iter() if e.tag.endswith('}entry') or e.tag == 'entry'}
            self.assertEqual(entries['themeMode'], '2')
            self.assertEqual(entries['useSystemAccent'], 'true')

    def test_all_local_asset_references_resolve(self):
        for qml in PACKAGES.rglob('*.qml'):
            for path in re.findall(r'Qt.resolvedUrl\("([^"]+)"\)', qml.read_text()):
                if not ':' in path:
                    self.assertTrue((qml.parent / path).is_file(), str(qml) + ':' + path)
        self.assertFalse(any(p.is_symlink() for p in PACKAGES.rglob('*')))

    def test_store_rights_are_explicitly_pending(self):
        self.assertIn('blocked', json.loads((ROOT / 'widgets/UPSTREAM.json').read_text())['storePublication'])

    def test_turkish_catalogs_cover_all_translatable_strings(self):
        for package in PACKAGES.iterdir():
            catalog = package / 'contents/locale/tr/LC_MESSAGES' / ('plasma_applet_org.nothingkde.widget.' + package.name + '.mo')
            with catalog.open('rb') as file: translator = gettext.GNUTranslations(file)
            strings = {json.loads(match) for qml in package.rglob('*.qml') for match in
                       re.findall(r'\bi18n\(\s*("(?:\\.|[^"\\])*")', qml.read_text())}
            for message in strings:
                self.assertIn(message, translator._catalog)

    def test_widget_archives_are_complete(self):
        for package in PACKAGES.iterdir():
            path = Path(os.environ.get('NOTHING_PACKAGE_DIR', ROOT / 'dist')) / ('Nothing-KDE-Widget-' + package.name + '-0.6.0-rc33.plasmoid')
            if not path.exists(): self.skipTest('Build packages first')
            with zipfile.ZipFile(path) as archive:
                for name in ('metadata.json', 'LICENSE', 'UPSTREAM-NOTICE.md', 'contents/ui/main.qml',
                             'contents/ui/components/NothingColors.qml', 'contents/ui/glassy/GlassySurface.qml',
                             'contents/ui/glassy/WidgetColors.qml'):
                    self.assertIn(name, archive.namelist())


if __name__ == '__main__': unittest.main()

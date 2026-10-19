"""Verify generated artifacts and real KDE package installation in a temp root."""
import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest
import zipfile
import tarfile

ROOT = Path(__file__).resolve().parents[1]
DIST = Path(os.environ.get('NOTHING_PACKAGE_DIR', ROOT / 'dist'))
VERSION = (ROOT / 'VERSION').read_text().strip()


@unittest.skipUnless((DIST / f'Nothing-KDE-{VERSION}.zip').exists(), 'Run ./package.sh to test distribution artifacts')
class PackageTests(unittest.TestCase):
    def test_no_login_manager_is_shipped(self):
        self.assertFalse((ROOT / 'login-manager').exists())
        self.assertFalse(any('Login' in p.name for p in DIST.iterdir()))

    def test_panel_carries_its_runtime_files(self):
        with zipfile.ZipFile(DIST / f'Nothing-KDE-Island-Dock-{VERSION}.plasmoid') as package:
            for name in ('contents/tools/nothing-control.sh', 'contents/tools/privacy.py',
                         'contents/tools/accent-links.py', 'contents/tools/jsonc_edit.py',
                         'contents/island/ui/ControlHub.qml', 'contents/island/ui/PowerPrivacyCard.qml',
                         'contents/ui/components/NativeWindowThumbnail.qml', 'contents/island/ui/AccentSettings.qml',
                         'contents/island/ui/ColorPicker.qml',
                         'contents/wallpapers/dark.jpeg', 'contents/wallpapers/light.jpeg',
                         'contents/ui/components/RuntimePaths.js', 'LICENSES/GPL-3.0.txt',
                         'contents/island/ui/ExpandedPanel.qml', 'contents/island/LICENSE',
                         'contents/island/NOTICE.md', 'contents/island/fonts/OFL-1.1.txt'):
                self.assertIn(name, package.namelist())
            self.assertNotIn('contents/ui/LeftRail.qml', package.namelist())
            self.assertNotIn('contents/ui/RightRail.qml', package.namelist())
            for old in ('contents/ui/CompactIsland.qml', 'contents/island/ui/AppLauncher.qml',
                        'contents/ui/components/TopControlPage.qml', 'contents/ui/components/PersonalizationPage.qml'):
                self.assertNotIn(old, package.namelist())
            self.assertFalse(any('Recorder' in n or 'coffee.py' in n for n in package.namelist()))

    def test_notification_archive_is_complete(self):
        with zipfile.ZipFile(DIST / f'Nothing-KDE-Notifications-Plasma-6.7.4-{VERSION}.plasmoid') as package:
            self.assertEqual(json.loads(package.read('UPSTREAM.json'))['version'], '6.7.4')
            self.assertIn('contents/ui/NothingNotificationPopup.qml', package.namelist())
            self.assertIn('contents/ui/delegates/NothingGlyphEdgeLights.qml', package.namelist())
            self.assertIn(b'Notifications.Globals.positionPopups()', package.read('contents/ui/main.qml'))
            self.assertIn(b'SPDX-FileCopyrightText', package.read('contents/ui/main.qml'))

    def test_glassy_decoration_is_complete(self):
        with zipfile.ZipFile(DIST / f'Glassy-Decoration-{VERSION}.kwindecoration') as package:
            self.assertEqual(json.loads(package.read('metadata.json'))['KPlugin']['Name'],'Glassy')
            for name in ('contents/ui/config.ui','contents/config/main.xml','contents/code/main.qml','contents/ui/GlassyDecoration.qml',
                         'contents/ui/ConfigDefaults.js','contents/assets/masks.svg'):
                self.assertIn(name,package.namelist())
            self.assertNotIn('contents/assets/mask-square.svg',package.namelist())

    def test_source_archive_builds_offline(self):
        with zipfile.ZipFile(DIST / f'Nothing-KDE-{VERSION}.zip') as package:
            for name in ('Globals.qml', 'NotificationPopup.qml'):
                self.assertIn('nothing-kde/notification-skin/upstream-cache/6.7.4/' + name, package.namelist())
            self.assertFalse(any('/dist/' in name or '/build/' in name for name in package.namelist()))
            self.assertFalse(any('/__pycache__/' in name or name.endswith(('.pyc', '.po')) for name in package.namelist()))
            self.assertNotIn('nothing-kde/notification-skin/apply.py', package.namelist())
            self.assertNotIn('nothing-kde/theme-state/nothing-plasma.state.json', package.namelist())
            for name in ('dolphin/manage.py', 'dolphin/profile.json', 'dolphin/style.qss', 'runtime/jsonc_edit.py',
                         'widgets/packages/date/contents/ui/components/DatePages.qml'):
                self.assertIn('nothing-kde/' + name, package.namelist())

    def test_checksums_match(self):
        for line in (DIST / 'SHA256SUMS').read_text().splitlines():
            digest, name = line.split('  ', 1)
            self.assertEqual(hashlib.sha256((DIST / name).read_bytes()).hexdigest(), digest, name)

    @unittest.skipUnless(shutil.which('kpackagetool6'), 'KDE package tools unavailable')
    def test_kde_accepts_archives(self):
        with tempfile.TemporaryDirectory(prefix='nothing-kpackage-') as td:
            env = dict(os.environ, XDG_DATA_HOME=td + '/data', XDG_CACHE_HOME=td + '/cache',
                       XDG_CONFIG_HOME=td + '/config')
            artifacts = [
                ('Plasma/Applet', f'Nothing-KDE-Island-Dock-{VERSION}.plasmoid'),
                ('Plasma/Applet', f'Nothing-KDE-Launcher-Bridge-{VERSION}.plasmoid'),
                ('Plasma/Applet', f'Nothing-KDE-Notifications-Plasma-6.7.4-{VERSION}.plasmoid'),
                ('Plasma/LayoutTemplate', f'Nothing-KDE-Island-Dock-Layout-{VERSION}.plasmalayout'),
                ('Plasma/Theme', f'Nothing-KDE-Style-Dark-{VERSION}.tar.gz'),
                ('Plasma/Theme', f'Nothing-KDE-Style-Light-{VERSION}.tar.gz'),
                ('Plasma/LookAndFeel', f'Nothing-KDE-Dark-{VERSION}.lookandfeel'),
                ('Plasma/LookAndFeel', f'Nothing-KDE-Light-{VERSION}.lookandfeel'),
                ('KWin/Decoration', f'Glassy-Decoration-{VERSION}.kwindecoration'),
            ]
            artifacts += [('Plasma/Applet', path.name) for path in sorted(DIST.glob(f'Nothing-KDE-Widget-*-{VERSION}.plasmoid'))]
            for kind, name in artifacts:
                result = subprocess.run(['kpackagetool6', '--type', kind, '--install', str(DIST / name)],
                                        env=env, capture_output=True, text=True, timeout=20)
                self.assertEqual(result.returncode, 0, name + '\n' + result.stdout + result.stderr)

    @unittest.skipUnless(shutil.which('kpackagetool6'), 'KDE package tools unavailable')
    def test_changed_applets_upgrade_and_remove_in_isolation(self):
        with tempfile.TemporaryDirectory(prefix='nothing-kpackage-lifecycle-') as td:
            env = dict(os.environ, XDG_DATA_HOME=td + '/data', XDG_CACHE_HOME=td + '/cache',
                       XDG_CONFIG_HOME=td + '/config')
            archives = [DIST / f'Nothing-KDE-Island-Dock-{VERSION}.plasmoid']
            changed = {'org.nothingkde.widget.' + name for name in ('photo', 'weather', 'clock-digital-large')}
            for path in DIST.glob(f'Nothing-KDE-Widget-*-{VERSION}.plasmoid'):
                with zipfile.ZipFile(path) as package:
                    if json.loads(package.read('metadata.json'))['KPlugin']['Id'] in changed:
                        archives.append(path)
            self.assertEqual(len(archives), 4)
            for archive in archives:
                with zipfile.ZipFile(archive) as package:
                    plugin = json.loads(package.read('metadata.json'))['KPlugin']['Id']
                    if plugin.endswith('.photo'):
                        self.assertIn('contents/default/nothing.png', package.namelist())
                        self.assertNotIn('contents/default/sample.jpeg', package.namelist())
                for action, target in (('--install', str(archive)), ('--upgrade', str(archive)), ('--remove', plugin)):
                    result = subprocess.run(['kpackagetool6', '--type', 'Plasma/Applet', action, target],
                                            env=env, capture_output=True, text=True, timeout=20)
                    self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
                self.assertFalse((Path(td) / 'data/plasma/plasmoids' / plugin).exists())


if __name__ == '__main__':
    unittest.main()

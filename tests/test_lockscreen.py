import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]


@unittest.skipUnless(shutil.which('kwriteconfig6') and shutil.which('kreadconfig6'), 'KDE config tools required')
class LockWallpaperTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.base = Path(self.temp.name)
        self.config = self.base / 'config'
        self.config.mkdir()
        self.data = self.base / 'data'
        walls = self.data / 'nothing-plasma/wallpapers'
        walls.mkdir(parents=True)
        for mode in ('light', 'dark'):
            (walls / (mode + '.jpeg')).write_bytes(b'fixture')
        self.bin = self.base / 'bin'
        self.bin.mkdir()
        qdbus = self.bin / 'qdbus6'
        qdbus.write_text('#!/bin/sh\nprintf "%s\\n" "$*" >> "$NOTHING_TEST_DBUS_LOG"\n')
        qdbus.chmod(0o755)
        self.log = self.base / 'dbus'
        self.env = {**os.environ, 'XDG_CONFIG_HOME': str(self.config), 'XDG_DATA_HOME': str(self.data),
                    'PATH': str(self.bin) + os.pathsep + os.environ['PATH'], 'NOTHING_TEST_DBUS_LOG': str(self.log)}

    def apply(self, mode):
        return subprocess.run(['bash', str(ROOT / 'runtime/nothing-control.sh'), 'lockscreen-wallpaper', mode],
                              env=self.env, capture_output=True, text=True)

    def read_key(self, groups, key):
        args = ['kreadconfig6', '--file', str(self.config / 'kscreenlockerrc')]
        for group in groups:
            args += ['--group', group]
        return subprocess.check_output(args + ['--key', key], env=self.env, text=True).strip()

    def test_theme_pair_and_security_preservation(self):
        original = '[Daemon]\nAutolock=true\nRequirePassword=true\nTimeout=17\n\n[Greeter]\nTheme=custom\n'
        (self.config / 'kscreenlockerrc').write_text(original)
        for mode in ('light', 'dark'):
            result = self.apply(mode)
            self.assertEqual(result.returncode, 0, result.stderr)
            groups = ['Greeter', 'Wallpaper', 'org.kde.image', 'General']
            expected = (self.data / 'nothing-plasma/wallpapers' / (mode + '.jpeg')).as_uri()
            self.assertEqual(self.read_key(groups, 'Image'), expected)
            self.assertEqual(self.read_key(groups, 'PreviewImage'), expected)
            self.assertEqual(self.read_key(['Daemon'], 'Timeout'), '17')
            self.assertEqual(self.read_key(['Daemon'], 'Autolock'), 'true')
            self.assertEqual(self.read_key(['Daemon'], 'RequirePassword'), 'true')
            self.assertEqual(self.read_key(['Greeter'], 'Theme'), 'custom')
        backup = self.data / 'nothing-plasma/backups/lockscreen-before-theme/kscreenlockerrc'
        self.assertEqual(backup.read_text(), original)
        self.assertEqual(self.log.read_text().splitlines(), ['org.kde.screensaver /ScreenSaver org.kde.screensaver.configure'] * 2)

    def test_repeated_mode_does_not_rewrite_or_reconfigure(self):
        self.assertEqual(self.apply('dark').returncode, 0)
        config = self.config / 'kscreenlockerrc'
        changed = config.stat().st_mtime_ns
        self.assertEqual(self.apply('dark').returncode, 0)
        self.assertEqual(config.stat().st_mtime_ns, changed)
        self.assertEqual(len(self.log.read_text().splitlines()), 1)
        self.assertTrue((self.data / 'nothing-plasma/backups/lockscreen-before-theme/previously-absent').is_file())

    def test_invalid_mode_changes_nothing(self):
        self.assertNotEqual(self.apply('../other').returncode, 0)
        self.assertFalse((self.config / 'kscreenlockerrc').exists())
        self.assertFalse(self.log.exists())

    def test_theme_hook_respects_wallpaper_preference(self):
        helper = (ROOT / 'runtime/nothing-control.sh').read_text()
        self.assertIn('if [[ "$auto_wallpaper" == "1" ]]; then\n    apply_wallpaper "$mode" || true\n    apply_lock_wallpaper "$mode"', helper)
        controls = (ROOT / 'plasmoids/com.nothingplasma.panel/contents/ui/components/SystemControls.qml').read_text()
        self.assertIn('if (!root.autoWallpaper) return', controls)
        meter = (ROOT / 'plasmoids/com.nothingplasma.panel/contents/island/ui/Meters.qml').read_text()
        temperatures = meter.split('id: tempRow', 1)[1].split('\n    Meter {', 1)[0]
        self.assertEqual(temperatures.count('color: Theme.primary'), 2)
        self.assertNotIn('Theme.alert', temperatures)

import importlib.util
import os
from pathlib import Path
import re
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location('bootsplash', ROOT / 'runtime/bootsplash.py')
boot = importlib.util.module_from_spec(spec)
spec.loader.exec_module(boot)


class BootSplashTests(unittest.TestCase):
    def test_preview_draws_a_complete_two_step_theme(self):
        with tempfile.TemporaryDirectory() as td:
            directory = Path(td)
            boot.draw(directory, '109dd9')
            self.assertEqual(len(list(directory.glob('throbber-*.png'))), boot.THROBBER_FRAMES)
            self.assertEqual(len(list(directory.glob('animation-*.png'))), boot.END_FRAMES)
            for name in ('entry.png', 'bullet.png', 'lock.png'):
                self.assertTrue((directory / name).is_file(), name)
            theme = (directory / 'nothing-kde.plymouth').read_text()
            self.assertIn('ModuleName=two-step', theme)
            self.assertIn('ImageDir=' + str(directory), theme)
            self.assertIn('[boot-up]\nUseEndAnimation=true', theme)
            self.assertEqual((directory / 'accent').read_text(), '109DD9\n')

    def test_polkit_rule_only_allows_an_accent(self):
        pattern = re.search(r'/\^(.*)\$/\.test', boot.POLKIT).group(1).replace('\\/', '/')
        allowed = re.compile('^' + pattern + '$')
        self.assertTrue(allowed.match(f'{boot.HELPER} accent 109DD9'))
        for refused in (f'{boot.HELPER} accent 109dd9', f'{boot.HELPER} accent 109DD9 x', f'{boot.HELPER} remove',
                        f'{boot.HELPER} setup 109DD9', f'/tmp/nothing-kde-boot accent 109DD9'):
            self.assertIsNone(allowed.match(refused), refused)
        self.assertIn('subject.local && subject.active', boot.POLKIT)

    def test_root_actions_refuse_without_root_and_bad_colours(self):
        if os.geteuid() == 0:
            self.skipTest('running as root')
        for args in (['setup', '109DD9'], ['accent', '109DD9'], ['remove']):
            result = subprocess.run(['python3', '-I', str(ROOT / 'runtime/bootsplash.py'), *args], capture_output=True, text=True)
            self.assertNotEqual(result.returncode, 0, args)
        with self.assertRaises(SystemExit):
            boot.rgb('12345G')

    def test_one_splash_for_both_themes_and_accent_hook(self):
        dark = ROOT / 'plasma/look-and-feel/com.nothingplasma.dark/contents'
        light = ROOT / 'plasma/look-and-feel/com.nothingplasma.light/contents'
        self.assertTrue((dark / 'splash/Splash.qml').is_file())
        self.assertTrue((dark / 'previews/splash.png').is_file())
        self.assertFalse((light / 'splash').exists())
        self.assertIn('[ksplashrc][KSplash]\nEngine=KSplashQML\nTheme=com.nothingplasma.dark', (light / 'defaults').read_text())
        self.assertIn('Kirigami.Theme.focusColor', (dark / 'splash/Splash.qml').read_text())
        control = (ROOT / 'runtime/nothing-control.sh').read_text()
        self.assertIn('sync_boot_accent "$hex"', control)


if __name__ == '__main__':
    unittest.main()

import math
import os
from pathlib import Path
import shutil
import struct
import subprocess
import tempfile
import unittest
import wave

ROOT = Path(__file__).resolve().parents[1]
HELPER = ROOT / 'runtime/sounds.py'
THEME = ROOT / 'assets/sounds/nothing-kde'


class SoundThemeTests(unittest.TestCase):
    def test_bundled_theme_is_complete(self):
        index = (THEME / 'index.theme').read_text()
        self.assertIn('Inherits=freedesktop', index)
        sounds = {p.stem for p in THEME.glob('stereo/*.oga')}
        # The events Plasma's own notifications ask for.
        for event in ('message-new-instant', 'dialog-information', 'dialog-warning', 'dialog-error', 'bell-window-system',
                      'device-added', 'device-removed', 'power-plug', 'power-unplug', 'battery-low', 'battery-caution',
                      'desktop-login', 'desktop-logout', 'trash-empty', 'alarm-clock-elapsed', 'audio-volume-change'):
            self.assertIn(event, sounds)
        for theme in ('dark', 'light'):
            defaults = (ROOT / f'plasma/look-and-feel/com.nothingplasma.{theme}/contents/defaults').read_text()
            self.assertIn('[kdeglobals][Sounds]\nTheme=nothing-kde', defaults)

    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix='nothing-sounds-')
        self.addCleanup(self.temp.cleanup)
        home = Path(self.temp.name)
        self.data, self.bin, self.store = home / 'data', home / 'bin', home / 'theme'
        self.bin.mkdir()
        # kreadconfig6/kwriteconfig6 stand-ins that keep the one value in a file.
        (self.bin / 'kreadconfig6').write_text(f'#!/bin/sh\ncat "{self.store}" 2>/dev/null\n')
        (self.bin / 'kwriteconfig6').write_text(
            f'#!/bin/sh\nfor a; do last=$a; done\ncase " $* " in *" --delete "*) rm -f "{self.store}";; *) printf %s "$last" > "{self.store}";; esac\n')
        for tool in ('kreadconfig6', 'kwriteconfig6'):
            (self.bin / tool).chmod(0o755)
        self.env = dict(os.environ, XDG_DATA_HOME=str(self.data), PATH=f'{self.bin}:{os.environ["PATH"]}')

    def run_helper(self, *args):
        return subprocess.run(['python3', '-I', str(HELPER), *args], env=self.env, capture_output=True, text=True, check=True)

    def selection(self):
        return self.store.read_text() if self.store.exists() else ''

    def test_install_selects_only_an_unchosen_theme(self):
        self.run_helper('install')
        self.assertTrue((self.data / 'sounds/nothing-kde/stereo/bell.oga').is_file())
        self.assertEqual(self.selection(), 'nothing-kde')
        self.store.write_text('ocean')
        self.run_helper('install')
        self.assertEqual(self.selection(), 'ocean')
        self.run_helper('remove')
        self.assertEqual(self.selection(), 'ocean')
        self.assertFalse((self.data / 'sounds/nothing-kde').exists())

    @unittest.skipUnless(shutil.which('ffmpeg'), 'ffmpeg is not installed')
    def test_import_maps_names_and_aliases(self):
        recordings = Path(self.temp.name) / 'recordings'
        recordings.mkdir()
        for name in ('notification', 'message-new-instant', 'unrelated'):
            with wave.open(str(recordings / (name + '.wav')), 'wb') as file:
                file.setnchannels(1); file.setsampwidth(2); file.setframerate(48000)
                file.writeframes(b''.join(struct.pack('<h', int(8000 * math.sin(i / 10))) for i in range(4800)))
        result = self.run_helper('import', str(recordings))
        theme = self.data / 'sounds/nothing-kde-personal'
        self.assertIn('Inherits=nothing-kde,freedesktop', (theme / 'index.theme').read_text())
        self.assertTrue((theme / 'stereo/dialog-information.oga').is_file())
        # The recording named after the event beats the alias.
        self.assertIn('message-new-instant.wav -> message-new-instant', result.stdout)
        self.assertNotIn('notification.wav -> message-new-instant', result.stdout)
        self.assertIn('unrelated.wav', result.stderr)
        self.assertEqual(self.selection(), 'nothing-kde-personal')
        self.run_helper('remove')
        self.assertEqual(self.selection(), '')


if __name__ == '__main__':
    unittest.main()

import importlib.util
import json
import os
import shutil
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'runtime'))
import appearance
spec = importlib.util.spec_from_file_location('kitty_theme', ROOT / 'runtime/kitty-theme.py')
kitty = importlib.util.module_from_spec(spec)
spec.loader.exec_module(kitty)


class RuntimePaletteTests(unittest.TestCase):
    @unittest.skipUnless(shutil.which('kwriteconfig6') and shutil.which('kreadconfig6'), 'Native KDE config tools required')
    def test_native_accent_persistence_startup_and_failed_apply_rollback(self):
        source = (ROOT/'runtime/nothing-control.sh').read_text()
        functions = source[source.index('apply_accent() {'):source.index('launcher_meta_action=')]
        stubs = '\npatch_nothing_color_schemes() { :; }; sync_panel_accent() { :; }; sync_accent_links() { :; }; sync_accent_from_kde() { :; };\n'
        with tempfile.TemporaryDirectory() as td:
            directory = Path(td)
            backend = directory/'plasma-apply-colorscheme'
            backend.write_text('#!/bin/sh\nexit "${FAIL_APPLY:-0}"\n'); backend.chmod(0o755)
            env = dict(os.environ, XDG_CONFIG_HOME=td, CONFIG_HOME=td, DATA_HOME=td,
                       PATH=td+os.pathsep+os.environ['PATH'])
            command = ['bash', '-c', 'set -euo pipefail\n'+functions+stubs+'apply_accent 806ee7']
            subprocess.run(command, env=env, check=True, capture_output=True)
            def saved():
                return subprocess.check_output(['kreadconfig6','--file','kdeglobals','--group','General','--key','AccentColor'],env=env,text=True).strip()
            self.assertEqual(saved(), '128,110,231')
            # Fresh startup process, with a conflicting stale legacy panel copy.
            (directory/'plasma-org.kde.plasma.desktop-appletsrc').write_text(
                '[Containments][1]\nplugin=com.nothingplasma.panel\n[Containments][1][General]\naccentColor=#DDAABB\n')
            subprocess.run(['bash','-c',functions+stubs+'init_accent'],env=env,check=True,capture_output=True)
            self.assertEqual(saved(), '128,110,231')
            result = subprocess.run(command[:-1]+[command[-1].replace('apply_accent 806ee7','apply_accent 112233')],
                                    env=dict(env,FAIL_APPLY='1'),capture_output=True)
            self.assertNotEqual(result.returncode, 0)
            self.assertEqual(saved(), '128,110,231')

    def test_kitty_interrupted_update_can_resume(self):
        with tempfile.TemporaryDirectory() as td:
            directory = Path(td)
            colors = dict(background='#090909', foreground='#eeeeee', selection_background='#806ee7', selection_foreground='#ffffff')
            real_atomic = kitty.atomic
            def interrupted(path, content):
                if path.name == kitty.FILES[1]: raise OSError('simulated interruption')
                return real_atomic(path, content)
            with patch.object(kitty, 'KITTY', directory), patch.object(kitty, 'STATE', directory/'state.json'), \
                 patch.object(kitty, 'user_colors', return_value=[]), patch.object(kitty, 'scheme', return_value=colors), \
                 patch.object(kitty, 'reload_running'):
                with patch.object(kitty, 'atomic', side_effect=interrupted):
                    with self.assertRaises(OSError): kitty.update({})
                state = json.loads((directory/'state.json').read_text())
                kitty.update(state)
                self.assertTrue(all((directory/name).is_file() for name in kitty.FILES))
                kitty.disable(state)
                self.assertFalse(any((directory/name).exists() for name in kitty.FILES))

    def test_notification_only_changed_scheme_with_loaded_style_and_deduplicated(self):
        state = {}
        with patch.object(appearance, 'read', return_value='Glassy'), \
             patch.object(appearance, 'notification_session', return_value='bus/server'), \
             patch.object(appearance, 'running_kvantum_apps', return_value=True), \
             patch.object(appearance.shutil, 'which', return_value='/usr/bin/notify-send'), \
             patch.object(appearance, 'run', return_value=subprocess.CompletedProcess([], 0, '42\n')) as run:
            light, dark = 'NothingPlasmaLight', 'NothingPlasmaDark'
            appearance.notify_cached_apps(state, light, light)
            run.assert_not_called()
            appearance.notify_cached_apps(state, light, dark)
            appearance.notify_cached_apps(state, light, dark)
            self.assertEqual(run.call_count, 1)
            appearance.notify_cached_apps(state, dark, light)
            self.assertEqual(run.call_count, 2)
            self.assertIn('--replace-id=42', run.call_args.args)
            self.assertIn('Theme updated', run.call_args.args)

    def test_no_notification_without_running_kvantum(self):
        with patch.object(appearance, 'read', return_value='Glassy'), \
             patch.object(appearance, 'notification_session', return_value='bus/server'), \
             patch.object(appearance, 'running_kvantum_apps', return_value=False), \
             patch.object(appearance, 'run') as run:
            appearance.notify_cached_apps({}, 'NothingPlasmaDark', 'NothingPlasmaLight')
            run.assert_not_called()

    def test_kitty_idempotence_and_rollback_preserve_main_and_existing_files(self):
        with tempfile.TemporaryDirectory() as td:
            directory = Path(td)
            (directory / 'kitty.conf').write_text('background_opacity 0.5\nfont_size 12.5\n')
            original = directory / kitty.FILES[0]
            original.write_text('background #abcdef\n')
            colors = dict(background='#090909', foreground='#eeeeee', selection_background='#806ee7', selection_foreground='#ffffff')
            with patch.object(kitty, 'KITTY', directory), patch.object(kitty, 'STATE', directory/'state.json'), \
                 patch.object(kitty, 'user_colors', return_value=['color1 #123456']), \
                 patch.object(kitty, 'scheme', return_value=colors), patch.object(kitty, 'reload_running'):
                state = {}
                kitty.update(state)
                timestamp = original.stat().st_mtime_ns
                kitty.update(state)
                self.assertEqual(timestamp, original.stat().st_mtime_ns)
                self.assertIn('color1 #123456', original.read_text())
                self.assertNotIn('background_opacity', original.read_text())
                kitty.disable(state)
                self.assertEqual(original.read_text(), 'background #abcdef\n')
                self.assertFalse((directory / kitty.FILES[1]).exists())
                self.assertEqual((directory/'kitty.conf').read_text(), 'background_opacity 0.5\nfont_size 12.5\n')

    def test_kitty_preserves_later_user_edits(self):
        with tempfile.TemporaryDirectory() as td:
            directory = Path(td)
            colors = dict(background='#090909', foreground='#eeeeee', selection_background='#806ee7', selection_foreground='#ffffff')
            with patch.object(kitty, 'KITTY', directory), patch.object(kitty, 'STATE', directory/'state.json'), \
                 patch.object(kitty, 'user_colors', return_value=[]), patch.object(kitty, 'scheme', return_value=colors), \
                 patch.object(kitty, 'reload_running'):
                state = {}; kitty.update(state)
                path = directory / kitty.FILES[0]; path.write_text('user change')
                with self.assertRaises(ValueError): kitty.update(state)
                kitty.disable(state)
                self.assertEqual(path.read_text(), 'user change')

"""No real device writes, privilege prompts, audio restarts, or recording."""
import importlib.util
import json
from pathlib import Path
import stat
import subprocess
import tempfile
from types import SimpleNamespace
import unittest
from unittest.mock import patch, Mock

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location('privacy', ROOT / 'runtime/privacy.py')
privacy = importlib.util.module_from_spec(spec)
spec.loader.exec_module(privacy)


class CameraTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.base = Path(self.temp.name)
        for name, cls in [('1-2:1.0', '0e'), ('1-2:1.1', '0e'), ('1-2:1.2', '01'), ('1-3:1.0', '03')]:
            p = self.base / name
            p.mkdir()
            (p / 'bInterfaceClass').write_text(cls)
            (p / 'authorized').write_text('1')
        self.patches = [patch.object(privacy, 'USB', self.base), patch.object(privacy, 'PROBE', self.base / 'probe')]
        for p in self.patches:
            p.start()
            self.addCleanup(p.stop)

    def test_only_video_interfaces_are_blocked_and_can_be_restored(self):
        privacy.set_camera(False)
        self.assertEqual((self.base / '1-2:1.0/authorized').read_text(), '0')
        self.assertEqual((self.base / '1-2:1.1/authorized').read_text(), '0')
        self.assertEqual((self.base / '1-2:1.2/authorized').read_text(), '1')
        self.assertEqual((self.base / '1-3:1.0/authorized').read_text(), '1')
        privacy.set_camera(True)
        self.assertTrue(all((p / 'authorized').read_text() == '1' for p in privacy.cameras()))

    def test_probe_failure_restores_previous_authorization(self):
        privacy.set_camera(False)
        with patch.object(privacy, 'PROBE', self.base / 'missing/probe'):
            with self.assertRaises(OSError):
                privacy.set_camera(True)
        self.assertTrue(all((p / 'authorized').read_text() == '0' for p in privacy.cameras()))


class MicrophoneTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.base = Path(self.temp.name)
        self.node = Mock()
        self.node.name = 'pcmC0D0c'
        self.node.stat.return_value = SimpleNamespace(st_rdev=10, st_mode=stat.S_IFCHR)
        self.caller = SimpleNamespace(pw_uid=1000, pw_name='test-user')
        def run(command, **kwargs):
            if '/usr/bin/pactl' in command:
                return subprocess.CompletedProcess(command, 0, '[{"name":"alsa_input.test"}]', '')
            return subprocess.CompletedProcess(command, 0, '# file: /dev/snd/pcmC0D0c\n', '')
        mocks = {
            'STATE': self.base, 'RULE': self.base / 'test.rules',
            'desktop_caller': Mock(return_value=self.caller),
            'prepare_state': Mock(), 'capture_nodes': Mock(return_value=[self.node]),
            'restart_audio': Mock(), 'reload_capture_rules': Mock(),
            'capture_busy': Mock(return_value=False), 'run': Mock(side_effect=run),
        }
        for name, value in mocks.items():
            p = patch.object(privacy, name, value)
            p.start()
            self.addCleanup(p.stop)
        p = patch.object(privacy.os, 'chmod')
        self.chmod = p.start()
        self.addCleanup(p.stop)

    def test_block_denies_capture_not_playback_and_keeps_snapshot(self):
        privacy.set_microphone(True)
        self.assertTrue(privacy.own_rule())
        self.chmod.assert_any_call(self.node, 0)
        self.assertTrue((self.base / 'capture-acls.json').exists())
        self.assertIn('KERNEL=="pcmC*D*c"', privacy.RULE.read_text())
        privacy.restart_audio.assert_called_once_with(self.caller)

    def test_direct_capture_holder_causes_rollback_not_false_success(self):
        privacy.capture_busy.return_value = True
        with patch.object(privacy, 'restore_microphones') as restore:
            with self.assertRaisesRegex(RuntimeError, 'capture-busy'):
                privacy.set_microphone(True)
            restore.assert_called_once()
        self.assertFalse((self.base / 'capture-acls.json').exists())

    def test_unblock_restores_exact_snapshot_and_restarts_audio(self):
        privacy.RULE.write_text(privacy.RULE_TEXT)
        snapshot = [{'name': 'pcmC0D0c', 'device': 10, 'acl': 'original-acl'}]
        (self.base / 'capture-acls.json').write_text(json.dumps(snapshot))
        with patch.object(privacy, 'restore_microphones') as restore:
            privacy.set_microphone(False)
            restore.assert_called_once_with(snapshot)
        privacy.restart_audio.assert_called_once_with(self.caller)

    def test_foreign_rule_is_never_overwritten(self):
        privacy.RULE.write_text('user policy')
        with self.assertRaisesRegex(RuntimeError, 'foreign-rule'):
            privacy.set_microphone(True)
        self.assertEqual(privacy.RULE.read_text(), 'user policy')

    def test_recovery_can_be_retried_after_rule_was_removed(self):
        snapshot = [{'name': 'pcmC0D0c', 'device': 10, 'acl': 'original-acl'}]
        (self.base / 'capture-acls.json').write_text(json.dumps(snapshot))
        with patch.object(privacy, 'restore_microphones') as restore:
            privacy.set_microphone(False)
            restore.assert_called_once_with(snapshot)
        self.assertFalse((self.base / 'capture-acls.json').exists())

    def test_pending_recovery_snapshot_is_never_overwritten(self):
        saved = self.base / 'capture-acls.json'
        saved.write_text('original-snapshot')
        with self.assertRaisesRegex(RuntimeError, 'recovery-required'):
            privacy.set_microphone(True)
        self.assertEqual(saved.read_text(), 'original-snapshot')
        self.chmod.assert_not_called()

    def test_bluetooth_capture_is_rejected_before_any_device_change(self):
        privacy.run.side_effect = None
        privacy.run.return_value = subprocess.CompletedProcess([], 0, '[{"name":"bluez_input.test"}]', '')
        with self.assertRaisesRegex(RuntimeError, 'unsupported-source'):
            privacy.set_microphone(True)
        self.assertFalse(privacy.RULE.exists())
        self.chmod.assert_not_called()

    def test_mutation_without_root_never_touches_hardware(self):
        with patch.object(privacy.sys, 'argv', ['privacy.py', 'camera', 'off']), \
             patch.object(privacy.os, 'geteuid', return_value=1000), \
             patch.object(privacy, 'set_camera') as setter, patch('builtins.print'):
            self.assertEqual(privacy.main(), 1)
        setter.assert_not_called()


if __name__ == '__main__':
    unittest.main()

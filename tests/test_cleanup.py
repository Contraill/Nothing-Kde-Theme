import os
from pathlib import Path
import re
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
CONTENTS = ROOT / 'plasmoids/com.nothingplasma.panel/contents'


class CleanupTests(unittest.TestCase):
    def test_island_has_no_hover_labels_but_keeps_action_errors(self):
        for path in (CONTENTS / 'island/ui').glob('*.qml'):
            self.assertNotIn('ToolTip.', path.read_text(), str(path))
        panel = (CONTENTS / 'island/ui/ExpandedPanel.qml').read_text()
        self.assertIn('text: ControlHub.error', panel)
        self.assertIn('onRequestSettings:', panel)
        self.assertNotIn('AppLauncher', panel)

    def test_all_shipped_qml_is_reachable(self):
        files = list(CONTENTS.rglob('*.qml'))
        by_name = {}
        for path in files:
            by_name.setdefault(path.stem, []).append(path)
        live = {p for p in files if p.name == 'main.qml' or p.parent.name == 'config'
                or p.read_text().startswith('pragma Singleton')}
        while True:
            found = set(live)
            for path in live:
                for token in re.findall(r'\b[A-Z][A-Za-z0-9_]*\b', path.read_text()):
                    found.update(by_name.get(token, []))
            if found == live:
                break
            live = found
        self.assertEqual(set(files) - live, set())

    def test_widget_components_are_reachable(self):
        for package in (ROOT / 'widgets/packages').iterdir():
            files = list(package.rglob('*.qml'))
            by_name = {p.stem: p for p in files}
            live = {p for p in files if p.name == 'main.qml' or p.parent.name == 'config'
                    or p.read_text().startswith('pragma Singleton')}
            while True:
                found = set(live)
                for path in live:
                    for token in re.findall(r'\b[A-Z][A-Za-z0-9_]*\b', path.read_text()):
                        if token in by_name: found.add(by_name[token])
                if found == live: break
                live = found
            self.assertEqual(set(files) - live, set(), package.name)

    def test_retired_files_are_not_in_source(self):
        # CHANGELOG.md is back, kept with each release.
        for name in ('dev-test.sh', 'README-RC18.md', 'theme-state',
                     'third-party', 'notification-skin/apply.py', 'notification-skin/manage.py',
                     'packaging/import-widgets.py'):
            self.assertFalse((ROOT / name).exists(), name)
        self.assertTrue((ROOT / 'notification-skin/restore-legacy.py').exists())

    def test_only_exact_legacy_units_are_stopped(self):
        with tempfile.TemporaryDirectory() as temp:
            directory = Path(temp)
            log = directory / 'calls'
            mock = directory / 'systemctl'
            mock.write_text('#!/bin/sh\nprintf "%s\\n" "$*" >> "$NOTHING_TEST_LOG"\nexit 5\n')
            mock.chmod(0o755)
            env = {**os.environ, 'PATH': temp + os.pathsep + os.environ['PATH'],
                   'NOTHING_TEST_LOG': str(log)}
            result = subprocess.run(['bash', str(ROOT / 'runtime/nothing-control.sh'), 'retire-inhibitors'],
                                    env=env, capture_output=True, text=True)
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertEqual(log.read_text().splitlines(), [
                '--user stop nothing-plasma-prevent-sleep.service',
                '--user stop nothing-plasma-prevent-lock.service',
                '--user stop nothing-plasma-stay-awake.service'])

    def test_custom_inhibitor_cannot_be_started_again(self):
        helper = (ROOT / 'runtime/nothing-control.sh').read_text()
        self.assertNotIn('systemd-inhibit', helper)
        self.assertNotIn('sleep infinity', helper)
        self.assertIn('retire-inhibitors', (ROOT / 'install.sh').read_text())
        controls = (CONTENTS / 'ui/components/SystemControls.qml').read_text()
        self.assertNotIn('setStayAwake', controls)
        self.assertNotIn('refreshInhibitor', controls)
        self.assertIn('controls.retireLegacyInhibitors()', (CONTENTS / 'ui/TopPanel.qml').read_text())


class ShortcutCleanupTests(unittest.TestCase):
    def test_only_dead_widget_shortcuts_are_removed(self):
        helper = (ROOT / 'runtime/nothing-control.sh').read_text()
        body = helper.split('cleanup_widget_shortcuts() {', 1)[1].split('\n}\n', 1)[0]
        # Live applets/containments are skipped; only plasmashell's widget actions qualify.
        self.assertIn('&& continue', body)
        self.assertIn(r'^activate\ widget\ ([0-9]+)$', body)
        self.assertIn('unregister ss plasmashell', body)
        self.assertIn('nothing-control.sh" cleanup-shortcuts', (ROOT / 'install.sh').read_text())

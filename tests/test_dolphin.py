import importlib.util
import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location('dolphin_profile', ROOT / 'dolphin/manage.py')
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)


class DolphinTests(unittest.TestCase):
    def test_roundtrip_and_idempotence(self):
        with tempfile.TemporaryDirectory() as td:
            config = Path(td); path = config / 'dolphinrc'
            original = 'MenuBar=Disabled\n[General]\nHomeUrl=/personal\nShowToolTips=true\n[Unrelated]\nkey=value\n'
            path.write_text(original)
            module.manage('apply', config); applied = path.read_text()
            module.manage('apply', config); self.assertEqual(path.read_text(), applied)
            self.assertIn('HomeUrl=/personal', applied)
            module.manage('restore', config); self.assertEqual(path.read_text(), original)

    def test_restore_preserves_later_edits(self):
        with tempfile.TemporaryDirectory() as td:
            config = Path(td); path = config / 'dolphinrc'
            path.write_text('[General]\nHomeUrl=/personal\n')
            module.manage('apply', config)
            path.write_text(path.read_text().replace('IconSize=64', 'IconSize=80').replace('/personal', '/new'))
            result = module.manage('restore', config)
            self.assertIn('HomeUrl=/new', path.read_text())
            self.assertIn('IconSize=80', path.read_text())
            self.assertIn('[IconsMode]/IconSize', result['preserved_user_changes'])

    def test_immutable_group_and_key_are_preserved(self):
        with tempfile.TemporaryDirectory() as td:
            config = Path(td); path = config / 'dolphinrc'
            path.write_text('[General][$i]\nShowFullPath=false\n[IconsMode]\nIconSize[$i]=16\n')
            module.manage('apply', config)
            self.assertNotIn('[General]\n', path.read_text())
            self.assertNotIn('IconSize=64', path.read_text())

    def test_only_native_appearance_keys(self):
        profile = json.loads((ROOT / 'dolphin/profile.json').read_text())
        self.assertFalse({'HomeUrl', 'GlobalViewProps', 'ConfirmClosingMultipleTabs', 'RememberOpenedTabs'} & profile['General'].keys())
        native = Path('/usr/share/config.kcfg')
        if not (native / 'dolphin_generalsettings.kcfg').exists(): self.skipTest('Dolphin schemas not installed')
        keys = set()
        # PlacesPanel's internal schema and KF6 KToolBar are not installed here.
        keys.update({('PlacesPanel', 'IconSize'),
                     ('MainWindow][Toolbar mainToolBar', 'IconSize'),
                     ('MainWindow][Toolbar mainToolBar', 'ToolButtonStyle')})
        for path in native.glob('dolphin_*settings.kcfg'):
            for group in ET.parse(path).getroot().findall('{*}group'):
                for entry in group.findall('{*}entry'): keys.add((group.attrib['name'], entry.attrib['name']))
        for group, settings in profile.items():
            for key in settings: self.assertIn((group, key), keys)

    def test_upgrade_keeps_original_backup_and_later_user_preferences(self):
        with tempfile.TemporaryDirectory() as td:
            config = Path(td); path = config / 'dolphinrc'
            original = '[General]\nHomeUrl=/original\n'
            path.write_text(original); module.manage('apply', config)
            journal = config / 'nothing-kde/dolphin/state.json'
            state = json.loads(journal.read_text()); state.pop('revision'); journal.write_text(json.dumps(state))
            path.write_text(path.read_text().replace('/original', '/edited').replace('IconSize=64', 'IconSize=80'))
            module.manage('apply', config); module.manage('restore', config)
            self.assertIn('HomeUrl=/edited', path.read_text())
            self.assertIn('IconSize=80', path.read_text())
            self.assertEqual((config / 'nothing-kde/dolphin/dolphinrc.before').read_text(), original)

    def test_desktop_style_roundtrip_keeps_shortcuts_and_translations(self):
        with tempfile.TemporaryDirectory() as td:
            config = Path(td) / 'config'; data = Path(td) / 'data'
            desktop = data / 'applications/org.kde.dolphin.desktop'; desktop.parent.mkdir(parents=True)
            original = '[Desktop Entry]\nName=Dolphin\nName[tr]=Dolphin\nExec=dolphin %u\nX-KDE-Shortcuts=Meta+E\n'
            desktop.write_text(original)
            module.manage('apply', config, data)
            self.assertIn('-stylesheet "', desktop.read_text())
            self.assertIn('X-KDE-Shortcuts=Meta+E', desktop.read_text())
            desktop.write_text(desktop.read_text() + 'Comment=My files\n')
            module.manage('restore', config, data)
            self.assertEqual(desktop.read_text(), original + 'Comment=My files\n')
            self.assertEqual((config / 'nothing-kde/dolphin/style.qss').read_text(), '')

    def test_custom_launcher_is_not_overwritten(self):
        with tempfile.TemporaryDirectory() as td:
            config = Path(td) / 'config'; data = Path(td) / 'data'
            desktop = data / 'applications/org.kde.dolphin.desktop'; desktop.parent.mkdir(parents=True)
            original = '[Desktop Entry]\nExec=my-dolphin-wrapper %u\n'; desktop.write_text(original)
            with self.assertRaises(ValueError): module.manage('apply', config, data)
            self.assertEqual(desktop.read_text(), original)
            self.assertFalse((config / 'dolphinrc').exists())

    def test_qss_uses_palette_not_fixed_colors_or_global_selectors(self):
        style = (ROOT / 'dolphin/style.qss').read_text()
        self.assertIn('palette(highlight)', style)
        self.assertNotIn('rgba(', style)
        self.assertNotIn('#ffffff', style.lower())
        self.assertNotIn('QWidget {', style)
        self.assertIn('QTabBar > CloseButton', style)
        self.assertIn('min-width: 32px', style)
        self.assertIn('margin: 5px 3px;', style)

    def test_live_qt_stylesheet_roundtrip_with_trailing_newline(self):
        with tempfile.TemporaryDirectory() as td:
            config = Path(td); root = config / 'nothing-kde/dolphin'; root.mkdir(parents=True)
            style = (ROOT / 'dolphin/style.qss').read_text(); (root / 'style.qss').write_text(style)
            with patch.object(module.subprocess, 'check_output', side_effect=['org.kde.dolphin-123\n', '/* previous */\n']), patch.object(module.subprocess, 'run'):
                module.refresh_running_style(config, True)
            with patch.object(module.subprocess, 'check_output', side_effect=['org.kde.dolphin-123\n', style + '\n']), patch.object(module.subprocess, 'run') as run:
                module.refresh_running_style(config, False)
                self.assertEqual(run.call_args_list[0].args[0][-1], '/* previous */')

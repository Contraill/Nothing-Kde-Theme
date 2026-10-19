import json
from pathlib import Path
import re
import unittest

ROOT = Path(__file__).resolve().parents[1]
UI = ROOT / 'plasmoids/com.nothingplasma.panel/contents/island/ui'


def translation_catalogs():
    """Catalogs of the generated Translations.js, by language."""
    source = (UI / 'Translations.js').read_text()
    return json.loads(source.split('var catalogs = ', 1)[1].rstrip().rstrip(';'))


class IslandTests(unittest.TestCase):
    def test_all_translation_keys_exist_and_no_spanish_ui(self):
        cfg = (UI / 'Cfg.qml').read_text()
        catalogs = translation_catalogs()
        # Every key the panel asks for has English and Turkish text.
        for file in list(UI.glob('*.qml')) + list((UI.parent.parent / 'ui').rglob('*.qml')) + [UI.parent.parent / 'config/config.qml']:
            for key in re.findall(r'Cfg\.t\("([^"]+)"\)', file.read_text()):
                self.assertIn(key, catalogs['en'], str(file))
                self.assertIn(key, catalogs['tr'], str(file))
        self.assertNotIn('EN LA BANDEJA', (UI / 'NotifPanel.qml').read_text())
        self.assertNotIn('es_ES', cfg)
        self.assertEqual(catalogs['tr']['COFFEE MODE'], 'KAHVE MODU')
        self.assertIn('property string lang: "auto"', cfg)
        # Language choices are Cfg.t() catalogs, not per-language branches.
        for file in (UI.parent.parent).rglob('*.qml'):
            self.assertNotIn('Cfg.turkish', file.read_text(), str(file))
            self.assertNotRegex(file.read_text(), r'\bi18nc?\(', str(file))

    @unittest.skipUnless(__import__('shutil').which('msgfmt'), 'gettext msgfmt is not installed')
    def test_translation_sources_build_the_catalog(self):
        import subprocess
        result = subprocess.run(['python3', '-I', str(ROOT / 'po/build.py'), '--check'], capture_output=True, text=True)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn('PowerPrivacyCard {', (UI / 'ExpandedPanel.qml').read_text())
        self.assertNotIn('Cfg.t("PLACEHOLDER")', (UI / 'ExpandedPanel.qml').read_text())

    def test_recording_and_custom_coffee_process_are_not_shipped(self):
        text = '\n'.join(p.read_text() for p in UI.glob('*.qml'))
        for forbidden in ('Recorder.', 'RecordView {', 'coffee.py', 'pkill', 'spectacle', 'pw-record', 'parec'):
            self.assertNotIn(forbidden, text)
        self.assertIn('BatteryMonitor.InhibitionControl', text)
        self.assertFalse((UI / 'AppLauncher.qml').exists())
        self.assertIn('Kicker.RootModel', (UI.parent.parent / 'ui/BottomPanel.qml').read_text())

    def test_offline_radio_does_not_disable_whole_panel(self):
        text = (UI / 'ConnPanel.qml').read_text()
        self.assertIn('readonly property bool radioOn:', text)
        self.assertNotIn('property bool enabled:', text)
        self.assertNotIn('root.enabled', text)

    def test_existing_backends_and_native_notification_settings(self):
        net = (UI / 'Net.qml').read_text()
        # Passwords reach NetworkManager over D-Bus, never on a command line.
        self.assertIn('handler.addAndActivateConnection(row.devicePath, row.specificPath, password)', net)
        self.assertNotIn('nmcli', net)
        self.assertNotIn('bluetoothctl', net)
        self.assertIn('BluezQt.Manager', net)
        self.assertIn('onHeldChanged: model.DelayModelUpdates = held', net)
        audio = (UI / 'Audio.qml').read_text()
        # Native PulseAudio bindings; choosing a level also unmutes, as in Plasma's applet.
        self.assertIn('org.kde.plasma.private.volume', audio)
        self.assertIn('PA.PreferredDevice.sink', audio)
        self.assertIn('if (v > 0 && device.muted) device.muted = false;', audio)
        self.assertNotIn('wpctl', audio)
        self.assertNotIn('refreshAudio', (ROOT / 'plasmoids/com.nothingplasma.panel/contents/ui/TopPanel.qml').read_text())
        notifs = (UI / 'Notifs.qml').read_text()
        self.assertIn('settings.notificationsInhibitedUntil', notifs)
        # Do Not Disturb stays on until turned off (Plasma's own one-year convention).
        self.assertIn('until.setFullYear(until.getFullYear() + 1)', notifs)
        self.assertNotIn('60 * 60 * 1000', notifs)
        self.assertIn('invokeDefaultAction(root.model.index(row, 0), NM.Notifications.Close)', notifs)
        self.assertIn('root.model.reply(', notifs)
        self.assertNotIn('NM.Server.inhibited =', notifs)

    def test_live_activities_and_island_audio_osd(self):
        compact = (UI / 'CompactPill.qml').read_text()
        self.assertIn('ActivityChips {', compact)
        self.assertIn('IslandOsd {', compact)
        osd = (UI / 'IslandOsd.qml').read_text()
        # Startup and output switches change the volume too; they must not flash the OSD.
        self.assertIn('if (Audio.sink !== root.lastSink)', osd)
        self.assertIn('Backend.expanded', osd)
        audio = (UI / 'Audio.qml').read_text()
        self.assertIn('!model.VirtualStream && !model.Corked', audio)
        helper = (ROOT / 'runtime/nothing-control.sh').read_text()
        self.assertIn('for key in VolumeOsd MuteOsd MicrophoneSensitivityOsd', helper)
        self.assertIn('--notify', helper.split('audio_osd() {', 1)[1].split('\n}\n', 1)[0])
        self.assertIn('audio-osd plasma', (ROOT / 'uninstall.sh').read_text())

    def test_auto_theme_status_only_claims_the_nothing_pair(self):
        import os, subprocess, tempfile
        with tempfile.TemporaryDirectory() as td:
            stub = Path(td) / 'kreadconfig6'
            # Prints $KEY_<name> for --key <name>.
            stub.write_text('#!/bin/bash\nwhile [ $# -gt 0 ]; do [ "$1" = --key ] && k=$2; shift; done\nv=KEY_$k; echo "${!v}"\n')
            stub.chmod(0o755)
            def status(auto, light, dark):
                env = dict(os.environ, PATH=td + ':' + os.environ['PATH'], KEY_AutomaticLookAndFeel=auto,
                           KEY_DefaultLightLookAndFeel=light, KEY_DefaultDarkLookAndFeel=dark)
                return subprocess.run(['bash', str(ROOT / 'runtime/nothing-control.sh'), 'auto-theme', 'status'],
                                      env=env, capture_output=True, text=True, check=True).stdout.strip()
            self.assertEqual(status('true', 'com.nothingplasma.light', 'com.nothingplasma.dark'), 'on')
            self.assertEqual(status('true', 'org.kde.breeze.desktop', 'org.kde.breezedark.desktop'), 'off')
            self.assertEqual(status('false', 'com.nothingplasma.light', 'com.nothingplasma.dark'), 'off')
        self.assertIn('auto-theme off', (ROOT / 'uninstall.sh').read_text())

    def test_player_switcher_skips_proxies_and_text_is_readable(self):
        media = (UI / 'Media.qml').read_text()
        self.assertIn('objectName === "playerctld"', media)
        self.assertIn('!row.multiplexer && !row.proxy', media)
        self.assertIn('Media.controls(modelData)', (UI / 'MediaCard.qml').read_text())
        # outline is a border tone; text directly followed by it is unreadable.
        for file in UI.glob('*.qml'):
            self.assertNotRegex(file.read_text(), r'\n\s*text: [^\n]*\n\s*color: Theme\.outline\n', str(file))
        self.assertIn('color: Theme.fgDim', (UI / 'StatusPills.qml').read_text().split('text: Audio.description', 1)[1].split('\n')[1])

    def test_coffee_mode_survives_shell_restarts(self):
        coffee = (UI / 'Coffee.qml').read_text()
        self.assertIn('BatteryMonitor.InhibitionControl', coffee)
        self.assertIn('root.panelConfig.coffeeMode = enabled', coffee)
        self.assertIn('(root.panelConfig?.coffeeMode ?? false) && !root.active', coffee)
        self.assertIn('Binding { target: Island.Coffee; property: "panelConfig"', (UI.parent.parent / 'ui/TopPanel.qml').read_text())
        self.assertIn('Coffee.toggle()', (UI / 'QuickActions.qml').read_text())

    def test_fonts_and_attribution_are_bundled(self):
        base = UI.parent
        for file in ('LICENSE', 'NOTICE.md', 'fonts/OFL-1.1.txt', 'fonts/Apache-2.0.txt',
                     'fonts/SpaceGrotesk.ttf', 'fonts/MaterialSymbolsRounded.ttf',
                     'fonts/NothingDots.ttf', 'fonts/NothingDots-OFL.txt'):
            self.assertTrue((base / file).is_file(), file)
        # One build of the dot font, shared by the panel and the desktop widgets.
        widget_font = ROOT / 'widgets/shared/fonts/NothingDots.ttf'
        self.assertEqual((base / 'fonts/NothingDots.ttf').read_bytes(), widget_font.read_bytes())
        self.assertEqual(list(ROOT.glob('**/ndot*')), [])

    def test_no_side_panel_sources_or_state(self):
        main = ROOT / 'plasmoids/com.nothingplasma.panel/contents/ui'
        self.assertFalse((main / 'LeftRail.qml').exists())
        self.assertFalse((main / 'RightRail.qml').exists())
        layout = (ROOT / 'plasma/layout-templates/com.nothingplasma.island.panel/contents/layout.js').read_text()
        self.assertIn('"top", "top", 50', layout)
        self.assertIn('"bottom", "bottom", 50', layout)

    def test_brightness_reuses_system_backend_and_two_column_layout(self):
        card = (UI / 'BrightnessCard.qml').read_text()
        self.assertIn('controls.setDisplayBrightness(value, display?.displayName ?? "")', card)
        self.assertIn('!Backend.preview && available', card)
        self.assertIn('interval: 100', card)
        self.assertIn('from: root.keyboardMode ? 0 : 1', card)
        pills = (UI / 'StatusPills.qml').read_text()
        self.assertIn('columns: 2', pills)
        self.assertIn('BrightnessCard {', pills)
        self.assertIn('maxValue: Audio.maxVolume', pills)
        self.assertIn('MicToggle {', pills)

    def test_battery_is_outside_media_replacement_and_has_percentage(self):
        compact = (UI / 'CompactPill.qml').read_text()
        self.assertLess(compact.index('id: persistentBattery'), compact.index('id: statusGroup'))
        self.assertIn('anchors.right: persistentBattery.visible ? persistentBattery.left', compact)
        self.assertIn('id: battery\n', (UI / 'ExpandedPanel.qml').read_text())
        self.assertIn('root.percent + "%"', (UI / 'Battery.qml').read_text())

    def test_brightness_overlay_requires_native_capability(self):
        card = (UI / 'BrightnessCard.qml').read_text()
        self.assertIn('acceptedButtons: Qt.RightButton', card)
        self.assertIn('enabled: !root.keyboardMode && !root.display && root.detailsAvailable', card)
        panel = (UI / 'ExpandedPanel.qml').read_text()
        self.assertIn('name === "brightness" && !(Backend.controls?.brightnessDetailsAvailable ?? false)', panel)
        self.assertIn('onBrightnessDetailsAvailableChanged', panel)
        controls = (ROOT / 'plasmoids/com.nothingplasma.panel/contents/ui/components/SystemControls.qml').read_text()
        self.assertIn('Brightness.KeyboardBrightnessControl', controls)
        self.assertIn('keyboardControl.isBrightnessAvailable && keyboardControl.brightnessMax > 0', controls)
        # PowerDevil also drives external monitors; never write 0 to a display.
        self.assertIn('Brightness.ScreenBrightnessControl', controls)
        self.assertIn('screenControl.setBrightness(display.displayName, Math.max(1, level))', controls)


if __name__ == '__main__':
    unittest.main()

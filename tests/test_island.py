import json
from pathlib import Path
import re
import unittest

ROOT = Path(__file__).resolve().parents[1]
UI = ROOT / 'plasmoids/com.nothingplasma.panel/contents/island/ui'


class IslandTests(unittest.TestCase):
    def test_all_translation_keys_exist_and_no_spanish_ui(self):
        cfg = (UI / 'Cfg.qml').read_text()
        texts = json.loads(cfg.split('readonly property var textos: (', 1)[1].split(')\n', 1)[0])
        for file in UI.glob('*.qml'):
            for key in re.findall(r'Cfg\.t\("([^"]+)"\)', file.read_text()):
                self.assertIn(key, texts, str(file))
        self.assertNotIn('EN LA BANDEJA', (UI / 'NotifPanel.qml').read_text())
        self.assertNotIn('es_ES', cfg)
        self.assertEqual(texts['COFFEE MODE'][0], 'KAHVE MODU')
        self.assertIn('property string lang: "auto"', cfg)
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
        self.assertIn('readonly property bool radioEnabled:', text)
        self.assertNotIn('property bool enabled:', text)
        self.assertNotIn('popup.enabled', text)

    def test_existing_backends_and_native_notification_settings(self):
        net = (UI / 'Net.qml').read_text()
        # Passwords reach NetworkManager over D-Bus, never on a command line.
        self.assertIn('handler.addAndActivateConnection(row.devicePath, row.specificPath, password)', net)
        self.assertNotIn('nmcli', net)
        self.assertNotIn('bluetoothctl', net)
        self.assertIn('BluezQt.Manager', net)
        self.assertIn('networkModel.delayModelUpdates = holdNetworkUpdates', net)
        audio = (UI / 'Audio.qml').read_text()
        # Native PulseAudio bindings; choosing a level also unmutes, as in Plasma's applet.
        self.assertIn('org.kde.plasma.private.volume', audio)
        self.assertIn('PA.PreferredDevice.sink', audio)
        self.assertIn('if (v > 0 && device.muted) device.muted = false;', audio)
        self.assertNotIn('wpctl', audio)
        self.assertNotIn('refreshAudio', (ROOT / 'plasmoids/com.nothingplasma.panel/contents/ui/TopPanel.qml').read_text())
        notifs = (UI / 'Notifs.qml').read_text()
        self.assertIn('settings.notificationsInhibitedUntil', notifs)
        self.assertNotIn('NM.Server.inhibited =', notifs)

    def test_fonts_and_attribution_are_bundled(self):
        base = UI.parent
        for file in ('LICENSE', 'NOTICE.md', 'fonts/OFL-1.1.txt', 'fonts/Apache-2.0.txt',
                     'fonts/SpaceGrotesk.ttf', 'fonts/MaterialSymbolsRounded.ttf',
                     'fonts/ndot-47-inspired-by-nothing.otf'):
            self.assertTrue((base / file).is_file(), file)

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
        self.assertLess(compact.index('id: persistentBattery'), compact.index('id: rightGroup'))
        self.assertIn('anchors.right: persistentBattery.visible ? persistentBattery.left', compact)
        self.assertIn('id: headerBattery', (UI / 'ExpandedPanel.qml').read_text())
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

from pathlib import Path
import unittest
import xml.etree.ElementTree as ET

ROOT=Path(__file__).resolve().parents[1]

class FinalSettings(unittest.TestCase):
    def test_native_persistent_defaults(self):
        for file,key in [('plasmoids/com.nothingplasma.panel/contents/config/main.xml','confirmPowerActions'),
                         ('plasma/aurorae/org.glassy.decoration/contents/config/main.xml','RoundBottomCorners')]:
            entries=[e for e in ET.parse(ROOT/file).iter() if e.tag.endswith('entry') and e.get('name')==key]
            self.assertEqual(len(entries),1)
            self.assertEqual(entries[0].get('type'),'Bool')
            self.assertEqual(next(iter(entries[0])).text,'true')
    def test_no_icon_activation_or_package_removal(self):
        for file in ('install.sh','uninstall.sh','runtime/appearance.py'):
            text=(ROOT/file).read_text()
            self.assertNotIn('pacman -R',text)
        for defaults in (ROOT/'plasma/look-and-feel').glob('*/contents/defaults'):
            self.assertNotIn('[Icons]',defaults.read_text())
    def test_power_backend_keeps_native_authority(self):
        text=(ROOT/'plasmoids/com.nothingplasma.panel/contents/island/ui/PowerView.qml').read_text()
        for action in ('logoutAndShutdown','logoutAndReboot','PowerManagement Suspend'):
            self.assertIn(action,text)
        self.assertNotIn('--force',text)
        self.assertNotIn('--ignore-inhibitors',text)
        self.assertIn('popup.requestAction(op.titulo, op.comando, op.pesada)',text)

if __name__=='__main__': unittest.main()

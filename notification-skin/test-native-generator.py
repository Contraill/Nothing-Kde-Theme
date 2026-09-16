import importlib.util, pathlib, tempfile, unittest, shutil
root=pathlib.Path(__file__).resolve().parent
spec=importlib.util.spec_from_file_location('prep',root/'prepare-native.py')
p=importlib.util.module_from_spec(spec);spec.loader.exec_module(p)
class GeneratorTests(unittest.TestCase):
 def test_pinned_source_build_maps_every_native_global(self):
  with tempfile.TemporaryDirectory() as td:
   out=p.generate(p.verified_source('Globals.qml'),p.verified_source('NotificationPopup.qml'),pathlib.Path(td)/'out')
   q=(out/'contents/ui/main.qml').read_text()
   self.assertIn('Notifications.Globals.positionPopups()',q)
   self.assertIn('Notifications.Globals.inhibited',q)
   self.assertIn('Notifications.Globals.plasmoid.forceActivateWindow',q)
   self.assertNotIn('PlasmaCore.Theme',q)
   self.assertIn('required property int jobError',q)
 def test_refuses_to_replace_unrelated_output(self):
  with tempfile.TemporaryDirectory() as td:
   path=pathlib.Path(td);(path/'keep.txt').write_text('user data')
   with self.assertRaises(ValueError):
    p.generate(p.verified_source('Globals.qml'),p.verified_source('NotificationPopup.qml'),path)
   self.assertEqual((path/'keep.txt').read_text(),'user data')
 def test_braces_ignore_strings_and_comments(self):
  self.assertEqual(p.block('delegate: A { x: "}"; // {\n y: 1 }','delegate: A {'),'delegate: A { x: "}"; // {\n y: 1 }')
 def test_hash_pin_rejects_wrong_source(self):
  with tempfile.TemporaryDirectory() as td:
   path=pathlib.Path(td)/p.SOURCES['Globals.qml'][0];path.parent.mkdir(parents=True);path.write_text('wrong')
   with self.assertRaises(ValueError):p.verified_source('Globals.qml',td)
 def test_generate_native_contract(self):
  globals_text='''QtObject { id: globals\n property Instantiator popupInstantiator: Instantiator {\n model: globals.popupNotificationsModel\n        delegate: NotificationPopup {\n            id: popup\n            required property int index\n            required property var model\n            required property string notificationId\n            onExpired: model.expired = true\n            modelInterface { onReplied: text => globals.popupNotificationsModel.reply(index, text, 0) }\n        }\n } }'''
  popup='''import QtQuick\nimport plasma.applet.org.kde.plasma.notifications as NotificationsApplet\nNotificationsApplet.NotificationWindow {\n mainItem: Item {\n        DraggableDelegate {\n            contentItem: Delegates.DelegatePopup { modelInterface: parent.modelInterface }\n        }\n }\n}'''
  with tempfile.TemporaryDirectory() as td:
   out=p.generate(globals_text,popup,pathlib.Path(td)/'out')
   q=(out/'contents/ui/main.qml').read_text();self.assertIn('NothingNotificationPopup {',q)
   self.assertIn('SortByDate',q);self.assertIn('Binding.RestoreBinding',q)
   self.assertIn('onReplied:',q)
   self.assertIn('NothingDelegatePopup {',(out/'contents/ui/NothingNotificationPopup.qml').read_text())
   self.assertTrue((out/'metadata.json').exists())
 def test_no_system_mutation_in_generator(self):
  text=(root/'prepare-native.py').read_text()
  for forbidden in ('/usr/share/plasma/plasmoids','systemctl','killall','rm -rf /','org.freedesktop.Notifications /'):
   self.assertNotIn(forbidden,text)
if __name__=='__main__':unittest.main()

"""Exercise the generated native popup's timeout/hover geometry contract."""
import importlib.util
import os
from pathlib import Path
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
RUNNER = os.environ.get('NOTHING_NATIVE_QML_RUNNER', '')


class NotificationHoverTests(unittest.TestCase):
    @unittest.skipUnless(RUNNER and Path(RUNNER).is_file(), 'Set NOTHING_NATIVE_QML_RUNNER to run native notification geometry tests')
    def test_paused_timer_does_not_resize_card(self):
        spec = importlib.util.spec_from_file_location('notification_generator', ROOT / 'notification-skin/prepare-native.py')
        generator = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(generator)
        with tempfile.TemporaryDirectory(prefix='nothing-hover-') as td:
            folder = Path(td)
            package = generator.generate(generator.verified_source('Globals.qml'), generator.verified_source('NotificationPopup.qml'), folder / 'adapter')
            popup = (package / 'contents/ui/NothingNotificationPopup.qml').read_text()
            self.assertIn('hasTimeout: notificationPopup.effectiveTimeout > 0', popup)
            (folder / 'tst_hover.qml').write_text('''
import QtQuick
import QtTest
import plasma.applet.org.kde.plasma.notifications as Native
import "adapter/contents/ui/delegates" as Delegates
Item {
    width: 400; height: 400
    Delegates.NothingDelegatePopup {
        id: card
        width: 320; height: implicitHeight
        hasTimeout: true
        modelInterface { applicationName: "Test"; summary: "Hover geometry"; body: "A timed notification"; timeout: 5000; closable: true }
    }
    SignalSpy { id: closed; target: card.modelInterface; signalName: "closeClicked" }
    TestCase {
        name: "NotificationHoverGeometry"
        when: windowShown
        function test_pause_resume_and_close() {
            waitForRendering(card);
            const height = card.implicitHeight;
            verify(height > 0);
            card.modelInterface.timeout = 0;
            wait(30);
            compare(card.implicitHeight, height);
            card.modelInterface.timeout = 5000;
            wait(30);
            compare(card.implicitHeight, height);
            const close = findChild(card, "notificationCloseButton");
            mouseClick(close, close.width / 2, close.height / 2);
            compare(closed.count, 1);
            card.hasTimeout = false;
            wait(30);
            verify(card.implicitHeight < height);
        }
    }
}
''')
            result = subprocess.run([RUNNER, '-input', str(folder), '-o', '-,txt'], capture_output=True, text=True,
                                    env=dict(os.environ, QT_QPA_PLATFORM='offscreen', QT_QUICK_BACKEND='software', QT_FORCE_STDERR_LOGGING='1', NOTHING_TEST_NOTIFICATIONS='1'), timeout=30)
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

    def test_focused_custom_popup_does_not_obstruct_itself(self):
        spec = importlib.util.spec_from_file_location('notification_generator', ROOT / 'notification-skin/prepare-native.py')
        generator = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(generator)
        upstream = generator.verified_source('Globals.qml')
        controller = (ROOT / 'notification-skin/native-controller.qml.in').read_text()
        anchor = 'function retainExternalObstruction()'
        guard = generator.block(controller, anchor) if anchor in controller else anchor + ' {}'
        script = '''
const assert = require('node:assert/strict');
const Qt = {AlignTop: 1, AlignBottom: 2, AlignLeft: 4, AlignRight: 8, AlignHCenter: 16,
    rect: (x,y,width,height) => ({x,y,width,height})};
const popup = {x:0,y:0,width:320,height:100,visible:true};
const popupInstantiator = {count:1,objectAt:()=>popup};
const plasmoid = {};
const globals = {armed:true,lastExternalObstruction:null,screenRect:{x:0,y:0,width:1920,height:1080},visualParent:{Window:{window:null}}};
let obstruction = null;
const native = {popupInstantiator};
Object.defineProperty(globalThis, 'obstructingDialog', {get:()=>obstruction,
    set:value=>{obstruction=value;retainExternalObstruction();}});
Object.defineProperty(native, 'obstructingDialog', {get:()=>obstructingDialog,
    set:value=>{obstructingDialog=value;}});
const Notifications = {Globals:native};
const popupLocation=Qt.AlignTop|Qt.AlignRight, popupEdgeDistance=12, popupSpacing=8, popupMaximumScreenFill=.8;
class NotificationPopup {}
let focusDialog = null;
'''
        script += generator.block(upstream, 'function rectIntersect(') + '\n'
        script += generator.block(upstream, 'function positionPopups()') + '\n' + guard + '\n'
        script += 'function focusChanged() ' + generator.block(upstream, 'onFocusDialogChanged:').split(':', 1)[1] + '\n'
        script += '''
positionPopups();
const originalY = popup.y;
focusDialog = popup;
focusChanged();
assert.equal(popup.y, originalY, 'clicking must not move the popup away from itself');
const external = {x:popup.x,y:12,width:340,height:200,visible:true};
focusDialog = external;
focusChanged();
assert.equal(popup.y,224, 'genuine dialogs must still be avoided');
focusDialog = popup;
focusChanged();
assert.equal(obstructingDialog,external, 'keep the last external dialog when a popup takes focus');
assert.equal(popup.y,224);
external.visible = false;
positionPopups();
assert.equal(popup.y,originalY);
globals.armed=false;
Notifications.Globals.obstructingDialog=popup;
assert.equal(obstructingDialog,popup, 'disabled adapter leaves native state alone');
'''
        result = subprocess.run(['node', '-e', script], capture_output=True, text=True, timeout=10)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

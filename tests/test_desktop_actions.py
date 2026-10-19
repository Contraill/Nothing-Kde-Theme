"""Read real KDE desktop actions from a private fixture; never start an application."""
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
# As validate.sh: Qt 6's runner, never a Qt 5 qmltestrunner earlier on PATH.
RUNNER = (shutil.which('qmltestrunner6') or (os.access('/usr/lib/qt6/bin/qmltestrunner', os.X_OK) and '/usr/lib/qt6/bin/qmltestrunner')
          or shutil.which('qmltestrunner'))


@unittest.skipUnless(RUNNER, 'Qt Quick Test runner required')
class DesktopActionsTests(unittest.TestCase):
    def test_native_actions_file_uri_labels_arguments_and_empty_replacement(self):
        with tempfile.TemporaryDirectory(prefix='nothing-actions-') as td:
            home = Path(td)
            desktop = home / 'fixture with spaces.desktop'
            desktop.write_text('[Desktop Entry]\nType=Application\nName=Nothing action fixture\nExec=/bin/true\n'
                               'Actions=First;Second;\n[Desktop Action First]\nName=First native action\n'
                               'Exec=/bin/true first\n[Desktop Action Second]\nName=Second native action\nExec=/bin/true second\n')
            source = (ROOT / 'plasmoids/com.nothingplasma.panel/contents/ui/components').as_uri()
            qml = '''import QtQuick
import QtTest
import "SOURCE" as Components
Item {
    Components.DesktopActions { id: actions; launcherUrl: "DESKTOP" }
    TestCase {
        name: "DesktopActions"
        when: windowShown
        function test_native_actions() {
            tryVerify(() => actions.actions.length === 2);
            compare(actions.actions[0].text, "First native action");
            compare(actions.actions[1].text, "Second native action");
            verify(actions.actions[1].actionArgument !== undefined);
            compare(actions.actions[1].actionId, "_kicker_jumpListAction");
            actions.refresh();
            tryVerify(() => actions.actions.length === 2);
            actions.launcherUrl = "";
            tryVerify(() => actions.actions.length === 0);
        }
    }
}'''.replace('SOURCE', source).replace('DESKTOP', desktop.as_uri())
            (home / 'tst_actions.qml').write_text(qml)
            env = dict(os.environ, QT_FORCE_STDERR_LOGGING='1', QT_QPA_PLATFORM='offscreen', QT_QUICK_BACKEND='software',
                       XDG_CONFIG_HOME=str(home/'config'), XDG_CACHE_HOME=str(home/'cache'))
            result = subprocess.run([RUNNER, '-input', str(home/'tst_actions.qml'), '-o', '-,txt'],
                                    env=env, capture_output=True, text=True, timeout=20)
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

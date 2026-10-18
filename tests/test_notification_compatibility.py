import importlib.util
import os
from pathlib import Path
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location('notification_compat', ROOT / 'notification-skin/compatibility.py')
compat = importlib.util.module_from_spec(spec)
spec.loader.exec_module(compat)


class ContractTests(unittest.TestCase):
    def fixture(self):
        import re
        custom = (ROOT / 'notification-skin/delegates/NothingDelegatePopup.qml').read_text()
        model = '\n'.join('property var ' + name for name in set(re.findall(r'modelInterface\.(\w+)', custom)))
        return {'global/Globals.qml': compat.prepare.verified_source('Globals.qml'),
                'NotificationPopup.qml': compat.prepare.verified_source('NotificationPopup.qml'),
                'qmldir': 'singleton Globals 254.0 global/Globals.qml\nDraggableDelegate 254.0 DraggableDelegate.qml',
                'NotificationWindow': 'available', 'components/ModelInterface.qml': model,
                **{'components/' + name + '.qml': 'property ModelInterface modelInterface'
                   for name in ('Body', 'Icon', 'FooterLoader')}}

    def test_compatible_contract_without_patch_version(self):
        source = self.fixture()
        source['global/Globals.qml'] += '\n// Different distro patch\n'
        source['NotificationPopup.qml'] = source['NotificationPopup.qml'].replace('property int popupWidth', 'property   int   popupWidth')
        compat.validate(source)

    def test_plasma_6_8_job_error_type_is_compatible(self):
        source = self.fixture()
        source['global/Globals.qml'] = source['global/Globals.qml'].replace('required property string jobError', 'required property int jobError')
        compat.validate(source)

    def test_unrelated_global_changes_allowed(self):
        source = self.fixture()
        source['global/Globals.qml'] = source['global/Globals.qml'].replace('property int popupSpacing:', 'property int popupSpacing: /* distro */')
        compat.validate(source)

    def test_popup_binding_change_does_not_change_its_contract(self):
        source = self.fixture()
        source['NotificationPopup.qml'] = source['NotificationPopup.qml'].replace('defaultTimeout: 5000', 'defaultTimeout: 6000')
        compat.validate(source)

    def test_missing_or_changed_contract_rejected(self):
        for file, old, new in [('global/Globals.qml', 'required property string notificationId', 'required property int notificationId'),
                               ('global/Globals.qml', 'property Instantiator popupInstantiator:', 'property Instantiator renamed:'),
                               ('NotificationPopup.qml', 'property int popupWidth', 'property bool popupWidth'),
                               ('components/Body.qml', 'modelInterface', 'renamed'),
                               ('components/ModelInterface.qml', 'property var summary', 'property var renamed')]:
            with self.subTest(file=file, old=old):
                source = self.fixture(); self.assertIn(old, source[file])
                source[file] = source[file].replace(old, new)
                with self.assertRaises(ValueError): compat.validate(source)


class InstallerTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix='nothing-notification-test-')
        self.addCleanup(self.temp.cleanup)
        self.home = Path(self.temp.name)
        self.bin = self.home / 'bin'; self.bin.mkdir()
        self.env = dict(os.environ, PATH=str(self.bin) + ':' + os.environ['PATH'],
                        XDG_DATA_HOME=str(self.home / 'data'), XDG_CONFIG_HOME=str(self.home / 'config'),
                        XDG_CACHE_HOME=str(self.home / 'cache'), TMPDIR=str(self.home),
                        NOTHING_TEST_LOG=str(self.home / 'calls'), PYTHONDONTWRITEBYTECODE='1')
        self.mock('plasmashell', 'echo "plasmashell 6.7.99"')
        self.mock('python3', 'case "$1" in */compatibility.py) exit "${COMPAT_EXIT:-0}";; esac\nexec /usr/bin/python3 "$@"')
        self.mock('qmlformat6', 'exit "${PARSE_EXIT:-0}"')
        self.mock('sleep', 'exit 0')
        self.mock('systemctl', 'case "$*" in *restart*) exit "${RESTART_EXIT:-0}";; *MainPID*) echo 4242;; esac')
        self.mock('journalctl', 'if [ "${ACTIVATION_FAIL:-0}" = 0 ]; then echo NOTHING_NOTIFICATION_BRIDGE_ACTIVE:true; fi')
        self.mock('qdbus6', '''case "$*" in
*GetServerInformation*) exit "${SERVER_EXIT:-0}";;
*NOTHING_BRIDGE_PRESENT*) if [ "${BRIDGE_PRESENT:-0}" = 1 ]; then echo NOTHING_BRIDGE_PRESENT; fi;;
*NOTHING_HOST_MISSING*) echo NOTHING_HOST:1;;
*NOTHING_NOTIFICATION_BRIDGE_CREATED*)
 if [ "${ATTACH_FAIL:-0}" = 0 ]; then echo NOTHING_NOTIFICATION_BRIDGE_CREATED:2; else exit 1; fi;;
*NOTHING_NOTIFICATION_BRIDGE_REMOVED*) echo NOTHING_NOTIFICATION_BRIDGE_REMOVED:1;;
esac''')
        self.mock('kpackagetool6', '''for arg in "$@"; do
 case "$arg" in
 --list) exit 0;;
 --install|--upgrade) operation="$arg";;
 esac
 last="$arg"
done
if [ -n "${operation:-}" ]; then
 [ "${PACKAGE_EXIT:-0}" = 0 ] || exit "$PACKAGE_EXIT"
 exec /usr/bin/python3 -c 'import os,sys,shutil,pathlib; p=pathlib.Path(os.environ["XDG_DATA_HOME"])/"plasma/plasmoids/com.nothingplasma.notificationbridge"; shutil.copytree(sys.argv[1],p,dirs_exist_ok=True)' "$last"
fi''')

    def mock(self, name, body):
        path = self.bin / name
        path.write_text('#!/bin/bash\nprintf "%s %s\\n" "' + name + '" "$*" >> "$NOTHING_TEST_LOG"\n' + body + '\n')
        path.chmod(0o755)

    def run_install(self, *args, **env):
        return subprocess.run(['bash', str(ROOT / 'install.sh'), *args],
                              env={**self.env, **env}, capture_output=True, text=True, timeout=25)

    def calls(self):
        return (self.home / 'calls').read_text()

    def test_other_patch_installs_and_reinstall_is_noop(self):
        for _ in range(2):
            result = self.run_install('--notifications-only', '--package-only')
            self.assertEqual(result.returncode, 0, result.stderr)
        calls = self.calls()
        self.assertEqual(calls.count('kpackagetool6 --type Plasma/Applet --install'), 1)
        self.assertEqual(len(list((self.home / 'data/nothing-plasma/backups').iterdir())), 1)
        self.assertFalse(list(self.home.glob('nothing-kde-notifications-*')))

    def test_unknown_contract_falls_back_without_install(self):
        result = self.run_install('--notifications-only', COMPAT_EXIT='3')
        self.assertEqual(result.returncode, 3)
        self.assertNotIn('kpackagetool6', self.calls())
        self.assertIn('NOTHING_NOTIFICATION_BRIDGE_REMOVED', self.calls())
        self.assertFalse((self.home / 'data').exists())

    def test_force_and_restart_in_either_order(self):
        for args in [('--notifications-only', '--force-notifications', '--restart-plasma'),
                     ('--force-notifications', '--restart-plasma', '--notifications-only')]:
            result = self.run_install(*args, COMPAT_EXIT='3')
            self.assertEqual(result.returncode, 0, result.stderr)
        self.assertNotIn('compatibility.py', self.calls())
        self.assertIn('systemctl --user restart plasma-plasmashell.service', self.calls())

    def test_rejected_installed_adapter_is_not_rediscovered_by_layouts(self):
        result = self.run_install('--notifications-only', '--package-only')
        self.assertEqual(result.returncode, 0, result.stderr)
        result = self.run_install('--notifications-only', COMPAT_EXIT='3')
        self.assertEqual(result.returncode, 3, result.stderr)
        installed = self.home / 'data/plasma/plasmoids/com.nothingplasma.notificationbridge'
        self.assertFalse(installed.exists())
        backups = list((self.home / 'data/nothing-plasma/backups').glob('native-notifications-incompatible-*/com.nothingplasma.notificationbridge/metadata.json'))
        self.assertEqual(len(backups), 1)

    def test_force_never_bypasses_parse_guard(self):
        result = self.run_install('--notifications-only', '--force-notifications', PARSE_EXIT='1')
        self.assertNotEqual(result.returncode, 0)
        self.assertNotIn('kpackagetool6', self.calls())
        self.assertFalse((self.home / 'data').exists())

    def test_force_never_bypasses_native_service_guard(self):
        result = self.run_install('--notifications-only', '--force-notifications', SERVER_EXIT='1')
        self.assertNotEqual(result.returncode, 0)
        self.assertNotIn('kpackagetool6', self.calls())
        self.assertFalse((self.home / 'data').exists())

    def test_current_live_attachment_is_noop(self):
        result = self.run_install('--notifications-only', '--package-only')
        self.assertEqual(result.returncode, 0, result.stderr)
        result = self.run_install('--notifications-only', BRIDGE_PRESENT='1')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn('already current and attached', result.stdout)
        self.assertEqual(len(list((self.home / 'data/nothing-plasma/backups').iterdir())), 1)
        self.assertNotIn('NOTHING_NOTIFICATION_BRIDGE_CREATED', self.calls())

    def test_failed_upgrade_restores_previous_package_bytes(self):
        result = self.run_install('--notifications-only', '--package-only')
        self.assertEqual(result.returncode, 0, result.stderr)
        installed = self.home / 'data/plasma/plasmoids/com.nothingplasma.notificationbridge'
        main = installed / 'contents/ui/main.qml'
        main.write_text(main.read_text() + '\n// previous package\n')
        before = {str(p.relative_to(installed)): p.read_bytes() for p in installed.rglob('*') if p.is_file()}
        result = self.run_install('--notifications-only', ATTACH_FAIL='1')
        self.assertNotEqual(result.returncode, 0)
        after = {str(p.relative_to(installed)): p.read_bytes() for p in installed.rglob('*') if p.is_file()}
        self.assertEqual(before, after)

    def test_post_install_failures_detach_and_preserve_layout(self):
        config = self.home / 'config'; config.mkdir()
        layout = config / 'plasma-org.kde.plasma.desktop-appletsrc'
        layout.write_text('user layout — never restore over this')
        for fault in ('PACKAGE_EXIT', 'ATTACH_FAIL', 'RESTART_EXIT', 'ACTIVATION_FAIL'):
            with self.subTest(fault=fault):
                result = self.run_install('--notifications-only', '--restart-plasma', **{fault: '1'})
                self.assertNotEqual(result.returncode, 0, result.stdout)
                self.assertIn('NOTHING_NOTIFICATION_BRIDGE_REMOVED', self.calls())
                self.assertEqual(layout.read_text(), 'user layout — never restore over this')
                self.assertFalse(list(self.home.glob('nothing-kde-notifications-*')))

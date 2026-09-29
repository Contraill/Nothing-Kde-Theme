import importlib.util
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

spec = importlib.util.spec_from_file_location('login_wallpaper', Path(__file__).resolve().parents[1] / 'runtime/login-wallpaper.py')
login = importlib.util.module_from_spec(spec)
spec.loader.exec_module(login)


class LoginWallpaperTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.source = self.root / 'source'
        self.source.mkdir()
        for name in login.NAMES:
            folder = self.source / Path(name).stem
            folder.mkdir()
            (folder / 'wallpaper.jpeg').write_bytes(name.encode())
        self.primary = self.root / 'etc/plasmalogin.conf'
        self.primary.parent.mkdir()
        self.primary.write_text('[Autologin]\nUser=example\n[Greeter][Wallpaper][org.kde.image][General]\nImage=/custom.png\n')
        self.original = self.primary.read_bytes()

    def test_install_reinstall_switch_and_uninstall_preserve_existing_config(self):
        login.install('dark', self.root, self.source)
        config = self.root / login.CONFIG
        self.assertIn('WallpaperPluginId=org.kde.image', config.read_text())
        self.assertIn('/dark.jpeg', config.read_text())
        stamp = config.stat().st_mtime_ns
        login.install('dark', self.root, self.source)
        self.assertEqual(stamp, config.stat().st_mtime_ns)
        login.install('light', self.root, self.source)
        self.assertIn('/light.jpeg', config.read_text())
        self.assertEqual(self.primary.read_bytes(), self.original)
        for path in login.managed_files(self.root):
            self.assertEqual(path.stat().st_mode & 0o777, 0o644)
        login.remove(self.root)
        login.remove(self.root)
        self.assertFalse(config.exists())
        self.assertFalse((self.root / login.ASSETS).exists())
        self.assertEqual(self.primary.read_bytes(), self.original)

    def test_user_edits_are_neither_overwritten_nor_deleted(self):
        login.install('dark', self.root, self.source)
        config = self.root / login.CONFIG
        config.write_text('user override')
        for action in (lambda: login.install('light', self.root, self.source), lambda: login.remove(self.root)):
            with self.assertRaises(RuntimeError):
                action()
        self.assertEqual(config.read_text(), 'user override')

    def test_real_release_wallpapers_are_available(self):
        login.install('dark', self.root)
        for name in login.NAMES:
            expected = login.ROOT / 'wallpapers' / Path(name).stem / 'wallpaper.jpeg'
            self.assertEqual((self.root / login.ASSETS / name).read_bytes(), expected.read_bytes())

    def test_unmanaged_collision_is_preserved(self):
        config = self.root / login.CONFIG
        config.parent.mkdir(parents=True)
        config.write_text('existing unrelated settings')
        with self.assertRaises(RuntimeError):
            login.install('dark', self.root, self.source)
        self.assertEqual(config.read_text(), 'existing unrelated settings')

    def test_failed_update_restores_all_owned_bytes(self):
        login.install('dark', self.root, self.source)
        paths = [*login.managed_files(self.root), self.root / login.ASSETS / 'ownership.json']
        before = {p: p.read_bytes() for p in paths}
        write = login.atomic_write
        failed = False
        def fail_once(path, data):
            nonlocal failed
            if path.name == 'ownership.json' and not failed:
                failed = True
                raise OSError('simulated disk error')
            write(path, data)
        with patch.object(login, 'atomic_write', side_effect=fail_once):
            with self.assertRaises(OSError):
                login.install('light', self.root, self.source)
        self.assertEqual(before, {p: p.read_bytes() for p in paths})
        self.assertTrue(login.check_owned(self.root))

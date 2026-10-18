import importlib.util
from pathlib import Path
import re
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location('widget_prepare', ROOT / 'widgets/prepare.py')
builder = importlib.util.module_from_spec(spec)
spec.loader.exec_module(builder)


class WidgetSurfaceTests(unittest.TestCase):
    def test_each_widget_uses_shared_surface_and_palette(self):
        for package in (ROOT / 'widgets/packages').iterdir():
            qml = '\n'.join(p.read_text() for p in package.rglob('*.qml'))
            # The photo is its own card; the large clock's card is optional.
            if package.name != 'photo':
                self.assertIn('Glassy.GlassySurface {', qml, package.name)
            self.assertIn('Glassy.WidgetColors {}', qml, package.name)
        surface = (ROOT / 'widgets/shared/GlassySurface.qml').read_text()
        self.assertIn('Kirigami.Theme.backgroundColor', surface)
        self.assertIn('Kirigami.Theme.textColor', surface)
        for forbidden in ('ShaderEffect', 'MultiEffect', 'highlightColor', 'opacity:', '#'):
            self.assertNotIn(forbidden, surface)

    def test_standalone_packages_have_local_shared_imports(self):
        with tempfile.TemporaryDirectory() as td:
            for package in (ROOT / 'widgets/packages').iterdir():
                staged = builder.prepare(package, Path(td) / package.name)
                source = ROOT / 'widgets/shared'
                for shared in (f for f in source.rglob('*') if f.is_file()):
                    self.assertEqual(shared.read_bytes(), (staged / 'contents/ui/glassy' / shared.relative_to(source)).read_bytes())
                for qml in staged.rglob('*.qml'):
                    for relative in re.findall(r'import "([^"]+)" as Glassy', qml.read_text()):
                        target = (qml.parent / relative).resolve()
                        self.assertTrue(target.is_relative_to(staged))
                        self.assertTrue((target / 'GlassySurface.qml').is_file())
                with self.assertRaises(FileExistsError):
                    builder.prepare(package, staged)

    def test_no_double_photo_background_or_media_gradient(self):
        photo = (ROOT / 'widgets/packages/photo/contents/ui/main.qml').read_text()
        self.assertNotIn('color: nColors.background', photo)
        self.assertIn('maskEnabled: true', photo)
        media = (ROOT / 'widgets/packages/media/contents/ui/main.qml').read_text()
        self.assertNotIn('GradientStop', media)
        # The empty cover is a faint wash over the card, not an opaque square.
        self.assertIn('color: nColors.alpha(nColors.textPrimary, 0.06)', media)
        self.assertIn('visible: cover.status === Image.Ready', media)

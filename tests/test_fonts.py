from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

from fontTools.ttLib import TTFont

ROOT = Path(__file__).resolve().parents[1]
FACES = ROOT / 'widgets/packages/clock-digital-large/contents/fonts'


class FontTests(unittest.TestCase):
    def test_bundled_fonts_are_free_to_share(self):
        # Every font ships under the SIL OFL or Apache 2.0 (NType 82's own terms did not).
        # Tracked and not yet added files alike, as they stand in the working tree.
        listed = subprocess.run(['git', 'ls-files', '--cached', '--others', '--exclude-standard', '*.ttf', '*.otf'],
                                cwd=ROOT, capture_output=True, text=True, check=True).stdout.split()
        fonts = [path for path in listed if (ROOT / path).exists()]
        self.assertTrue(fonts)
        for path in fonts:
            name = TTFont(ROOT / path)['name']
            license = name.getDebugName(13) or ''
            # Material Symbols carries no license string; its Apache text sits beside it.
            apache_beside = (ROOT / path).with_name('Apache-2.0.txt').exists()
            self.assertTrue('Open Font License' in license or 'Apache' in license or apache_beside, path)

    def test_clock_faces_match_their_builder(self):
        with tempfile.TemporaryDirectory() as out:
            subprocess.run([sys.executable, str(ROOT / 'assets/fonts/build-clockfaces.py'), out], check=True, capture_output=True)
            for face in ('NothingDotted', 'NothingTiles', 'NothingStencil'):
                self.assertEqual((Path(out) / f'{face}.ttf').read_bytes(), (FACES / f'{face}.ttf').read_bytes(), face)
                font = TTFont(FACES / f'{face}.ttf')
                # The large clock sizes its text by these metrics, as with the faces they replaced.
                self.assertEqual((font['hhea'].ascent, font['hhea'].descent, font['head'].unitsPerEm), (800, -200, 1000))
        self.assertTrue((FACES / 'NothingClockFaces-OFL.txt').exists())


if __name__ == '__main__':
    unittest.main()

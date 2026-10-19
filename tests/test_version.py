import json
from pathlib import Path
import re
import subprocess
import unittest

ROOT = Path(__file__).resolve().parents[1]
VERSION = (ROOT / 'VERSION').read_text().strip()


class VersionTests(unittest.TestCase):
    def test_one_version_everywhere(self):
        self.assertRegex(VERSION, r'^\d+\.\d+\.\d+(-rc\d+)?$')
        listed = subprocess.run(['git', 'ls-files', '*metadata.json'], cwd=ROOT, capture_output=True, text=True, check=True).stdout.split()
        for path in listed:
            if 'upstream-cache' in path: continue
            data = json.loads((ROOT / path).read_text())
            version = data.get('KPlugin', {}).get('Version')
            # Glassy's window decoration is versioned on its own.
            if data['KPlugin'].get('Id') == 'org.glassy.decoration': continue
            self.assertEqual(version, VERSION, path)

    def test_changelog_names_the_version(self):
        changelog = (ROOT / 'CHANGELOG.md').read_text()
        released = re.findall(r'^## \[?(\d+\.\d+\.\d+(?:-rc\d+)?)\]?', changelog, re.M)
        # The newest heading is either Unreleased or this version.
        self.assertTrue(changelog.count('## [Unreleased]') == 1 or (released and released[0] == VERSION))


if __name__ == '__main__':
    unittest.main()

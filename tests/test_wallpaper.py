import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]


@unittest.skipUnless(shutil.which('node'), 'Node is needed to exercise Plasma desktop script')
class WallpaperTests(unittest.TestCase):
    def test_restart_hotplug_theme_switch_and_user_overrides(self):
        with tempfile.TemporaryDirectory(prefix='nothing-wallpaper-') as td:
            base = Path(td)
            walls = base / 'data/nothing-plasma/wallpapers'
            walls.mkdir(parents=True)
            for mode in ('dark', 'light'):
                (walls / (mode + '.jpeg')).write_bytes(b'fixture')
            bin_dir = base / 'bin'
            bin_dir.mkdir()
            mock = bin_dir / 'qdbus6'
            mock.write_text('#!/bin/sh\nprintf "%s" "$4" > "$NOTHING_SCRIPT"\n')
            mock.chmod(0o755)
            env = dict(os.environ, XDG_DATA_HOME=str(base / 'data'),
                       PATH=str(bin_dir) + os.pathsep + os.environ['PATH'], NOTHING_SCRIPT=str(base / 'script.js'))
            scripts = {}
            for mode in ('dark', 'light'):
                result = subprocess.run(['bash', str(ROOT / 'runtime/nothing-control.sh'), 'wallpaper', mode],
                                        env=env, capture_output=True, text=True)
                self.assertEqual(result.returncode, 0, result.stderr)
                scripts[mode] = (base / 'script.js').read_text()
            fixture = '''
const vm = require('node:vm');
const assert = require('node:assert/strict');
const {scripts, dark, light} = JSON.parse(process.argv[1]);
function desktop(image, plugin='org.kde.image') {
    return {wallpaperPlugin:plugin, image, writes:0, reloads:0,
        readConfig(key) { return this.image; },
        writeConfig(key,value) { if (key==='Image') this.image=value; ++this.writes; },
        reloadConfig() { ++this.reloads; }};
}
let list = [desktop('file:///usr/share/wallpapers/Next/contents/images/1920x1080.png'),
    desktop('file:///home/user/My%20photo.png'), desktop('custom', 'org.kde.slideshow'), desktop(dark)];
const context = {desktops: () => list};
vm.runInNewContext(scripts.dark, context);
assert.equal(list[0].image,dark);
assert.equal(list[1].image,'file:///home/user/My%20photo.png');
assert.equal(list[1].writes,0); assert.equal(list[2].writes,0); assert.equal(list[3].writes,0);
vm.runInNewContext(scripts.dark, context);
assert.equal(list[0].reloads,1); // retries are idempotent
list.push(desktop('')); // newly created monitor desktop
vm.runInNewContext(scripts.light, context);
assert.equal(list[0].image,light); assert.equal(list[3].image,light); assert.equal(list[4].image,light);
list[0].image='file:///home/user/new-custom.jpg'; // override a previously managed screen
vm.runInNewContext(scripts.dark, context);
assert.equal(list[0].image,'file:///home/user/new-custom.jpg');
assert.equal(list[1].writes,0); assert.equal(list[2].wallpaperPlugin,'org.kde.slideshow');
'''
            result = subprocess.run(['node', '-e', fixture, json.dumps({'scripts': scripts,
                'dark': (walls / 'dark.jpeg').as_uri(), 'light': (walls / 'light.jpeg').as_uri()})],
                capture_output=True, text=True)
            self.assertEqual(result.returncode, 0, result.stderr)

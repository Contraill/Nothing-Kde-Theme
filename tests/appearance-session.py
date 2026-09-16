#!/usr/bin/env python3
"""Bounded KWin test action on one explicitly supplied test-process PID."""
import argparse
from pathlib import Path
import subprocess
import tempfile
import time

parser = argparse.ArgumentParser()
parser.add_argument('pid', type=int)
parser.add_argument('action', choices=('activate', 'inactive', 'maximize', 'restore', 'tile', 'tile-right', 'resize', 'close'))
parser.add_argument('--capture', type=Path)
args = parser.parse_args()
actions = {'activate': '', 'inactive': 'workspace.activeWindow = null;', 'maximize': 'w.setMaximize(true, true);',
           'restore': 'w.setMaximize(false, false); w.tile = null; w.frameGeometry = {x:220,y:140,width:960,height:680};',
           'tile': 'workspace.slotWindowQuickTileLeft();',
           'tile-right': 'workspace.slotWindowQuickTileRight();',
           'resize': 'w.frameGeometry = {x:240,y:160,width:840,height:600};',
           'close': 'w.closeWindow();'}
code = 'for (const w of workspace.windowList()) { if (w.pid === ' + str(args.pid) + ') { workspace.activeWindow = w; ' + actions[args.action] + ' break; } }'
def dbus(*tail):
    return subprocess.run(['qdbus6', 'org.kde.KWin', *tail], check=True, capture_output=True, text=True).stdout.strip()
with tempfile.TemporaryDirectory(prefix='nothing-appearance-action-') as directory:
    source = Path(directory) / 'action.js'; source.write_text(code)
    name = 'nothing-appearance-action-' + str(args.pid)
    script_id = dbus('/Scripting', 'org.kde.kwin.Scripting.loadScript', str(source), name)
    try:
        dbus('/Scripting/Script' + script_id, 'org.kde.kwin.Script.run')
        time.sleep(1)
        if args.capture:
            subprocess.run(['spectacle', '-b', '-n', '-f' if args.action == 'inactive' else '-a', '-o', str(args.capture)], check=True)
    finally:
        dbus('/Scripting', 'org.kde.kwin.Scripting.unloadScript', name)

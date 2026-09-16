#!/usr/bin/env python3
"""Uninstall-only recovery for the retired native-file overlay. Never install it."""
import os
from pathlib import Path
import shutil

DATA = Path(os.environ.get('XDG_DATA_HOME', Path.home() / '.local/share'))
DST = DATA / 'plasma/plasmoids/org.kde.plasma.notifications'
BACKUP = DATA / 'nothing-plasma/backups/org.kde.plasma.notifications.pre-nothing'
MARKER = '.nothing-plasma-notification-overlay'


def restore():
    if DST.is_symlink() or not (DST / MARKER).is_file(): return
    shutil.rmtree(DST)
    if BACKUP.exists(): BACKUP.rename(DST)
    print('Removed retired Nothing overlay; restored the previous native applet override if present.')


if __name__ == '__main__': restore()

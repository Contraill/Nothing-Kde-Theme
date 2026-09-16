#!/usr/bin/env python3
"""Reversible Kitty automatic OS theme integration; never edits kitty.conf."""
import argparse
import base64
import configparser
import fcntl
import hashlib
import json
import os
from pathlib import Path
import shutil
import signal
import subprocess
import sys

sys.dont_write_bytecode = True
from appearance import atomic

CONFIG = Path(os.environ.get('XDG_CONFIG_HOME', Path.home() / '.config'))
DATA = Path(os.environ.get('XDG_DATA_HOME', Path.home() / '.local/share'))
KITTY = Path(os.environ.get('KITTY_CONFIG_DIRECTORY', CONFIG / 'kitty'))
STATE = CONFIG / 'nothing-kde/kitty-theme/state.json'
FILES = ('light-theme.auto.conf', 'dark-theme.auto.conf', 'no-preference-theme.auto.conf')


def digest(data):
    return hashlib.sha256(data).hexdigest()


def user_colors():
    # Kitty resolves includes, env expansion and special color values itself.
    # Preserve effective user color/image directives: auto themes reset omitted
    # colors/images to defaults. No opacity, fonts, shortcuts or remote control.
    code = '''
import json, os
from kitty.config import load_config, effective_config_lines
from kitty.constants import config_dir
from kitty.options.types import all_colors
from kitty.colors import BackgroundImageOptions, ThemeFile
load_config(os.path.join(config_dir, 'kitty.conf'))
keys = all_colors | BackgroundImageOptions.__optional_keys__ | {'transparent_background_colors'}
print(json.dumps([line for line in effective_config_lines if line.split()[0] in keys]))
'''
    env = dict(os.environ, KITTY_CONFIG_DIRECTORY=str(KITTY))
    result = subprocess.run(['kitty', '+runpy', code], env=env, text=True,
                            capture_output=True, check=True, timeout=15)
    return json.loads(result.stdout)


def scheme(mode):
    name = 'NothingPlasma' + mode.title() + '.colors'
    dirs = [DATA, *(Path(p) for p in os.environ.get('XDG_DATA_DIRS', '/usr/local/share:/usr/share').split(':'))]
    path = next((d / 'color-schemes' / name for d in dirs if (d / 'color-schemes' / name).is_file()), None)
    if path is None: raise ValueError(f'Missing KDE color scheme: {name}')
    c = configparser.ConfigParser(interpolation=None)
    c.read(path)
    def color(group, key):
        value = c[group][key]
        parts = [int(v) for v in value.split(',')]
        if len(parts) != 3 or any(v < 0 or v > 255 for v in parts): raise ValueError(value)
        return '#' + ''.join(f'{v:02x}' for v in parts)
    return { 'background': color('Colors:Window', 'BackgroundNormal'),
             'foreground': color('Colors:Window', 'ForegroundNormal'),
             'selection_background': color('Colors:Selection', 'BackgroundNormal'),
             'selection_foreground': color('Colors:Selection', 'ForegroundNormal') }


def render(lines, colors):
    roles = dict(colors)
    roles.update(cursor=colors['foreground'], cursor_text_color=colors['background'],
                 active_tab_background=colors['background'], inactive_tab_background=colors['background'],
                 tab_bar_background=colors['background'], tab_bar_margin_color=colors['background'],
                 active_tab_foreground=colors['foreground'], inactive_tab_foreground=colors['foreground'])
    return ('# Managed by Nothing KDE: official Kitty automatic OS color themes.\n'
            + '\n'.join(lines) + '\n' + '\n'.join(f'{k} {v}' for k, v in roles.items()) + '\n').encode()


def reload_running():
    for proc in Path('/proc').glob('[0-9]*'):
        try:
            if proc.stat().st_uid != os.getuid() or (proc / 'exe').resolve().name != 'kitty': continue
            args = (proc / 'cmdline').read_bytes().split(b'\0')
            if any(a in (b'--config', b'-c', b'+runpy') or a.startswith(b'--config=') for a in args): continue
            env = dict(v.split(b'=', 1) for v in (proc / 'environ').read_bytes().split(b'\0') if b'=' in v)
            config = Path(os.fsdecode(env.get(b'KITTY_CONFIG_DIRECTORY', env.get(b'XDG_CONFIG_HOME', os.fsencode(Path.home() / '.config')) + b'/kitty')))
            if config.resolve() == KITTY.resolve(): os.kill(int(proc.name), signal.SIGUSR1)
        except (OSError, ValueError):
            continue


def update(state):
    lines = user_colors()
    files = state.setdefault('files', {})
    output = {name: render(lines, scheme('dark' if name.startswith('dark') else 'light')) for name in FILES}
    # Preflight every path before writing, and journal recovery before mutation.
    for name in FILES:
        path = KITTY / name
        if path.is_symlink(): raise ValueError(f'Refusing symlink: {path}')
        current = path.read_bytes() if path.exists() else None
        item = files.get(name)
        current_hash = None if current is None else digest(current)
        if item and current_hash not in {item['after'], item.get('pending', item['after'])}:
            raise ValueError(f'User-modified automatic theme preserved: {path}')
        if not item:
            files[name] = {'before': None if current is None else base64.b64encode(current).decode(),
                           'after': current_hash}
        files[name]['pending'] = digest(output[name])
    state['enabled'] = True
    atomic(STATE, json.dumps(state, indent=2))
    changed = False
    for name, content in output.items(): changed = atomic(KITTY / name, content) or changed
    for item in files.values(): item['after'] = item.pop('pending')
    atomic(STATE, json.dumps(state, indent=2))
    if changed: reload_running()


def disable(state):
    remaining = {}
    for name, item in state.get('files', {}).items():
        path = KITTY / name
        current_hash = digest(path.read_bytes()) if path.exists() and not path.is_symlink() else None
        if path.is_symlink() or current_hash not in {item['after'], item.get('pending', item['after'])}:
            remaining[name] = item
            print(f'User-modified file preserved: {path}', file=sys.stderr)
            continue
        if item['before'] is None:
            path.unlink(missing_ok=True)
        else:
            atomic(path, base64.b64decode(item['before']))
    state.update(enabled=False, files=remaining)
    atomic(STATE, json.dumps(state, indent=2))
    reload_running()


def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('action', choices=('install', 'sync', 'disable', 'status'))
    args = p.parse_args()
    STATE.parent.mkdir(parents=True, exist_ok=True)
    with (STATE.parent / '.lock').open('w') as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)
        state = json.loads(STATE.read_text()) if STATE.exists() else {}
        if args.action == 'status': print(json.dumps(state)); return
        if args.action == 'disable': disable(state); return
        if args.action == 'sync' and not state.get('enabled'): return
        if not shutil.which('kitty'): return
        update(state)


if __name__ == '__main__':
    try: main()
    except (OSError, ValueError, subprocess.SubprocessError) as e:
        print(f'Kitty theme: {e}', file=sys.stderr)
        sys.exit(1)

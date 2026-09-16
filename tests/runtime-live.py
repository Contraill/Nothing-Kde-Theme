#!/usr/bin/env python3
"""Opt-in real desktop runtime check. Restores scheme/accent; never restarts apps.

Launches ONLY owned test windows, observes those same PIDs for all three phases.
Requires the prebuilt read-only Glassy observer. Does not logout or reboot.
"""
import argparse
import hashlib
import json
import os
from pathlib import Path
import signal
import subprocess
import time

ROOT = Path(__file__).resolve().parents[1]
HELPER = ROOT / 'runtime/nothing-control.sh'


def run(*args):
    return subprocess.run(args, check=True, text=True, capture_output=True, timeout=45).stdout.strip()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output', type=Path, required=True)
    parser.add_argument('--observer', type=Path, required=True)
    parser.add_argument('--skip-open-settings', action='store_true', help='Leave an existing user System Settings process untouched')
    args = parser.parse_args()
    args.output.mkdir(exist_ok=False)
    old_scheme = run('kreadconfig6', '--file', 'kdeglobals', '--group', 'General', '--key', 'ColorScheme')
    if old_scheme not in ('NothingPlasmaLight', 'NothingPlasmaDark'): raise RuntimeError('Requires an active Nothing scheme')
    settings_open = subprocess.run(['pgrep', '-x', 'systemsettings'], capture_output=True).returncode == 0
    if settings_open and not args.skip_open_settings:
        raise RuntimeError('Close System Settings yourself before this opt-in test')
    old_accent = run('bash', str(HELPER), 'accent', 'get')
    conf = Path.home() / '.config/kitty/kitty.conf'
    before = hashlib.sha256(conf.read_bytes()).hexdigest()
    children = []; owned = {}; results = {'apps': {}, 'accent': []}
    try:
        run('bash', str(HELPER), 'accent', '806ee7')
        run('systemctl', '--user', 'restart', 'plasma-plasmashell.service')
        time.sleep(5)
        run('bash', str(HELPER), 'accent', 'init')
        results['afterPanelReload'] = run('bash', str(HELPER), 'accent', 'get')
        assert results['afterPanelReload'] == '#806EE7'
        run('bash', str(HELPER), 'theme', 'light', '0')
        socket = 'unix:' + str(args.output.resolve() / 'kitty.sock')
        commands = {'dolphin': ['dolphin', '--new-window', str(ROOT)],
                    'kate': ['kate', '--startanon', str(ROOT/'README.md')],
                    'systemsettings': ['systemsettings', 'kcm_colors'],
                    'kitty': ['kitty', '--listen-on', socket, '-o', 'allow_remote_control=socket-only',
                              '--title', 'Nothing runtime test', '/usr/bin/sleep', '180']}
        if settings_open:
            del commands['systemsettings']
            results['skipped'] = ['System Settings already open: user process retained']
        for name, command in commands.items():
            prefix = args.output.resolve() / name
            prefix.with_suffix('.phase').write_text('0')
            env = dict(os.environ)
            if name != 'kitty': env.update(LD_PRELOAD=str(args.observer.resolve()), GLASSY_LIVE_CAPTURE=str(prefix))
            with prefix.with_suffix('.log').open('w') as log:
                child = subprocess.Popen(command, env=env, stdout=log, stderr=log, start_new_session=True)
            children.append(child)
            results['apps'][name] = {'launchPid': child.pid, 'phases': []}
        time.sleep(5)
        for phase, mode in enumerate(('light', 'dark', 'light')):
            run('bash', str(HELPER), 'theme', mode, '0')
            run('bash', str(HELPER), 'accent', 'init')
            accent = run('bash', str(HELPER), 'accent', 'get')
            assert accent == '#806EE7', accent
            results['accent'].append(accent)
            for name in commands: (args.output/name).with_suffix('.phase').write_text(str(phase))
            time.sleep(4)
            for name in ('dolphin', 'kate', 'systemsettings'):
                if name not in commands: continue
                data = json.loads((args.output / f'{name}-{phase}.json').read_text())
                marker = ('GLASSY_LIVE_CAPTURE=' + str(args.output.resolve()/name)).encode()
                assert marker in Path(f'/proc/{data["pid"]}/environ').read_bytes().split(b'\0')
                owned[data['pid']] = marker
                phases = results['apps'][name]['phases']
                if phases: assert (data['pid'],data['styleAddress']) == (phases[0]['pid'],phases[0]['styleAddress'])
                phases.append(data)
            colors = dict(line.split() for line in run('kitten', '@', '--to', socket, 'get-colors').splitlines())
            expected = '#f6f6f3' if mode == 'light' else '#090909'
            assert colors['background'] == expected, colors['background']
            results['apps']['kitty']['phases'].append({'mode':mode, 'colors':colors, 'pid':children[-1].pid})
            assert children[-1].poll() is None
            run('python3', str(ROOT/'tests/appearance-session.py'), str(children[-1].pid), 'activate',
                '--capture', str(args.output/f'kitty-{phase}.png'))
            print(mode, accent, 'Kitty', colors['background'], flush=True)
        results['kittyConfUnchanged'] = before == hashlib.sha256(conf.read_bytes()).hexdigest()
        assert results['kittyConfUnchanged']
    finally:
        for pid, marker in owned.items():
            try:
                if marker in Path(f'/proc/{pid}/environ').read_bytes().split(b'\0'): os.kill(pid, signal.SIGTERM)
            except (FileNotFoundError, ProcessLookupError): pass
        for child in children:
            if child.poll() is None: os.killpg(child.pid, signal.SIGTERM)
            try: child.wait(timeout=5)
            except subprocess.TimeoutExpired: os.killpg(child.pid, signal.SIGKILL); child.wait()
        run('bash', str(HELPER), 'accent', old_accent.lstrip('#'))
        run('bash', str(HELPER), 'theme', 'dark' if old_scheme.endswith('Dark') else 'light', '0')
        (args.output/'results.json').write_text(json.dumps(results, indent=2))


if __name__ == '__main__': main()

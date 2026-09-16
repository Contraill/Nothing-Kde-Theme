#!/usr/bin/env python3
"""On-demand kernel device privacy controls; no resident process.

camera: USB Video interfaces only, never whole USB composite devices.
microphone: local ALSA capture character devices, not output devices.
Mutations require pkexec and a normal desktop caller; status is unprivileged.
"""
import fcntl
import grp
import json
import os
from pathlib import Path
import pwd
import re
import shutil
import stat
import subprocess
import sys

USB = Path('/sys/bus/usb/devices')
PROBE = Path('/sys/bus/usb/drivers_probe')
SOUND = Path('/dev/snd')
RULE = Path('/etc/udev/rules.d/71-nothing-plasma-microphone.rules')
STATE = Path('/var/lib/nothing-plasma-privacy')
RULE_TEXT = '# Nothing KDE local ALSA capture privacy\nSUBSYSTEM=="sound", KERNEL=="pcmC*D*c", TAG-="uaccess", MODE:="0000"\n'
ENV = dict(os.environ, LC_ALL='C')


def run(args, *, input=None, check=True):
    p = subprocess.run(args, input=input, text=True, capture_output=True,
                       timeout=35, env=ENV, check=False)
    if check and p.returncode:
        raise RuntimeError('command-failed')
    return p


def cameras():
    result = []
    for p in sorted(USB.glob('*:*')):
        if not re.fullmatch(r'\d+-[\d.]+:\d+\.\d+', p.name):
            continue
        try:
            if (p / 'bInterfaceClass').read_text().strip().lower() == '0e':
                result.append(p)
        except OSError:
            continue
    return result


def capture_nodes():
    return [p for p in sorted(SOUND.glob('pcmC*D*c'))
            if re.fullmatch(r'pcmC\d+D\d+c', p.name) and stat.S_ISCHR(p.stat().st_mode)]


def own_rule():
    return RULE.is_file() and not RULE.is_symlink() and RULE.read_text() == RULE_TEXT


def extra_sources():
    """Bluetooth/virtual/network capture is outside the ALSA gate's guarantee."""
    try:
        sources = json.loads(run(['pactl', '--format=json', 'list', 'sources']).stdout)
        return [s['name'] for s in sources
                if not s.get('monitor_of_sink_name') and not s['name'].endswith('.monitor')
                and not s['name'].startswith('alsa_input.')]
    except (OSError, RuntimeError, ValueError):
        return None


def status():
    cam = cameras()
    authorized = [(p / 'authorized').read_text().strip() == '1' for p in cam]
    nodes = capture_nodes()
    extras = extra_sources()
    denied = bool(nodes) and all(stat.S_IMODE(p.stat().st_mode) == 0 for p in nodes)
    profiles = []
    profile = ''
    try:
        listing = run(['powerprofilesctl', 'list']).stdout
        profiles = re.findall(r'^\s*\*?\s*(power-saver|balanced|performance):\s*$', listing, re.M)
        profile = run(['powerprofilesctl', 'get']).stdout.strip()
    except (OSError, RuntimeError):
        pass
    mic_tools = all(shutil.which(tool) for tool in ('pkexec', 'pactl', 'getfacl', 'setfacl', 'udevadm', 'runuser', 'systemctl'))
    legacy_capture = Path('/dev/dsp').exists() or Path('/dev/audio').exists()
    return {'cameraAvailable': bool(cam) and bool(shutil.which('pkexec')), 'cameraBlocked': bool(cam) and not any(authorized),
            'cameraMixed': bool(cam) and any(authorized) and not all(authorized),
            'microphoneAvailable': bool(nodes) and extras == [] and mic_tools and not legacy_capture,
            'microphoneBlocked': own_rule() and denied and extras == [] and not legacy_capture,
            'microphonePartial': own_rule() and (not denied or extras != [] or legacy_capture),
            'profiles': profiles, 'profile': profile}


def set_camera(enabled):
    interfaces = cameras()
    if not interfaces:
        raise RuntimeError('unavailable')
    previous = {p: (p / 'authorized').read_text().strip() for p in interfaces}
    try:
        for p in interfaces:
            (p / 'authorized').write_text('1' if enabled else '0')
        # Authorize every interface before probing multi-interface cameras.
        if enabled:
            for p in interfaces:
                PROBE.write_text(p.name)
        if any((p / 'authorized').read_text().strip() != ('1' if enabled else '0') for p in interfaces):
            raise RuntimeError('verify-failed')
    except Exception:
        for p, value in previous.items():
            try:
                (p / 'authorized').write_text(value)
            except OSError:
                pass
        for p, value in previous.items():
            if value == '1':
                try:
                    PROBE.write_text(p.name)
                except OSError:
                    pass
        raise


def desktop_caller():
    raw = os.environ.get('PKEXEC_UID', '')
    if not raw.isdigit() or int(raw) < 1000:
        raise RuntimeError('desktop-caller-required')
    return pwd.getpwuid(int(raw))


def user_command(caller, command):
    return ['/usr/bin/runuser', '-u', caller.pw_name, '--', '/usr/bin/env',
            'XDG_RUNTIME_DIR=/run/user/' + str(caller.pw_uid),
            'DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/' + str(caller.pw_uid) + '/bus'] + command


def restart_audio(caller):
    # Existing capture FDs in PipeWire must be released; never kill user apps.
    run(user_command(caller, ['/usr/bin/systemctl', '--user', 'restart',
                             'pipewire.service', 'pipewire-pulse.service', 'wireplumber.service']))


def capture_busy(nodes):
    devices = {p.stat().st_rdev for p in nodes}
    for proc in Path('/proc').glob('[0-9]*/fd'):
        try:
            for fd in proc.iterdir():
                try:
                    info = fd.stat()
                    if stat.S_ISCHR(info.st_mode) and info.st_rdev in devices:
                        return True
                except OSError:
                    continue
        except OSError:
            continue
    return False


def reload_capture_rules():
    run(['/usr/bin/udevadm', 'control', '--reload-rules'])
    run(['/usr/bin/udevadm', 'trigger', '--action=change', '--subsystem-match=sound', '--sysname-match=pcmC*D*c'])
    run(['/usr/bin/udevadm', 'settle', '--timeout=10'])


def prepare_state():
    if STATE.is_symlink():
        raise RuntimeError('unsafe-state')
    STATE.mkdir(mode=0o700, exist_ok=True)
    s = STATE.stat()
    if s.st_uid != 0 or stat.S_IMODE(s.st_mode) != 0o700:
        raise RuntimeError('unsafe-state')


def restore_microphones(snapshot):
    if own_rule():
        RULE.unlink()
    elif RULE.exists():
        raise RuntimeError('foreign-rule')
    by_name = {p['name']: p for p in snapshot}
    for node in capture_nodes():
        previous = by_name.get(node.name)
        if previous and previous['device'] == node.stat().st_rdev:
            run(['/usr/bin/setfacl', '--restore=-'], input=previous['acl'])
        else:
            # Capture devices connected while blocked receive normal ALSA
            # ownership first; udev/logind then restore seat-specific access.
            os.chown(node, 0, grp.getgrnam('audio').gr_gid)
            os.chmod(node, 0o660)
    reload_capture_rules()


def set_microphone(blocked):
    caller = desktop_caller()
    prepare_state()
    saved = STATE / 'capture-acls.json'
    if RULE.exists() and not own_rule():
        raise RuntimeError('foreign-rule')
    if blocked and own_rule():
        raise RuntimeError('already-blocked')
    if not blocked:
        # A failed audio restart may leave the rule removed but the recovery
        # snapshot intact. Retrying "on" must still finish the recovery.
        if not saved.is_file():
            raise RuntimeError('no-snapshot')
        snapshot = json.loads(saved.read_text())
        restore_microphones(snapshot)
        restart_audio(caller)
        saved.unlink()
        return
    nodes = capture_nodes()
    if saved.exists():
        raise RuntimeError('recovery-required')
    if not nodes:
        raise RuntimeError('unavailable')
    if Path('/dev/dsp').exists() or Path('/dev/audio').exists():
        raise RuntimeError('unsupported-source')
    # Inspect the caller's session, not root's (which has no audio server).
    sources = json.loads(run(user_command(caller, ['/usr/bin/pactl', '--format=json', 'list', 'sources'])).stdout)
    if any(not s.get('monitor_of_sink_name') and not s['name'].endswith('.monitor')
           and not s['name'].startswith('alsa_input.') for s in sources):
        raise RuntimeError('unsupported-source')
    snapshot = [{'name': p.name, 'device': p.stat().st_rdev,
                 'acl': run(['/usr/bin/getfacl', '-p', str(p)]).stdout} for p in nodes]
    saved.write_text(json.dumps(snapshot))
    saved.chmod(0o600)
    try:
        with RULE.open('x') as f:
            f.write(RULE_TEXT)
        RULE.chmod(0o644)  # Unprivileged UI must be able to verify our rule.
        reload_capture_rules()
        for node in capture_nodes():
            run(['/usr/bin/setfacl', '-b', str(node)])
            os.chmod(node, 0)
        restart_audio(caller)
        if capture_busy(capture_nodes()):
            raise RuntimeError('capture-busy')
        if not all(stat.S_IMODE(p.stat().st_mode) == 0 for p in capture_nodes()):
            raise RuntimeError('verify-failed')
    except Exception:
        restore_microphones(snapshot)
        restart_audio(caller)
        saved.unlink(missing_ok=True)
        raise


def main():
    try:
        if sys.argv[1:] == ['status']:
            print(json.dumps(status()))
            return 0
        if os.geteuid() != 0:
            raise RuntimeError('authorization-required')
        if len(sys.argv) != 3 or sys.argv[1] not in ('camera', 'microphone') or sys.argv[2] not in ('on', 'off'):
            raise RuntimeError('invalid-action')
        prepare_state()
        with (STATE / 'operation.lock').open('a') as lock:
            fcntl.flock(lock, fcntl.LOCK_EX)
            if sys.argv[1] == 'camera':
                set_camera(sys.argv[2] == 'on')
            else:
                set_microphone(sys.argv[2] == 'off')
        print(json.dumps({'ok': True}))
        return 0
    except Exception as error:
        print(json.dumps({'ok': False, 'error': str(error) if isinstance(error, RuntimeError) else 'system-error'}))
        return 1


if __name__ == '__main__':
    raise SystemExit(main())

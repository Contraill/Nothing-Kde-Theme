#!/usr/bin/env python3
"""Nothing KDE sound themes: install, select, and import personal recordings.

  sounds.py install            copy the bundled "nothing-kde" theme to ~/.local/share/sounds
                               and select it when no sound theme was chosen
  sounds.py use nothing|personal|default
  sounds.py import DIR         build "nothing-kde-personal" from your own recordings
  sounds.py remove             delete both themes and drop a selection that points at them

Recordings are named after the event they replace (freedesktop names such as
message-new-instant.wav) or one of the short aliases below. They are converted
with ffmpeg into your data directory only; nothing is copied into the project.
Events without a recording fall back to the bundled theme.
"""
import argparse
import os
from pathlib import Path
import shutil
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
DATA = Path(os.environ.get('XDG_DATA_HOME', Path.home() / '.local/share'))
BUNDLED = ROOT / 'assets/sounds/nothing-kde'
THEME, PERSONAL = 'nothing-kde', 'nothing-kde-personal'
FORMATS = ('.wav', '.ogg', '.oga', '.opus', '.mp3', '.m4a', '.aac', '.flac')
# Short names for recordings; each may stand for several events.
ALIASES = {
    'notification': ['message-new-instant', 'dialog-information'], 'bildirim': ['message-new-instant', 'dialog-information'],
    'message': ['message-new-instant'], 'mesaj': ['message-new-instant'],
    'email': ['message-new-email'], 'eposta': ['message-new-email'],
    'alarm': ['alarm-clock-elapsed'], 'timer': ['alarm-clock-elapsed'], 'zamanlayici': ['alarm-clock-elapsed'],
    'ringtone': ['phone-incoming-call'], 'zil': ['phone-incoming-call'],
    'charging': ['power-plug'], 'sarj': ['power-plug'], 'unplug': ['power-unplug'],
    'connect': ['device-added'], 'bagla': ['device-added'], 'disconnect': ['device-removed'],
    'error': ['dialog-error'], 'hata': ['dialog-error'], 'warning': ['dialog-warning'], 'uyari': ['dialog-warning'],
    'startup': ['desktop-login'], 'acilis': ['desktop-login'], 'shutdown': ['desktop-logout'], 'kapanis': ['desktop-logout'],
    'volume': ['audio-volume-change'], 'lowbattery': ['battery-low'], 'success': ['completion-success'], 'trash': ['trash-empty'],
}
PERSONAL_INDEX = '''[Sound Theme]
Name=Nothing KDE (personal)
Name[tr]=Nothing KDE (kişisel)
Comment=Your own recordings over the Nothing KDE theme
Comment[tr]=Kendi kayıtların, Nothing KDE temasının üstünde
Inherits=nothing-kde,freedesktop
Directories=stereo

[stereo]
OutputProfile=stereo
'''


def kde(*args):
    return subprocess.run(args, capture_output=True, text=True, check=False)


def selected():
    return kde('kreadconfig6', '--file', 'kdeglobals', '--group', 'Sounds', '--key', 'Theme').stdout.strip()


def select(theme):
    """Writes the System Sounds choice with --notify, as the KDE settings page does."""
    if theme:
        kde('kwriteconfig6', '--notify', '--file', 'kdeglobals', '--group', 'Sounds', '--key', 'Theme', theme)
    else:
        kde('kwriteconfig6', '--notify', '--file', 'kdeglobals', '--group', 'Sounds', '--key', 'Theme', '--delete')


def install():
    target = DATA / 'sounds' / THEME
    staging = target.with_name(THEME + '.new')
    shutil.rmtree(staging, ignore_errors=True)
    shutil.copytree(BUNDLED, staging)
    shutil.rmtree(target, ignore_errors=True)
    staging.rename(target)
    # Only take over the default; a theme the user picked stays.
    if not selected():
        select(THEME)


def targets(stem):
    stem = stem.lower()
    if stem in ALIASES:
        return ALIASES[stem]
    events = {p.stem for p in BUNDLED.glob('stereo/*.oga')}
    return [stem] if stem in events else []


def import_recordings(directory):
    if not shutil.which('ffmpeg'):
        raise SystemExit('ffmpeg is required to convert recordings')
    files = sorted(p for p in Path(directory).expanduser().iterdir() if p.suffix.lower() in FORMATS)
    # Aliases first, so a recording named after the exact event wins.
    ordered = sorted(files, key=lambda p: p.stem.lower() not in ALIASES)
    plan = {event: source for source in ordered for event in targets(source.stem)}
    unknown = [p.name for p in files if not targets(p.stem)]
    if not plan:
        raise SystemExit('No recordings named after a sound event or alias in ' + str(directory))
    theme = DATA / 'sounds' / PERSONAL
    (theme / 'stereo').mkdir(parents=True, exist_ok=True)
    (theme / 'index.theme').write_text(PERSONAL_INDEX)
    for event, source in sorted(plan.items()):
        # Trim silence at the start so the sound answers immediately.
        subprocess.run(['ffmpeg', '-loglevel', 'error', '-y', '-i', str(source), '-af',
                        'silenceremove=start_periods=1:start_threshold=-50dB,loudnorm=I=-18:TP=-3',
                        '-ac', '2', '-ar', '48000', '-c:a', 'libvorbis', '-q:a', '5',
                        str(theme / 'stereo' / (event + '.oga'))], check=True)
        print(f'{source.name} -> {event}')
    if unknown:
        print('Skipped (no matching event): ' + ', '.join(unknown), file=sys.stderr)


def remove():
    for name in (THEME, PERSONAL):
        shutil.rmtree(DATA / 'sounds' / name, ignore_errors=True)
    if selected() in (THEME, PERSONAL):
        select(None)


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument('action', choices=('install', 'use', 'import', 'remove', 'status'))
    parser.add_argument('value', nargs='?')
    args = parser.parse_args()
    if args.action == 'install':
        install()
    elif args.action == 'use':
        choice = {'nothing': THEME, 'personal': PERSONAL, 'default': None}.get(args.value, '')
        if choice == '':
            parser.error('use nothing|personal|default')
        if choice and not (DATA / 'sounds' / choice / 'index.theme').is_file():
            raise SystemExit(choice + ' is not installed')
        select(choice)
    elif args.action == 'import':
        if not args.value:
            parser.error('import DIR')
        import_recordings(args.value)
        select(PERSONAL)
    elif args.action == 'remove':
        remove()
    print('System sounds: ' + (selected() or 'default (Ocean)'))


if __name__ == '__main__':
    main()

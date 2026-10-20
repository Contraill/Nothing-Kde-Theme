#!/usr/bin/env python3
"""Nothing KDE application style / native Aurorae installation and ownership."""
import argparse
import fcntl
import glob
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import tempfile
import time
import importlib.util

sys.dont_write_bytecode = True
from appearance_render import render
from glassy_settings import settings as glassy_settings, configure as configure_glassy

CONFIG = Path(os.environ.get('XDG_CONFIG_HOME', Path.home() / '.config'))
DATA = Path(os.environ.get('XDG_DATA_HOME', Path.home() / '.local/share'))
ROOT = Path(__file__).resolve().parents[1]
STATE = CONFIG / 'nothing-kde/appearance/state.json'
KV = CONFIG / 'Kvantum/Glassy'
TEMPLATE = DATA / 'nothing-plasma/appearance/Glassy.kvconfig'
DECO = DATA / 'kwin/decorations/org.glassy.decoration'
TRANSLATION = DATA / 'locale/tr/LC_MESSAGES/glassydecoration.mo'
STYLE = ('kdeglobals', 'KDE', 'widgetStyle')
LIBRARY = ('kwinrc', 'org.kde.kdecoration2', 'library')
THEME = ('kwinrc', 'org.kde.kdecoration2', 'theme')
SCHEME = ('kdeglobals', 'General', 'ColorScheme')
KVTHEME = ('Kvantum/kvantum.kvconfig', 'General', 'theme')
BLUR = ('kwinrc', 'Plugins', 'blurEnabled')
# Kvantum builds its surfaces once per style object, and KDE's platform plugin
# recreates the style only when the style *name* changes. Kvantum's two style
# keys load different files from the same theme folder, so every sync writes the
# inactive slot and flips the name: running applications reload live.
SLOTS = {'kvantum': 'Glassy', 'kvantum-dark': 'GlassyDark'}


def run(*args, check=True):
    return subprocess.run(args, check=check, capture_output=True, text=True, timeout=30)


def read(key):
    return run('kreadconfig6', '--file', str(CONFIG / key[0]), '--group', key[1], '--key', key[2],
               '--default', '__NOTHING_ABSENT__').stdout.strip()


def write(key, value):
    args = ['kwriteconfig6', '--file', str(CONFIG / key[0]), '--group', key[1], '--key', key[2]]
    run(*args, *(['--delete'] if value == '__NOTHING_ABSENT__' else [value]))


def atomic(path, data):
    if isinstance(data, str): data = data.encode()
    if path.is_symlink(): raise ValueError(f'Refusing symlink: {path}')
    if path.exists() and path.read_bytes() == data: return False
    path.parent.mkdir(parents=True, exist_ok=True)
    fd, temporary = tempfile.mkstemp(prefix='.appearance-', dir=path.parent)
    try:
        with os.fdopen(fd, 'wb') as stream: stream.write(data)
        os.chmod(temporary, path.stat().st_mode & 0o777 if path.exists() else 0o644)
        os.replace(temporary, path)
    finally:
        if os.path.exists(temporary): os.unlink(temporary)
    return True


def save(state): atomic(STATE, json.dumps(state, indent=2) + '\n')


def palette():
    roles = {'window': ('Window', 'BackgroundNormal'), 'text': ('Window', 'ForegroundNormal'),
             'base': ('View', 'BackgroundNormal'), 'button': ('Button', 'BackgroundNormal'),
             'highlight': ('Selection', 'BackgroundNormal'), 'highlight_text': ('Selection', 'ForegroundNormal'),
             'alternate': ('View', 'BackgroundAlternate'),
             'inactive_text': ('Window', 'ForegroundInactive')}
    result = {}
    for role, (group, key) in roles.items():
        value = read(('kdeglobals', 'Colors:' + group, key))
        if re.fullmatch(r'\d{1,3},\d{1,3},\d{1,3}', value) and all(int(x) <= 255 for x in value.split(',')):
            result[role] = '#' + ''.join(f'{int(x):02x}' for x in value.split(','))
        elif re.fullmatch(r'#[0-9a-fA-F]{6}', value): result[role] = value.lower()
        else: raise ValueError('KDE palette role unavailable: ' + role)
    return result


def digest(data): return hashlib.sha256(data).hexdigest()


def owned_file(state, path, data):
    """Journal first; reject edits to a previously installed asset."""
    if isinstance(data, str): data = data.encode()
    if path.is_symlink() or any(parent.is_symlink() for parent in path.parents):
        raise ValueError(f'Refusing symlink asset path: {path}')
    name = str(path)
    files = state.setdefault('files', {})
    previous = files.get(name)
    if path.exists():
        actual = digest(path.read_bytes())
        if actual == digest(data): return False
        if not previous or actual != previous['after']:
            raise ValueError(f'User-edited or unrelated asset retained: {path}')
    files[name] = {'after': digest(data)}
    save(state)
    return atomic(path, data)


def set_owned(state, key, value):
    keys = state.setdefault('keys', [])
    item = next((item for item in keys if item['key'] == list(key)), None)
    current = read(key)
    if item:
        if current != item['after']:
            print('Keeping user selection:', '/'.join(key)); return
    else:
        item = {'key': list(key), 'before': current}
        keys.append(item)
    item['after'] = value
    save(state)
    if current != value: write(key, value)
    if read(key) != value:
        raise ValueError('KDE setting could not be applied (possibly locked): ' + '/'.join(key))


def notify(style=False):
    run('dbus-send', '--session', '--type=signal', '/KGlobalSettings',
        'org.kde.KGlobalSettings.notifyChange', 'int32:' + ('2' if style else '0'), 'int32:0', check=False)
    run('qdbus6', 'org.kde.KWin', '/KWin', 'org.kde.KWin.reconfigure', check=False)


def reload_decoration():
    """KWin keeps a decoration's QML in memory while any window uses it, so new
    files load only after every Glassy decoration is gone: switch away and back."""
    if read(LIBRARY) != 'org.kde.kwin.aurorae' or read(THEME) != 'org.glassy.decoration': return
    reconfigure = ('qdbus6', 'org.kde.KWin', '/KWin', 'org.kde.KWin.reconfigure')
    try:
        write(LIBRARY, 'org.kde.breeze')
        run(*reconfigure, check=False)
        time.sleep(4)  # KWin tears decorations down asynchronously.
    finally:
        write(LIBRARY, 'org.kde.kwin.aurorae')
        run(*reconfigure, check=False)


class MissingDependencies(ValueError):
    """Glassy cannot run here yet; the rest of Nothing KDE can (exit status 3)."""


# Without pacman, the plugins themselves show what is installed, whichever
# package manager put them there.
QT6_PLUGINS = ('/usr/lib/qt6/plugins', '/usr/lib64/qt6/plugins', '/usr/lib/*-linux-gnu/qt6/plugins')
QT5_PLUGINS = ('/usr/lib/qt/plugins', '/usr/lib64/qt5/plugins', '/usr/lib/*-linux-gnu/qt5/plugins')


def plugin_present(roots, *names):
    found = [root for pattern in roots for root in glob.glob(pattern)]
    return any(Path(root, name).is_file() for root in found for name in names)


def dependencies(state, qt5=False):
    if not shutil.which('pacman'):
        wanted = {'Kvantum for Qt 6': plugin_present(QT6_PLUGINS, 'styles/libkvantum.so'),
                  'Aurorae': plugin_present(QT6_PLUGINS, 'org.kde.kdecoration3/org.kde.kwin.aurorae.so',
                                            'org.kde.kdecoration2/org.kde.kwin.aurorae.so')}
        if qt5: wanted['Kvantum for Qt 5'] = plugin_present(QT5_PLUGINS, 'styles/libkvantum.so')
        missing = [name for name, present in wanted.items() if not present]
        if missing:
            raise MissingDependencies('Glassy needs ' + ' and '.join(missing) + ': install them with your '
                                      "distribution's package manager, then run ./install.sh --appearance install. Nothing was changed.")
        return
    names = ['kvantum', 'aurorae'] + (['kvantum-qt5'] if qt5 else [])
    # Verified Arch providers; only source-build tools, never a new style engine.
    if state.get('settings_build') != settings_signature() or not (DATA/'nothing-plasma/bin/glassy-settings').is_file():
        if not shutil.which('cmake'): names.append('cmake')
        if not shutil.which('c++'): names.append('gcc')
    missing = []
    packages = state.setdefault('packages', {})
    for name in names:
        # -T also accepts installed providers (e.g. an existing -git package).
        present = run('pacman', '-T', name, check=False).returncode == 0
        packages.setdefault(name, {'preexisting': present, 'installed_by_us': False})
        if not present:
            run('pacman', '-Si', name)  # Only verified official repository packages.
            missing.append(name)
    save(state)
    if missing:
        escalator = shutil.which('pkexec') or shutil.which('sudo')
        if not escalator: raise ValueError('Missing packages: ' + ', '.join(missing) + '; no authentication helper found')
        subprocess.run([escalator, '/usr/bin/pacman', '-S', '--needed', *missing], check=True)
        for name in missing: packages[name]['installed_by_us'] = True
        save(state)


def slot_current(slot, svg, config):
    files = [(KV / (slot + '.svg'), svg), (KV / (slot + '.kvconfig'), config)]
    return all(path.is_file() and path.read_bytes() == (data.encode() if isinstance(data, str) else data)
               for path, data in files)


def flip_style(state, value):
    """Owned switch between the two Kvantum slots; rollback keeps the original style."""
    keys = state.setdefault('keys', [])
    item = next((item for item in keys if item['key'] == list(STYLE)), None)
    if item is None:
        item = {'key': list(STYLE), 'before': read(STYLE)}
        keys.append(item)
    item['after'] = value
    save(state)
    write(STYLE, value)


def sync(state):
    if not state.get('enabled') or read(KVTHEME) != 'Glassy': return
    p = palette()
    options = glassy_settings()
    svg, config = render(p, options), config_text(p, options)
    style = read(STYLE)
    if style not in SLOTS or slot_current(SLOTS[style], svg, config):
        # Another widget style, or nothing changed for the active slot: refresh
        # the default slot and deliver the palette notification (text/link roles).
        if style not in SLOTS:
            owned_file(state, KV / 'Glassy.svg', svg)
            owned_file(state, KV / 'Glassy.kvconfig', config)
        notify()
        return
    target = next(name for name in SLOTS if name != style)
    owned_file(state, KV / (SLOTS[target] + '.svg'), svg)
    owned_file(state, KV / (SLOTS[target] + '.kvconfig'), config)
    flip_style(state, target)
    notify(style=True)


def config_text(p, options=None):
    # Theme-Config exception 2: omit colors so native Qt palette roles can win.
    # Only Base/AlternateBase remain: Kvantum 1.1.8 standardPalette() explicitly
    # substitutes white for omitted Base and derives AlternateBase from it.
    # Keep those opaque to avoid white-on-white startup views/editable combos.
    # Window, button, text, highlight and link roles need no config override.
    roles = {'base.color': p['base'], 'alt.base.color': p['alternate']}
    config = configure_glassy(TEMPLATE.read_text(), options or glassy_settings())
    # Exception: menu and tooltip text sit on the glass rendered from this
    # palette, so they take its colours too. A process without the KDE palette
    # (KWin's window menu) otherwise drew black text on dark glass.
    menu = {'[MenuItem]\n': {'text.normal.color': p['text'], 'text.focus.color': p['highlight_text'],
                             'text.press.color': p['highlight_text']},
            '[ToolTip]\n': {'text.normal.color': p['text']}}
    for header, keys in menu.items():
        assert config.count(header) == 1, header
        config = config.replace(header, header + ''.join(k + '=' + v + '\n' for k, v in keys.items()))
    return config + '\n[GeneralColors]\n' + ''.join(k + '=' + v + '\n' for k, v in roles.items())


def running_kvantum_apps():
    """Only same-user processes that have actually loaded the Widgets style."""
    for proc in Path('/proc').glob('[0-9]*'):
        try:
            if proc.stat().st_uid != os.getuid(): continue
            if '/styles/libkvantum.so' in (proc / 'maps').read_text(): return True
        except (OSError, UnicodeError):
            continue
    return False


def notification_session():
    # The bus address stays the same across login/reboot. Scope replacement IDs
    # to the actual bus AND notification server instance, not that reused path.
    try:
        base = ('qdbus6', 'org.freedesktop.DBus', '/org/freedesktop/DBus')
        bus = run(*base, 'org.freedesktop.DBus.GetId').stdout.strip()
        owner = run(*base, 'org.freedesktop.DBus.GetNameOwner', 'org.freedesktop.Notifications').stdout.strip()
        return bus + '/' + owner
    except (OSError, subprocess.SubprocessError):
        return ''


def notify_cached_apps(state, previous, current):
    pair = ('NothingPlasmaLight', 'NothingPlasmaDark')
    if previous not in pair or current not in pair or previous == current: return
    session = notification_session()
    transition = [session, previous, current]
    notice = state.setdefault('palette_notice', {})
    if notice.get('transition') == transition: return
    # Glassy reloads live through the slot flip; nothing needs reopening.
    if read(STYLE) in SLOTS: return
    old_session = notice.get('session')
    notice['transition'] = transition
    if read(KVTHEME) != 'Glassy' or not running_kvantum_apps() or not shutil.which('notify-send'): return
    replace = str(notice.get('id', 0)) if session and old_session == session else '0'
    result = run('notify-send', '--app-name=Nothing KDE', '--transient', '--print-id',
                 '--replace-id=' + replace, '--expire-time=8000', 'Theme updated',
                 'Bazı açık uygulamalar yeni renkleri görmek için yeniden açılabilir.', check=False)
    if result.returncode == 0 and result.stdout.strip().isdigit():
        notice.update(id=int(result.stdout.strip()), session=session)


def record_scheme(state, previous):
    """Record only an explicit Nothing switch; external palette choices stay unowned."""
    if not state.get('enabled'): return
    current = read(SCHEME)
    if current not in ('NothingPlasmaLight', 'NothingPlasmaDark') or not previous: return
    keys = state.setdefault('keys', [])
    item = next((item for item in keys if item['key'] == list(SCHEME)), None)
    if item is None:
        keys.append({'key': list(SCHEME), 'before': previous, 'after': current})
    else:
        # A user-selected external scheme between Nothing switches becomes the
        # new rollback target; do not revert a later user choice to ancient state.
        if previous != item['after']: item['before'] = previous
        item['after'] = current
    notify_cached_apps(state, previous, current)
    save(state)


def settings_signature():
    source = ROOT / 'runtime/settings'
    return digest(b''.join(p.read_bytes() for p in sorted(source.iterdir()) if p.is_file()))


def install_settings_tool(state):
    source = ROOT / 'runtime/settings'
    binary = DATA / 'nothing-plasma/bin/glassy-settings'
    signature = settings_signature()
    if state.get('settings_build') != signature or not binary.is_file():
        if not shutil.which('cmake') or not shutil.which('c++'):
            # Arch gets the build tools above; elsewhere the utility waits for them.
            if not shutil.which('pacman'):
                print('Glassy Settings skipped: building it needs cmake and a C++ compiler. Glassy itself is installed.')
                return
            raise ValueError('Building the native Glassy settings utility requires cmake and a C++ compiler (build tools only).')
        with tempfile.TemporaryDirectory(prefix='glassy-settings-build-') as directory:
            subprocess.run(['cmake','-S',str(source),'-B',directory,'-DCMAKE_BUILD_TYPE=Release'],check=True)
            subprocess.run(['cmake','--build',directory,'-j2'],check=True)
            owned_file(state,binary,(Path(directory)/'glassy-settings').read_bytes())
            binary.chmod(0o755)
        state['settings_build'] = signature; save(state)
    command = str(binary).replace('\\','\\\\').replace('"','\\"').replace('`','\\`').replace('$','\\$')
    owned_file(state,DATA/'applications/org.glassy.settings.desktop',
               '[Desktop Entry]\nType=Application\nName=Glassy Settings\nName[tr]=Glassy Ayarları\n'
               'Icon=preferences-desktop-theme\nExec="'+command+'"\nCategories=Qt;KDE;Settings;DesktopSettings;\n')


def install(state, qt5=False):
    before = tuple(read(key) for key in (STYLE, LIBRARY, THEME, KVTHEME, BLUR))
    dependencies(state, qt5)
    if 'snapshot' not in state:
        state['snapshot'] = {'/'.join(key): read(key) for key in (STYLE, LIBRARY, THEME, SCHEME, KVTHEME, BLUR)}
        save(state)
    # The framework/plugin belongs to the distro. Only our native theme assets
    # and two small sync helpers are copied; unchanged files are never rewritten.
    sources = [(ROOT / 'assets/kvantum/Glassy/Glassy.kvconfig', TEMPLATE)]
    sources.append((ROOT / 'plasma/aurorae/i18n/glassydecoration.mo', TRANSLATION))
    sources += [(path, DECO / path.relative_to(ROOT / 'plasma/aurorae/org.glassy.decoration'))
                for path in (ROOT / 'plasma/aurorae/org.glassy.decoration').rglob('*') if path.is_file() and path.name != 'config.ui']
    sources += [(ROOT / 'runtime' / name, DATA / 'nothing-plasma/bin' / name)
                for name in ('appearance.py', 'appearance_render.py', 'glassy_settings.py')]
    decoration_changed = False
    for source, target in sources:
        changed = owned_file(state, target, source.read_bytes())
        decoration_changed |= changed and target.is_relative_to(DECO)
    spec = importlib.util.spec_from_file_location('glassy_decoration_build', ROOT / 'plasma/aurorae/build.py')
    builder = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(builder)
    for name, data in builder.assets(ROOT / 'plasma/aurorae/org.glassy.decoration').items():
        decoration_changed |= owned_file(state, DECO / name, data)
    manifest = {str(target) for source, target in sources}
    manifest.update(str(DECO / name) for name in builder.assets(ROOT / 'plasma/aurorae/org.glassy.decoration'))
    for name, item in list(state.get('files', {}).items()):
        path = Path(name)
        if path.is_relative_to(DECO) and name not in manifest:
            if path.is_file() and not path.is_symlink() and digest(path.read_bytes()) == item['after']:
                path.unlink()
                state['files'].pop(name)
                print('Removed superseded owned decoration asset:', path.name)
    save(state)
    p = palette()
    options = glassy_settings()
    owned_file(state, KV / 'Glassy.svg', render(p, options))
    owned_file(state, KV / 'Glassy.kvconfig', config_text(p, options))
    for key, value in ((KVTHEME, 'Glassy'), (STYLE, 'kvantum'),
                       (LIBRARY, 'org.kde.kwin.aurorae'), (THEME, 'org.glassy.decoration'), (BLUR, 'true')):
        set_owned(state, key, value)
    state['enabled'] = True
    save(state)
    install_settings_tool(state)
    if before != tuple(read(key) for key in (STYLE, LIBRARY, THEME, KVTHEME, BLUR)):
        notify(style=True)
    elif decoration_changed:
        reload_decoration()
    print('Glassy application style + decoration installed. Existing dependencies and unrelated appearance settings retained.')
    print('Palette, accent and Glassy setting changes reload live in running KDE applications; none are restarted.')


def restore(state, remove=False):
    entries = {tuple(item['key']): item for item in state.get('keys', [])}
    protected = set()
    # Native selections are pairs. Never combine a restored plugin with a
    # user-chosen theme belonging to a different engine (or vice versa).
    for pair in ((LIBRARY, THEME), (STYLE, KVTHEME)):
        if all(key in entries for key in pair) and any(read(key) != entries[key]['after'] for key in pair):
            protected.update(pair)
    for item in reversed(state.get('keys', [])):
        if tuple(item['key']) in protected:
            print('Keeping user selection pair:', '/'.join(item['key'])); continue
        if read(item['key']) == item['after']:
            if tuple(item['key']) == SCHEME and item['before'] != '__NOTHING_ABSENT__':
                run('plasma-apply-colorscheme', item['before'])
            else: write(item['key'], item['before'])
        else: print('Keeping user selection:', '/'.join(item['key']))
    state['enabled'] = False
    state['keys'] = []
    save(state)
    notify(style=True)
    if remove:
        for name, item in list(state.get('files', {}).items()):
            path = Path(name)
            allowed = path.is_relative_to(KV) or path.is_relative_to(DECO) or path in (TEMPLATE, TRANSLATION) or path in [DATA / 'nothing-plasma/bin' / n for n in ('appearance.py', 'appearance_render.py')]
            if allowed and path.is_file() and not path.is_symlink() and digest(path.read_bytes()) == item['after']:
                path.unlink()
                state['files'].pop(name)
        save(state)
    print('Appearance selections restored where still owned; no dependency packages removed.')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('action', choices=('install', 'sync', 'disable', 'uninstall', 'status', 'record-scheme'))
    parser.add_argument('--previous-scheme', help=argparse.SUPPRESS)
    parser.add_argument('--qt5', action='store_true', help='Explicitly add the Qt5 backend only if needed')
    args = parser.parse_args()
    if args.action in ('sync', 'record-scheme') and not STATE.exists(): return
    STATE.parent.mkdir(parents=True, exist_ok=True)
    with (STATE.parent / '.lock').open('a') as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)
        state = json.loads(STATE.read_text()) if STATE.exists() else {}
        if args.action == 'install': install(state, args.qt5)
        elif args.action == 'sync': sync(state)
        elif args.action == 'record-scheme': record_scheme(state, args.previous_scheme)
        elif args.action in ('disable', 'uninstall'): restore(state, args.action == 'uninstall')
        else: print(json.dumps(state, indent=2))


if __name__ == '__main__':
    try: main()
    except MissingDependencies as error:
        print(error, file=sys.stderr); sys.exit(3)
    except (OSError, ValueError, subprocess.SubprocessError) as error:
        sys.exit(str(error))

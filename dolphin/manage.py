#!/usr/bin/env python3
"""Nothing KDE: optional native Dolphin appearance, with guarded restoration."""
import argparse
import fcntl
import json
import hashlib
import os
from pathlib import Path
import sys
import subprocess

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'runtime'))
from importlib import import_module
atomic = import_module('accent-links').atomic


def values(text):
    result, group = {}, ''
    for line in text.splitlines():
        if line.startswith('['): group = line.strip()
        elif '=' in line and not line.lstrip().startswith(('#', ';')):
            key, value = line.split('=', 1)
            result[(group, key)] = value
    return result


def change(text, group, key, value):
    section, found, lines = '', False, []
    for line in text.splitlines(keepends=True):
        if line.startswith('['):
            if section == group and not found and value is not None:
                lines.append(key + '=' + value + '\n'); found = True
            section = line.strip()
        if section == group and line.startswith(key + '='):
            if value is not None: lines.append(key + '=' + value + '\n')
            found = True
        else: lines.append(line)
    if not found and value is not None:
        if lines and not lines[-1].endswith('\n'): lines[-1] += '\n'
        if section != group: lines.append('\n' + group + '\n')
        lines.append(key + '=' + value + '\n')
    return ''.join(lines)


def desktop_style(text, stylesheet):
    original = values(text).get(('[Desktop Entry]', 'Exec'), '')
    if not original.startswith(('dolphin ', '/usr/bin/dolphin ')) or '-stylesheet' in original:
        raise ValueError('Custom Dolphin launcher: stylesheet not installed; original retained')
    executable, args = original.split(' ', 1)
    quoted = str(stylesheet).replace('\\', '\\\\').replace('"', '\\"').replace('`', '\\`').replace('$', '\\$').replace('%', '%%')
    result = change(text, '[Desktop Entry]', 'Exec', executable + ' -stylesheet "' + quoted + '" ' + args)
    # Qt handles the stylesheet argument at startup; no wrapper or daemon.
    return result


def prepare_style(state, root, data):
    target = data / 'applications/org.kde.dolphin.desktop'
    appearance = state.get('appearance')
    if appearance:
        if target.read_text() != appearance['after']:
            raise ValueError('Dolphin launcher was edited after apply; restore/review it before upgrading')
        if (root / 'style.qss').read_text() != appearance.get('style_after', ''):
            raise ValueError('Dolphin stylesheet was edited after apply; original retained')
        return appearance
    before = target.read_text() if target.exists() else None
    source = before
    if source is None:
        for directory in os.environ.get('XDG_DATA_DIRS', '/usr/local/share:/usr/share').split(':'):
            candidate = Path(directory) / 'applications/org.kde.dolphin.desktop'
            if candidate.is_file(): source = candidate.read_text(); break
    if source is None: raise ValueError('Native Dolphin desktop entry not found')
    stylesheet = root / 'style.qss'
    after = desktop_style(source, stylesheet)
    if target.is_symlink() or stylesheet.is_symlink(): raise ValueError('Refusing symbolic-link appearance targets')
    return {'path': str(target), 'before': before, 'after': after, 'source': source,
            'style_before': stylesheet.read_text() if stylesheet.exists() else None}


def restore_style(state, root):
    appearance = state.get('appearance')
    if not appearance: return
    target = Path(appearance['path'])
    if target.exists():
        text = target.read_text()
        if text == appearance['after']:
            if appearance['before'] is None: target.unlink()
            else: atomic(target, appearance['before'])
        else:
            key = ('[Desktop Entry]', 'Exec')
            # Keep user-added translations/actions/comments; restore only our Exec.
            if values(text).get(key) == values(appearance['after']).get(key):
                atomic(target, change(text, *key, values(appearance['source'])[key]))
    # Leave a harmless empty file for any already-resolved launch request.
    stylesheet = root / 'style.qss'
    if stylesheet.exists() and stylesheet.read_text() == appearance.get('style_after'):
        atomic(stylesheet, appearance['style_before'] or '')


def manage(action, config, data=None):
    path = config / 'dolphinrc'
    root = config / 'nothing-kde/dolphin'
    root.mkdir(parents=True, exist_ok=True)
    with (root / '.lock').open('a') as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)
        journal_path = root / 'state.json'
        state = json.loads(journal_path.read_text()) if journal_path.exists() else None
        if action == 'status': return {'enabled': bool(state), 'backup': str(root / 'dolphinrc.before')}
        text = path.read_text() if path.exists() else ''
        current = values(text)
        if action == 'apply':
            profile = json.loads((Path(__file__).parent / 'profile.json').read_text())
            style = (Path(__file__).parent / 'style.qss').read_text()
            revision = hashlib.sha256((json.dumps(profile) + style).encode()).hexdigest()
            if state and state.get('revision') == revision and (data is None or state.get('appearance')):
                return {'enabled': True, 'changed': False}
            if state:
                state['exact_restore'] = state.get('exact_restore', True) and text == state['after']
            else:
                state = {'before': text, 'keys': [], 'exact_restore': True}
                atomic(root / 'dolphinrc.before', text)
            if data is not None:
                state['appearance'] = prepare_style(state, root, data)
                state['appearance']['style_after'] = style
            preserved = []
            for group, settings in profile.items():
                group = '[' + group + ']'
                for key, value in settings.items():
                    # Respect native KConfig's immutable entries/groups.
                    if group + '[$i]' in text or (group, key + '[$i]') in current:
                        continue
                    item = next((v for v in state['keys'] if v['group'] == group and v['key'] == key), None)
                    if item:
                        if current.get((group, key)) != item['after']:
                            preserved.append(group + '/' + key); continue
                        item['after'] = value
                    else:
                        state['keys'].append({'group': group, 'key': key, 'before': current.get((group, key)), 'after': value})
                    text = change(text, group, key, value)
            state['after'] = text
            state['revision'] = revision
            atomic(journal_path, json.dumps(state, indent=2) + '\n')
            if data is not None:
                atomic(root / 'style.qss', style)
                atomic(Path(state['appearance']['path']), state['appearance']['after'])
            atomic(path, text)
            return {'enabled': True, 'backup': str(root / 'dolphinrc.before'), 'preserved_user_changes': preserved}
        if not state: return {'enabled': False, 'changed': False}
        preserved = []
        if text == state['after'] and state.get('exact_restore', True): text = state['before']
        else:
            for item in state['keys']:
                if current.get((item['group'], item['key'])) == item['after']:
                    text = change(text, item['group'], item['key'], item['before'])
                else: preserved.append(item['group'] + '/' + item['key'])
        atomic(path, text)
        restore_style(state, root)
        atomic(journal_path, 'null\n')
        return {'enabled': False, 'preserved_user_changes': preserved}


def refresh_running_style(config, enabled):
    """One-shot Qt API call; never close windows or install a resident process."""
    root = config / 'nothing-kde/dolphin'
    saved_path = root / 'running-styles.json'
    saved = json.loads(saved_path.read_text()) if saved_path.exists() else {}
    style = (root / 'style.qss').read_text() if enabled else ''
    try:
        services = subprocess.check_output(['qdbus6'], text=True, timeout=5).split()
        for service in services:
            if not service.startswith('org.kde.dolphin-'): continue
            cmd = ['qdbus6', service, '/MainApplication']
            current = subprocess.check_output(cmd + ['org.qtproject.Qt.QApplication.styleSheet'], text=True, timeout=5).rstrip('\n')
            if enabled:
                if service not in saved: saved[service] = {'before': current}
                saved[service]['after'] = style
                atomic(saved_path, json.dumps(saved, indent=2) + '\n')
                subprocess.run(cmd + ['org.qtproject.Qt.QApplication.setStyleSheet', style], check=True, timeout=5, capture_output=True)
            elif service in saved and current == saved[service]['after'].rstrip('\n'):
                subprocess.run(cmd + ['org.qtproject.Qt.QApplication.setStyleSheet', saved[service]['before']], check=True, timeout=5, capture_output=True)
            elif not enabled and current in ((root / 'style.qss').as_uri(), 'file:///' + str(root / 'style.qss'),
                                              (Path(__file__).parent / 'style.qss').read_text().rstrip('\n')):
                subprocess.run(cmd + ['org.qtproject.Qt.QApplication.setStyleSheet', ''], check=True, timeout=5, capture_output=True)
        if not enabled: atomic(saved_path, '{}\n')
        subprocess.run(['kbuildsycoca6'], check=False, timeout=20, capture_output=True)
    except (OSError, subprocess.SubprocessError):
        print('Reopen Dolphin to load the appearance / Görünüm için Dolphin’i yeniden açın.', file=sys.stderr)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('action', choices=('apply', 'restore', 'status'))
    args = parser.parse_args()
    try:
        config = Path(os.environ.get('XDG_CONFIG_HOME', Path.home() / '.config'))
        data = Path(os.environ.get('XDG_DATA_HOME', Path.home() / '.local/share'))
        print(json.dumps(manage(args.action, config, data)))
        if args.action != 'status': refresh_running_style(config, args.action == 'apply')
    except (OSError, ValueError) as error:
        parser.exit(1, str(error) + '\n')

#!/usr/bin/env python3
"""Optional, reversible accent overlays. No daemon and no boot-file writes."""
import argparse
import fcntl
import json
import os
from pathlib import Path
import re
import shlex
import signal
import subprocess
import tempfile
import tomllib
import sys

sys.path.insert(0, str(Path(__file__).resolve().parent))
from jsonc_edit import Document

BEGIN = '# >>> Nothing KDE accent >>>'
END = '# <<< Nothing KDE accent <<<'
TARGETS = ('starship', 'spaceship', 'fastfetch')


def accent(value):
    if re.fullmatch(r'#[0-9a-fA-F]{6}', value): return value.upper()
    parts = value.split(',')
    if len(parts) == 3 and all(p.isdigit() and 0 <= int(p) <= 255 for p in parts):
        return '#' + ''.join(f'{int(p):02X}' for p in parts)
    raise ValueError('Expected #RRGGBB or KDE RGB accent')


def current_accent():
    for group, key in [('General', 'AccentColor'), ('Colors:Selection', 'BackgroundNormal')]:
        result = subprocess.run(['kreadconfig6', '--file', 'kdeglobals', '--group', group, '--key', key],
                                capture_output=True, text=True, check=False, timeout=5)
        try: return accent(result.stdout.strip())
        except ValueError: pass
    raise ValueError('KDE accent is unavailable')


def atomic(path, text):
    path.parent.mkdir(parents=True, exist_ok=True)
    if path.is_symlink(): raise ValueError('Refusing to replace a symbolic link: ' + str(path))
    if path.exists() and path.read_text() == text: return
    mode = path.stat().st_mode & 0o777 if path.exists() else 0o600
    fd, temporary = tempfile.mkstemp(prefix='.nothing-kde-', dir=path.parent)
    try:
        with os.fdopen(fd, 'w') as file: file.write(text)
        os.chmod(temporary, mode)
        os.replace(temporary, path)
    finally:
        if os.path.exists(temporary): os.unlink(temporary)


def block(text, content=None):
    if text.count(BEGIN) != text.count(END) or text.count(BEGIN) > 1:
        raise ValueError('Incomplete or duplicate Nothing KDE block; no changes made')
    text = re.sub(re.escape(BEGIN) + r'\n[\s\S]*?' + re.escape(END) + r'\n?', '', text)
    if content is not None:
        text += ('' if not text or text.endswith('\n') else '\n') + BEGIN + '\n' + content + '\n' + END + '\n'
    return text


def current_palette():
    roles = {'text': ('Window', 'ForegroundNormal'), 'window': ('Window', 'BackgroundNormal'),
             'base': ('View', 'BackgroundNormal'), 'button': ('Button', 'BackgroundNormal'),
             'alternate': ('View', 'BackgroundAlternate'), 'selection_text': ('Selection', 'ForegroundNormal')}
    palette = {}
    for role, (group, key) in roles.items():
        result = subprocess.run(['kreadconfig6', '--file', 'kdeglobals', '--group', 'Colors:'+group, '--key', key],
                                capture_output=True, text=True, check=True, timeout=5)
        palette[role] = accent(result.stdout.strip())
    return palette


def luminance(color):
    rgb = [int(color[i:i+2], 16)/255 for i in (1,3,5)]
    rgb = [v/12.92 if v<=.04045 else ((v+.055)/1.055)**2.4 for v in rgb]
    return sum(v*w for v,w in zip(rgb,(.2126,.7152,.0722)))


def contrast(a, b):
    light, dark = sorted((luminance(a),luminance(b)),reverse=True)
    return (light+.05)/(dark+.05)


def readable_foreground(background, palette, preferred=None):
    """Use palette colors first; only adjust luminance if none reaches 4.5:1."""
    if preferred and contrast(preferred,background)>=4.5: return preferred
    candidate = max(palette.values(),key=lambda value: contrast(value,background))
    if contrast(candidate,background)>=4.5: return candidate
    return contrast_tint(candidate,background)


def contrast_tint(candidate, background):
    """Minimal luminance adjustment, retaining the supplied color's tint."""
    rgb = [int(candidate[i:i+2],16) for i in (1,3,5)]
    # Extreme luminance is a search endpoint, not a fixed replacement color.
    pole = 0 if luminance(background)>.179 else 255
    def mixed(amount):
        return '#' + ''.join(f'{round(v+(pole-v)*amount):02X}' for v in rgb)
    lo, hi = 0., 1.
    for _ in range(24):
        mid = (lo+hi)/2
        if contrast(mixed(mid),background)>=4.5: hi=mid
        else: lo=mid
    return mixed(hi)


def palette_starship(text, palette):
    """Separate powerline paint from text; preserve shapes, module order and glyphs."""
    data = tomllib.loads(text)
    name = data.get('palette','')
    colors = dict(data.get('palettes',{}).get(name,{}))
    for key, role in {'bg0':'window','bg1':'base','bg2':'button','bg3':'alternate','text':'text','muted':'text'}.items():
        if key in colors:
            colors[key] = palette[role]
            text = toml_value(text,'palettes.'+name,key,colors[key])
    def resolve(value):
        value = colors.get(value,value)
        # Resolve explicit ANSI background names; these are not chosen foregrounds.
        value = {'black':'#000000','white':'#FFFFFF'}.get(value,value)
        return value if re.fullmatch(r'#[0-9a-fA-F]{6}',value) else None
    def style(value, semantic=False):
        if '$' in value: return value
        tokens=value.split()
        bg=next((resolve(t[3:]) for t in tokens if t.startswith('bg:')),None) or palette['window']
        attributes={'bold','italic','underline','dimmed','inverted','strikethrough','blink','hidden'}
        old=next((resolve(t[3:] if t.startswith('fg:') else t) for t in tokens if not t.startswith('bg:') and t not in attributes),None)
        if semantic and old and contrast(old,bg)>=4.5: return value
        fg=contrast_tint(old,bg) if semantic and old else readable_foreground(bg,palette,palette['text'])
        return ' '.join([t for t in tokens if t in attributes or t.startswith('bg:')] + ['fg:'+fg])
    def formatted(value, semantic=False):
        def replace(match):
            glyph=match[1].strip()
            # These foregrounds paint background transitions, not icon/text ink.
            if glyph and all('\ue0b0'<=c<='\ue0d7' for c in glyph): return match[0]
            return '['+match[1]+']('+style(match[2],semantic)+')'
        return re.sub(r'\[([^\[\]]*)\]\(([^()]*)\)',replace,value)
    for group, fields in data.items():
        if group=='palettes' or not isinstance(fields,dict): continue
        for key,value in fields.items():
            if not isinstance(value,str): continue
            semantic=group in ('git_status','status','battery') or key in ('error_symbol','style_root','read_only_style')
            changed = (style(value,semantic) if key=='style' or key.endswith('_style') or key.startswith('style_')
                       else formatted(value,semantic) if key=='format' or key.endswith('_symbol') else value)
            if changed!=value: text=toml_value(text,group,key,changed)
    return text


def patch_starship(text, color, palette=None):
    """Keep module order and glyphs; derive normal ink/surfaces from KDE."""
    palette = current_palette() if palette is None else palette
    data = tomllib.loads(text)
    palette_name = data.get('palette', '')
    colors = data.get('palettes', {}).get(palette_name, {})
    # Explicit semantic names; never guess that red/green are decoration rather
    # than exit-status colors. Other setups get a directory foreground override.
    key = next((k for k in ('accent', 'ice') if k in colors), None)
    if key:
        group = 'palettes.' + palette_name
        pattern = re.compile(r'^(\s*' + key + r'\s*=\s*)(["\']).*?\2', re.M)
        lines, section = [], ''
        for line in text.splitlines(keepends=True):
            if re.match(r'^\s*\[', line): section = line.strip().strip('[]')
            lines.append(pattern.sub(lambda m: m[1] + '"' + color + '"', line) if section == group else line)
        result = ''.join(lines)
        if tomllib.loads(result)['palettes'][palette_name][key] != color:
            raise ValueError('Unsupported quoted Starship palette layout; original retained')
        # The Frost preset uses blue for the directory's powerline edges while
        # its body incorrectly uses bg2. Link that section explicitly, without
        # changing blue globally (e.g. Go's language color).
        directory = data.get('directory', {})
        fmt = directory.get('format', '')
        if 'bg:blue' in fmt and 'fg:blue' in fmt:
            fmt = fmt.replace('bg:blue', 'bg:' + color).replace('fg:blue', 'fg:' + color)
            result = toml_value(result, 'directory', 'format', fmt)
            foreground = readable_foreground(color,palette)
            result = toml_value(result, 'directory', 'style', 'fg:' + foreground + ' bg:' + color)
            if 'read_only_style' in directory:
                result = toml_value(result,'directory','read_only_style',directory['read_only_style'].replace('bg:blue','bg:'+color))
        return palette_starship(starship_success(result,palette['text']),palette)
    directory = data.get('directory', {})
    style = directory.get('style', 'bold cyan')
    tokens = [t for t in style.split() if t in ('bold', 'italic', 'underline', 'dimmed') or t.startswith('bg:')]
    style = ' '.join(tokens + ['fg:' + color])
    lines, section, changed = [], '', False
    for line in text.splitlines(keepends=True):
        if re.match(r'^\s*\[', line): section = line.strip().strip('[]')
        if section == 'directory' and re.match(r'^\s*style\s*=', line):
            line = 'style = ' + json.dumps(style) + '\n'; changed = True
        lines.append(line)
        if section == 'directory' and line.strip() == '[directory]' and 'style' not in directory:
            lines.append('style = ' + json.dumps(style) + '\n'); changed = True
    if not changed: lines.append('\n[directory]\nstyle = ' + json.dumps(style) + '\n')
    result = ''.join(lines)
    tomllib.loads(result)
    return palette_starship(starship_success(result,palette['text']),palette)


def toml_value(text, group, key, value):
    """Replace a simple string assignment, or insert a missing one. Fail closed
    for unusual multiline/quoted layouts rather than damaging a user config."""
    before = tomllib.loads(text)
    fields=before
    for part in group.split('.'): fields=fields.get(part,{})
    section, found, lines = '', False, []
    for line in text.splitlines(keepends=True):
        if re.match(r'^\s*\[', line): section = line.strip().strip('[]')
        if section == group and re.match(r'^\s*' + re.escape(key) + r'\s*=', line):
            line = key + ' = ' + json.dumps(value, ensure_ascii=False) + '\n'; found = True
        lines.append(line)
        if line.strip() == '[' + group + ']' and key not in fields:
            lines.append(key + ' = ' + json.dumps(value, ensure_ascii=False) + '\n'); found = True
    if not found:
        if fields: raise ValueError('Unsupported Starship section layout')
        lines.append('\n[' + group + ']\n' + key + ' = ' + json.dumps(value, ensure_ascii=False) + '\n')
    result = ''.join(lines)
    expected = tomllib.loads(text)
    fields=expected
    for part in group.split('.'): fields=fields.setdefault(part,{})
    fields[key]=value
    if tomllib.loads(result) != expected: raise ValueError('Unsupported Starship string layout')
    return result


def starship_success(text, color):
    character = tomllib.loads(text).get('character', {})
    # Preserve custom glyphs and attributes; only replace foreground tokens in
    # the successful prompt. Failure/root/warning styles remain independent.
    value = character.get('success_symbol', '[❯](bold green)')
    def style(match):
        tokens = [t for t in match[1].split() if t in ('bold', 'italic', 'underline', 'dimmed', 'inverted') or t.startswith('bg:')]
        return '](' + ' '.join(tokens + ['fg:' + color]) + ')'
    patched = re.sub(r'\]\(([^()]*)\)', style, value)
    return toml_value(text, 'character', 'success_symbol', patched) if patched != value else text


def limine_preview(text, color):
    """Limine 12: branding/help/countdown accents, never terminal palette/boot entries."""
    color = accent(color)[1:]
    seen = set()
    def replace(match):
        key = match[2].lower().replace('colour', 'color')
        if key in seen or not re.fullmatch(r'[0-9a-fA-F]{6}', match[3].strip()):
            raise ValueError('Duplicate or pre-v12 Limine color field; original retained')
        seen.add(key)
        return match[1] + color
    result = re.sub(r'^(\s*(interface_(?:branding_colou?r|help_colou?r(?:_bright)?))\s*:\s*)([^\r\n]+)',
                    replace, text, flags=re.M | re.I)
    missing = [key + ': ' + color + '\n' for key in ('interface_branding_color', 'interface_help_color', 'interface_help_color_bright') if key not in seen]
    return ''.join(missing) + result


class Links:
    def __init__(self, config=None, home=None):
        self.home = Path(home or Path.home())
        self.config = Path(config or os.environ.get('XDG_CONFIG_HOME', self.home / '.config'))
        self.root = self.config / 'nothing-kde/accent-links'
        self.state_file = self.root / 'state.json'
        self.state = json.loads(self.state_file.read_text()) if self.state_file.exists() else {}

    def save(self): atomic(self.state_file, json.dumps(self.state, indent=2) + '\n')

    def edit(self, path, content):
        previous = path.read_text() if path.exists() else ''
        backup = self.root / 'backups' / str(path.relative_to(self.home))
        if not backup.exists(): atomic(backup, previous)
        atomic(path, block(previous, content))

    def retire_kitty(self):
        """Remove only our old include; never create a backup or recolor Kitty."""
        path = self.config / 'kitty/kitty.conf'
        changed = False
        if path.exists():
            previous = path.read_text()
            if BEGIN in previous:
                atomic(path, block(previous, None))
                changed = True
        if 'kitty' in self.state:
            self.state.pop('kitty')
            self.save()
        (self.root / 'kitty.conf').unlink(missing_ok=True)
        if changed: reload_kitty()

    def starship(self, enabled, color):
        source = self.config / 'starship.toml'
        generated = self.root / 'starship.toml'
        hook = self.config / 'fish/conf.d/00-nothing-kde-accent.fish'
        if enabled:
            existing = os.environ.get('STARSHIP_CONFIG')
            if existing and Path(existing) not in (source, generated):
                raise ValueError('Custom STARSHIP_CONFIG is active; no prompt override installed')
            if not source.exists() or not (self.config / 'fish').is_dir():
                raise ValueError('Starship/Fish configuration not found; use the export command for other shells')
            atomic(generated, patch_starship(source.read_text(), color))
            code = ('if not set -q STARSHIP_CONFIG; or test "$STARSHIP_CONFIG" = ' + shlex.quote(str(source))
                    + '\n    set -gx STARSHIP_CONFIG ' + shlex.quote(str(generated)) + '\nend')
            self.edit(hook, code)
        else:
            # Existing shells may still reference this path. Restore its original
            # content rather than removing a file used by an active prompt.
            if source.exists() and generated.exists(): atomic(generated, source.read_text())
            if hook.exists(): self.edit(hook, None)

    def spaceship(self, enabled, color):
        path = self.home / '.zshrc'
        if enabled:
            if not path.exists(): raise ValueError('Zsh configuration not found')
            atomic(self.root / 'spaceship-color', color + '\n')
            colorfile = shlex.quote(str(self.root / 'spaceship-color'))
            script = '''# Only successful prompt decoration; failure/root colors are untouched.
if (( ! ${+_nothing_kde_spaceship_saved} )); then
  typeset -g _nothing_kde_spaceship_saved=1
  typeset -g _nothing_kde_spaceship_before=${SPACESHIP_CHAR_COLOR_SUCCESS-green}
fi
function _nothing_kde_spaceship_accent() {
  local nothing_accent
  if [[ -s COLORFILE ]]; then
    nothing_accent=$(<COLORFILE)
    SPACESHIP_CHAR_COLOR_SUCCESS=$nothing_accent
  else
    SPACESHIP_CHAR_COLOR_SUCCESS=$_nothing_kde_spaceship_before
  fi
}
autoload -Uz add-zsh-hook
add-zsh-hook -d precmd _nothing_kde_spaceship_accent
add-zsh-hook precmd _nothing_kde_spaceship_accent
_nothing_kde_spaceship_accent
'''.replace('COLORFILE', colorfile)
            atomic(self.root / 'spaceship.zsh', script)
            self.edit(path, 'source ' + shlex.quote(str(self.root / 'spaceship.zsh')))
        else:
            atomic(self.root / 'spaceship-color', '')
            if path.exists(): self.edit(path, None)

    def fastfetch(self, enabled, color):
        path = self.config / 'fastfetch/config.jsonc'
        if not path.exists(): path = self.config / 'fastfetch/config.json'
        journal_path = self.root / 'fastfetch-state.json'
        journal = json.loads(journal_path.read_text()) if journal_path.exists() else None
        if journal: path = Path(journal['path'])
        if not path.exists():
            if enabled: raise ValueError('Fastfetch config not found')
            return
        original = path.read_text()
        doc = Document(original)
        if not enabled:
            if not journal: return
            if original == journal['after']:
                atomic(path, journal['before'])
            else:
                text = original
                for item in reversed(journal['keys']):
                    doc = Document(text); key = tuple(item['path'])
                    if key in doc.spans and doc.get(key) == item['after']:
                        text = doc.set(key, item.get('before'), remove=not item['existed'])
                atomic(path, text)
            # Keep the original backup, but start a fresh transaction on re-enable.
            atomic(journal_path, 'null\n')
            return
        if not journal:
            journal = {'path': str(path), 'before': original, 'keys': []}
            atomic(self.root / 'backups/fastfetch-config.jsonc', original)
        updates = [(('display', 'color', 'keys'), color), (('display', 'color', 'title'), color)]
        logo = doc.data.get('logo', {})
        source_key = ('logo', 'source')
        saved = next((v for v in journal['keys'] if tuple(v['path']) == source_key), None)
        source = saved['before'] if saved else logo.get('source', '') if isinstance(logo, dict) else ''
        if isinstance(logo, dict) and logo.get('type') == 'file-raw' and source:
            logo_path = Path(os.path.expandvars(os.path.expanduser(source)))
            if logo_path.is_absolute() and logo_path.is_file() and logo_path.stat().st_size < 1024 * 1024:
                raw = logo_path.read_text()
                # Plain user logos only: preserve existing multi-color/ANSI art.
                if '\x1b' not in raw:
                    rgb = ';'.join(str(int(color[i:i+2], 16)) for i in (1, 3, 5))
                    generated = self.root / 'fastfetch-logo.txt'
                    atomic(generated, ''.join('\x1b[38;2;' + rgb + 'm' + line + '\x1b[0m\n' for line in raw.splitlines()))
                    updates.append((source_key, str(generated)))
        text = original
        for key, value in updates:
            doc = Document(text)
            item = next((v for v in journal['keys'] if tuple(v['path']) == key), None)
            if item is None:
                item = {'path': list(key), 'existed': key in doc.spans}
                if item['existed']: item['before'] = doc.get(key)
                journal['keys'].append(item)
            item['after'] = value
            text = doc.set(key, value)
        journal['after'] = text
        # Journal first: even interruption before the config write is recoverable.
        atomic(journal_path, json.dumps(journal, indent=2) + '\n')
        atomic(path, text)

    def set(self, target, enabled, color):
        getattr(self, target)(enabled, color)
        self.state[target] = enabled
        self.save()

    def sync(self, color):
        for target in TARGETS:
            if self.state.get(target): getattr(self, target)(True, color)

    def status(self):
        zshrc = self.home / '.zshrc'
        spaceship_found = zshrc.exists() and ('spaceship' in zshrc.read_text().lower()
                           or Path('/usr/share/zsh/themes/spaceship.zsh-theme').exists())
        return {'enabled': {target: bool(self.state.get(target)) for target in TARGETS},
                'available': {'starship': (self.config / 'starship.toml').exists() and (self.config / 'fish').is_dir(),
                              'fastfetch': any((self.config / ('fastfetch/config.' + ext)).exists() for ext in ('jsonc', 'json')),
                              'spaceship': spaceship_found},
                'limine': 'export-only; enrolled boot configuration requires manual review'}


def reload_kitty():
    # Kitty officially reloads config on SIGUSR1. No remote-control socket or
    # allow_remote_control setting is opened for this integration.
    result = subprocess.run(['pgrep', '-u', str(os.getuid()), '-x', 'kitty'], capture_output=True, text=True)
    for pid in result.stdout.split():
        try: os.kill(int(pid), signal.SIGUSR1)
        except ProcessLookupError: pass


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('action', choices=('status', 'enable', 'disable', 'sync', 'export'))
    parser.add_argument('target', nargs='?', choices=(*TARGETS, 'limine', 'all', 'kitty'))
    parser.add_argument('--accent')
    parser.add_argument('--source', type=Path)
    parser.add_argument('--output', type=Path)
    args = parser.parse_args()
    if args.target == 'kitty' and args.action != 'disable':
        parser.error('Kitty accent integration has been removed; only disable is supported')
    try:
        links = Links()
        if args.action == 'status': print(json.dumps(links.status())); return
        color = accent(args.accent) if args.accent else ('#D71921' if args.action == 'disable' else current_accent())
        if args.action == 'export':
            if args.target not in ('starship', 'limine') or not args.source or not args.output:
                parser.error('export starship|limine requires --source and --output')
            if args.output.resolve() == args.source.resolve() or args.output.exists():
                raise ValueError('Export must use a new output path; never the original config')
            # Do not accept system boot paths as output, even when invoked as root.
            if str(args.output.resolve()).startswith(('/boot/', '/efi/', '/etc/')):
                raise ValueError('Export to a user-owned review file, not a boot/system config')
            transform = patch_starship if args.target == 'starship' else limine_preview
            atomic(args.output, transform(args.source.read_text(), color))
            print(str(args.output)); return
        links.root.mkdir(parents=True, exist_ok=True)
        with (links.root / '.lock').open('a') as lock:
            fcntl.flock(lock, fcntl.LOCK_EX)
            links = Links()  # re-read after acquiring the lock
            if links.state.get('kitty') or (args.action == 'disable' and args.target in ('kitty', 'all')):
                links.retire_kitty()
            if args.target == 'kitty':
                print(json.dumps(links.status())); return
            if args.action == 'sync': links.sync(color)
            else:
                targets = TARGETS if args.action == 'disable' and args.target == 'all' else (args.target,)
                if any(t not in TARGETS for t in targets): parser.error('Select starship, spaceship or fastfetch')
                for target in targets:
                    if args.action != 'disable' or links.state.get(target): links.set(target, args.action == 'enable', color)
        print(json.dumps(links.status()))
    except (ValueError, OSError, subprocess.SubprocessError) as error:
        parser.exit(1, str(error) + '\n')


if __name__ == '__main__':
    main()

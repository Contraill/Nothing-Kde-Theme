#!/usr/bin/env python3
"""Build complete KPackage archives; optionally resolve real KDE Store IDs."""
import argparse
import hashlib
import json
from pathlib import Path
import shutil
import tarfile
import tempfile
import zipfile
import importlib.util

ROOT = Path(__file__).resolve().parents[1]
VERSION = '0.6.0-rc35'


def archive(source, target):
    with zipfile.ZipFile(target, 'w', zipfile.ZIP_DEFLATED) as package:
        for path in sorted(source.rglob('*')):
            if path.is_file():
                package.write(path, path.relative_to(source))


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--store-ids', type=Path, help='JSON mapping component names to their published KDE Store numbers')
    parser.add_argument('--output', type=Path, default=ROOT / 'dist', help='Package output directory')
    parser.add_argument('--notification-package', type=Path, required=True, help=argparse.SUPPRESS)
    args = parser.parse_args()
    ids = json.loads(args.store_ids.read_text()) if args.store_ids else {}
    required = ('panel', 'launcher', 'notifications', 'style-dark', 'style-light', 'colors-dark', 'colors-light')
    if args.store_ids and any(not str(ids.get(key, '')).isdigit() for key in required):
        parser.error('Every component in store-ids.example.json needs a real numeric KDE Store ID')
    dist = args.output.resolve()
    if dist == ROOT or dist in ROOT.parents:
        parser.error('Output must be a dedicated directory, not the source root or its parent')
    if dist.is_relative_to(ROOT) and dist != ROOT / 'dist':
        parser.error('Use dist/ or an external output directory; source folders are not build targets')
    dist.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix='nothing-store-') as td:
        stage = Path(td)
        def copy(source, name):
            target = stage / name
            shutil.copytree(source, target)
            shutil.copytree(ROOT / 'LICENSES', target / 'LICENSES', dirs_exist_ok=True)
            metadata = target / 'metadata.json'
            data = json.loads(metadata.read_text())
            data['KPlugin']['Version'] = VERSION
            metadata.write_text(json.dumps(data, indent=2) + '\n')
            return target

        panel = copy(ROOT / 'plasmoids/com.nothingplasma.panel', 'panel')
        helpers = panel / 'contents/tools'
        helpers.mkdir()
        for name in ('nothing-control.sh', 'wifi.py', 'privacy.py', 'accent-links.py', 'kitty-theme.py', 'jsonc_edit.py', 'appearance.py', 'appearance_render.py', 'glassy_settings.py'):
            shutil.copy2(ROOT / 'runtime' / name, helpers / name)
        walls = panel / 'contents/wallpapers'
        walls.mkdir()
        for mode in ('dark', 'light'):
            shutil.copy2(ROOT / 'wallpapers' / mode / 'wallpaper.jpeg', walls / (mode + '.jpeg'))
        archive(panel, dist / f'Nothing-KDE-Island-Dock-{VERSION}.plasmoid')
        launcher = copy(ROOT / 'plasmoids/com.nothingplasma.launcherbridge', 'launcher')
        archive(launcher, dist / f'Nothing-KDE-Launcher-Bridge-{VERSION}.plasmoid')
        notifications = copy(args.notification_package, 'notifications')
        archive(notifications, dist / f'Nothing-KDE-Notifications-Plasma-6.7.4-{VERSION}.plasmoid')
        layout = copy(ROOT / 'plasma/layout-templates/com.nothingplasma.island.panel', 'layout')
        archive(layout, dist / f'Nothing-KDE-Island-Dock-Layout-{VERSION}.plasmalayout')
        decoration = copy(ROOT / 'plasma/aurorae/org.glassy.decoration', 'decoration')
        spec = importlib.util.spec_from_file_location('glassy_decoration_build', ROOT / 'plasma/aurorae/build.py')
        builder = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(builder)
        for name, data in builder.assets(decoration).items():
            path = decoration / name
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(data)
        archive(decoration, dist / f'Glassy-Decoration-{VERSION}.kwindecoration')

        for widget in sorted((ROOT / 'widgets/packages').iterdir()):
            spec = importlib.util.spec_from_file_location('widget_prepare', ROOT / 'widgets/prepare.py')
            builder = importlib.util.module_from_spec(spec)
            spec.loader.exec_module(builder)
            staged = builder.prepare(widget, Path(td) / ('widget-' + widget.name))
            archive(staged, dist / f'Nothing-KDE-Widget-{widget.name}-{VERSION}.plasmoid')

        for mode in ('dark', 'light'):
            title = mode.title()
            style = copy(ROOT / 'plasma/desktoptheme' / ('NothingPlasma' + title), 'style-' + mode)
            metadata = style / 'metadata.json'
            data = json.loads(metadata.read_text())
            data['KPackageStructure'] = 'Plasma/Theme'
            metadata.write_text(json.dumps(data, indent=2) + '\n')
            with tarfile.open(dist / f'Nothing-KDE-Style-{title}-{VERSION}.tar.gz', 'w:gz') as package:
                package.add(style, arcname='NothingPlasma' + title)
            shutil.copy2(ROOT / 'color-schemes' / f'NothingPlasma{title}.colors', dist)
            theme = copy(ROOT / 'plasma/look-and-feel' / ('com.nothingplasma.' + mode), 'theme-' + mode)
            if ids:
                data = json.loads((theme / 'metadata.json').read_text())
                deps = [(key, 'plasmoids.knsrc') for key in ('panel', 'launcher', 'notifications')]
                deps += [('style-' + mode, 'plasma-themes.knsrc'), ('colors-' + mode, 'colorschemes.knsrc')]
                data['X-KPackage-Dependencies'] = [f'kns://{knsrc}/api.kde-look.org/{ids[key]}' for key, knsrc in deps]
                (theme / 'metadata.json').write_text(json.dumps(data, indent=2) + '\n')
            archive(theme, dist / f'Nothing-KDE-{title}-{VERSION}.lookandfeel')
    # Keep verified upstream sources in the source release: installation must
    # work offline. Build outputs and desktop captures are never shipped.
    sources = [path for path in sorted(ROOT.rglob('*')) if path.is_file()
               and not path.is_relative_to(dist)
               and not any(part in ('dist', 'build', '__pycache__', '.git') for part in path.relative_to(ROOT).parts)
               and path.suffix not in ('.pyc', '.po', '.log', '.bak')
               and path.name != 'store-ids.json']
    with tarfile.open(dist / f'Nothing-KDE-{VERSION}.tar.gz', 'w:gz') as package:
        for path in sources:
            package.add(path, arcname=str(Path('nothing-kde') / path.relative_to(ROOT)))
    with zipfile.ZipFile(dist / f'Nothing-KDE-{VERSION}.zip', 'w', zipfile.ZIP_DEFLATED) as package:
        for path in sources:
            package.write(path, Path('nothing-kde') / path.relative_to(ROOT))
    artifacts = sorted(path for path in dist.iterdir() if path.is_file() and (VERSION in path.name or path.suffix == '.colors'))
    (dist / 'SHA256SUMS').write_text(''.join(hashlib.sha256(path.read_bytes()).hexdigest() + '  ' + path.name + '\n' for path in artifacts))
    print('Store component archives built, including notification QML, panel helpers, wallpapers and licenses.')
    print('Output:', dist)
    print('Global theme dependencies: ' + ('resolved from supplied Store IDs.' if ids else 'PENDING — publish components, then rerun with --store-ids.'))


if __name__ == '__main__':
    main()

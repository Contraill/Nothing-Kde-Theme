#!/usr/bin/env python3
"""Opt-in Plasma Login Manager wallpaper; leave user and distro config intact."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import shutil
import tempfile

ROOT = Path(__file__).resolve().parents[1]
ASSETS = Path('usr/local/share/nothing-kde/login-wallpaper')
CONFIG = Path('etc/plasmalogin.conf.d/90-nothing-kde-wallpaper.conf')
NAMES = ('dark.jpeg', 'light.jpeg')


def digest(data):
    return hashlib.sha256(data).hexdigest()


def atomic_write(path, data):
    path.parent.mkdir(parents=True, exist_ok=True)
    fd, tmp = tempfile.mkstemp(prefix='.nothing-', dir=path.parent)
    try:
        with os.fdopen(fd, 'wb') as stream:
            stream.write(data)
        os.chmod(tmp, 0o644)
        os.replace(tmp, path)
    finally:
        Path(tmp).unlink(missing_ok=True)


def managed_files(root):
    return [root / CONFIG, *(root / ASSETS / name for name in NAMES)]


def check_owned(root):
    folder = root / ASSETS
    manifest = folder / 'ownership.json'
    files = managed_files(root)
    if folder.is_symlink() or manifest.is_symlink():
        raise RuntimeError('Login wallpaper ownership path is a symlink; preserving it.')
    if not manifest.exists():
        if folder.exists() or any(p.exists() or p.is_symlink() for p in files):
            raise RuntimeError('Existing unmanaged Nothing login files; refusing to overwrite.')
        return False
    saved = json.loads(manifest.read_text())
    if set(p.name for p in folder.iterdir()) != {*NAMES, 'ownership.json'}:
        raise RuntimeError('Login wallpaper directory was modified; preserving it.')
    for path in files:
        if path.is_symlink() or not path.is_file() or digest(path.read_bytes()) != saved.get(str(path.relative_to(root))):
            raise RuntimeError(f'Login file was modified; preserving {path}')
    return True


def install(mode, root=Path('/'), source=ROOT / 'wallpapers'):
    owned = check_owned(root)
    files = managed_files(root)
    content = (f'# Managed by Nothing KDE; remove with install.sh --login-wallpaper remove\n'
               f'[Greeter]\nWallpaperPluginId=org.kde.image\n\n'
               f'[Greeter][Wallpaper][org.kde.image][General]\n'
               f'Image=file:///{ASSETS}/{mode}.jpeg\nPreviewImage=null\n').encode()
    values = [content, *((source / Path(name).stem / 'wallpaper.jpeg').read_bytes() for name in NAMES)]
    manifest = root / ASSETS / 'ownership.json'
    old = {p: p.read_bytes() if p.exists() else None for p in [*files, manifest]}
    if owned and all(old[p] == data for p, data in zip(files, values)):
        return
    try:
        # Publish image files before selecting them in the greeter configuration.
        for path, data in [*zip(files[1:], values[1:]), (files[0], values[0])]:
            atomic_write(path, data)
        atomic_write(manifest, json.dumps({str(p.relative_to(root)): digest(data) for p, data in zip(files, values)}, indent=2).encode())
    except Exception:
        for path, data in old.items():
            if data is None:
                path.unlink(missing_ok=True)
            else:
                atomic_write(path, data)
        if not owned and (root / ASSETS).exists():
            (root / ASSETS).rmdir()
        raise


def remove(root=Path('/')):
    if not check_owned(root):
        return
    (root / CONFIG).unlink()
    shutil.rmtree(root / ASSETS)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('action', choices=('dark', 'light', 'remove'))
    args = parser.parse_args()
    if os.geteuid() != 0:
        parser.error('Administrator access required: use pkexec /usr/bin/python3 -I runtime/login-wallpaper.py ' + args.action)
    if args.action != 'remove' and not Path('/usr/bin/plasmalogin').exists():
        parser.error('This integration requires Plasma Login Manager (not SDDM).')
    try:
        remove() if args.action == 'remove' else install(args.action)
    except (OSError, ValueError, RuntimeError) as error:
        parser.exit(1, str(error) + '\n')
    print('Login wallpaper configuration updated. Existing sessions were not restarted.')


if __name__ == '__main__':
    main()

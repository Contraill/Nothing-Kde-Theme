#!/usr/bin/env python3
"""Nothing KDE boot animation: a Plymouth "two-step" theme in the KDE accent.

The same ring of dots as the Plasma splash: a comet in the accent circles
while the system boots, then the ring fills and fades. Frames are drawn here
with Pillow, so no image in the theme comes from elsewhere.

  bootsplash.py preview DIR [RRGGBB]     draw the theme into DIR (no root)
  pkexec .../bootsplash.py setup RRGGBB  install theme, helper and polkit rule, make it the default
  nothing-kde-boot accent RRGGBB         redraw in a new accent and rebuild the initramfs
                                         (allowed without a password for the active session)
  pkexec nothing-kde-boot remove         restore the previous theme and remove everything

The initramfs carries the theme, so an accent change rebuilds it with the
distribution's own tool (plymouth-set-default-theme -R), debounced and in
the background.
"""
import fcntl
import math
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import tempfile
import time

NAME = 'nothing-kde'
THEMES = Path('/usr/share/plymouth/themes')
THEME = THEMES / NAME
HELPER = Path('/usr/local/libexec/nothing-kde-boot')
RULE = Path('/etc/polkit-1/rules.d/49-nothing-kde-boot.rules')
STATE = Path('/var/lib/nothing-kde-boot')

SIZE, RING, DOTS = 240, 92, 24
DOT = 9.0
THROBBER_FRAMES, END_FRAMES = 48, 20


def rgb(hex_color):
    if not re.fullmatch(r'[0-9A-Fa-f]{6}', hex_color or ''):
        raise SystemExit('accent must be RRGGBB')
    return tuple(int(hex_color[i:i + 2], 16) for i in (0, 2, 4))


def ring_frame(accent, head=None, lit=0.0, fade=1.0, grow=1.0):
    """One frame: base dots, an optional comet whose head is at `head` (in
    dots, fractional), `lit` share of dots filled, scaled by fade and grow."""
    from PIL import Image, ImageDraw
    scale = 3  # draw large, then downsample for smooth dots
    canvas = Image.new('RGBA', (SIZE * scale, SIZE * scale), (0, 0, 0, 0))
    draw = ImageDraw.Draw(canvas)
    centre = SIZE * scale / 2
    for index in range(DOTS):
        angle = 2 * math.pi * index / DOTS - math.pi / 2
        x = centre + RING * grow * scale * math.cos(angle)
        y = centre + RING * grow * scale * math.sin(angle)
        level, colour, size = 0.16, (255, 255, 255), DOT
        if index < round(lit * DOTS):
            level, colour = 1.0, accent
        if head is not None:
            behind = (head - index) % DOTS
            trail = max(0.0, 1 - behind / 7)
            if behind < 1:
                level, colour, size = 1.0, accent, DOT * 1.35
            elif trail > 0:
                level, size = max(level, 0.16 + 0.8 * trail), DOT * (1 + 0.3 * trail)
        alpha = int(255 * level * fade)
        r = size * scale / 2
        draw.ellipse((x - r, y - r, x + r, y + r), fill=colour + (alpha,))
    return canvas.resize((SIZE, SIZE), Image.LANCZOS)


def small_images(directory):
    """Password prompt pieces for encrypted disks: field, bullet and lock."""
    from PIL import Image, ImageDraw
    entry = Image.new('RGBA', (300, 40), (0, 0, 0, 0))
    ImageDraw.Draw(entry).rounded_rectangle((0, 0, 299, 39), radius=20, fill=(17, 17, 17, 255), outline=(58, 58, 58, 255), width=2)
    entry.save(directory / 'entry.png')
    bullet = Image.new('RGBA', (12, 12), (0, 0, 0, 0))
    ImageDraw.Draw(bullet).ellipse((1, 1, 10, 10), fill=(255, 255, 255, 255))
    bullet.save(directory / 'bullet.png')
    # A 5x7 dot-matrix padlock.
    lock = Image.new('RGBA', (30, 42), (0, 0, 0, 0))
    draw = ImageDraw.Draw(lock)
    for row, line in enumerate(['.###.', '#...#', '#...#', '#####', '##.##', '##.##', '#####']):
        for col, cell in enumerate(line):
            if cell == '#':
                draw.ellipse((col * 6 + 1, row * 6 + 1, col * 6 + 5, row * 6 + 5), fill=(255, 255, 255, 255))
    lock.save(directory / 'lock.png')


def theme_file(directory):
    return f'''[Plymouth Theme]
Name=Nothing KDE
Description=A ring of dots in the KDE accent, from Nothing KDE
ModuleName=two-step

[two-step]
Font=Sans 12
TitleFont=Sans Light 24
ImageDir={directory}
DialogHorizontalAlignment=.5
DialogVerticalAlignment=.62
TitleHorizontalAlignment=.5
TitleVerticalAlignment=.30
HorizontalAlignment=.5
VerticalAlignment=.5
Transition=none
TransitionDuration=0.0
BackgroundStartColor=0x000000
BackgroundEndColor=0x000000
ProgressBarBackgroundColor=0x262626
ProgressBarForegroundColor=0xffffff
MessageBelowAnimation=true

[boot-up]
UseEndAnimation=true
UseFirmwareBackground=false

[shutdown]
UseEndAnimation=false
UseFirmwareBackground=false

[reboot]
UseEndAnimation=false
UseFirmwareBackground=false

[updates]
SuppressMessages=true
ProgressBarShowPercentComplete=true
UseProgressBar=true
Title=Installing updates
SubTitle=Do not turn off your computer

[system-upgrade]
SuppressMessages=true
ProgressBarShowPercentComplete=true
UseProgressBar=true
Title=Upgrading the system
SubTitle=Do not turn off your computer

[firmware-upgrade]
SuppressMessages=true
ProgressBarShowPercentComplete=true
UseProgressBar=true
Title=Upgrading firmware
SubTitle=Do not turn off your computer
'''


def draw(directory, accent_hex, image_dir=None):
    """Writes the complete theme into `directory` (created if missing)."""
    accent = rgb(accent_hex)
    directory.mkdir(parents=True, exist_ok=True)
    for index in range(THROBBER_FRAMES):
        ring_frame(accent, head=index * DOTS / THROBBER_FRAMES).save(directory / f'throbber-{index + 1:04d}.png')
    # End: the ring fills in the accent, then grows a little and fades out.
    for index in range(END_FRAMES):
        progress = index / (END_FRAMES - 1)
        fill = min(1.0, progress / 0.55)
        fade = 1.0 if progress < 0.55 else 1 - (progress - 0.55) / 0.45
        ring_frame(accent, lit=fill, fade=fade, grow=1 + 0.08 * max(0.0, progress - 0.55)).save(directory / f'animation-{index + 1:04d}.png')
    small_images(directory)
    (directory / f'{NAME}.plymouth').write_text(theme_file(image_dir or directory))
    (directory / 'accent').write_text(accent_hex.upper() + '\n')


# --- root side -------------------------------------------------------------

POLKIT = f'''// Nothing KDE: the active local session may recolour the boot animation
// ("accent RRGGBB") without a password. Every other use keeps the prompt.
polkit.addRule(function(action, subject) {{
    if (action.id === "org.freedesktop.policykit.exec" &&
        action.lookup("program") === "{HELPER}" &&
        /^\\/usr\\/local\\/libexec\\/nothing-kde-boot accent [0-9A-F]{{6}}$/.test(action.lookup("command_line")) &&
        subject.local && subject.active) {{
        return polkit.Result.YES;
    }}
}});
'''


def run(*args):
    return subprocess.run(args, capture_output=True, text=True, check=False)


def current_theme():
    return run('plymouth-set-default-theme').stdout.strip()


def install_theme(accent_hex):
    """Draws into a fresh directory next to the theme, then swaps it in."""
    staging = Path(tempfile.mkdtemp(prefix='.nothing-kde-', dir=THEMES))
    try:
        draw(staging, accent_hex, THEME)
        os.chmod(staging, 0o755)
        old = THEME.with_name('.' + NAME + '.old')
        shutil.rmtree(old, ignore_errors=True)
        if THEME.exists():
            THEME.rename(old)
        staging.rename(THEME)
        shutil.rmtree(old, ignore_errors=True)
    finally:
        shutil.rmtree(staging, ignore_errors=True)


def rebuild_later(accent_hex):
    """Debounced initramfs rebuild: only the newest accent request rebuilds."""
    STATE.mkdir(parents=True, exist_ok=True)
    request = STATE / 'pending'
    request.write_text(accent_hex)
    if os.fork():
        return
    os.setsid()
    # Let pkexec and the caller finish; this child outlives them.
    null = os.open(os.devnull, os.O_RDWR)
    for fd in (0, 1, 2):
        os.dup2(null, fd)
    time.sleep(4)
    with (STATE / 'rebuild.lock').open('w') as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)
        if request.exists() and request.read_text() == accent_hex:
            request.unlink()
            if current_theme() == NAME:
                log = (STATE / 'rebuild.log').open('w')
                subprocess.run(['nice', '-n', '10', 'plymouth-set-default-theme', '-R', NAME], stdout=log, stderr=log, check=False)
    os._exit(0)


def setup(accent_hex):
    rgb(accent_hex)
    STATE.mkdir(parents=True, exist_ok=True)
    previous = current_theme()
    if previous and previous != NAME:
        (STATE / 'previous').write_text(previous)
    install_theme(accent_hex)
    HELPER.parent.mkdir(parents=True, exist_ok=True)
    source = Path(__file__).read_text().split('\n', 1)[1]
    with tempfile.NamedTemporaryFile('w', dir=HELPER.parent, delete=False) as file:
        file.write('#!/usr/bin/python3 -I\n' + source)
    os.chmod(file.name, 0o755)
    os.replace(file.name, HELPER)
    RULE.write_text(POLKIT)
    os.chmod(RULE, 0o644)
    result = run('plymouth-set-default-theme', '-R', NAME)
    print(result.stdout + result.stderr)
    print('Nothing KDE boot animation installed; it follows the accent from now on.')


def remove():
    previous = (STATE / 'previous').read_text().strip() if (STATE / 'previous').exists() else ''
    if current_theme() == NAME:
        result = run('plymouth-set-default-theme', '-R', previous or 'bgrt')
        print(result.stdout + result.stderr)
    shutil.rmtree(THEME, ignore_errors=True)
    for path in (RULE, HELPER):
        path.unlink(missing_ok=True)
    shutil.rmtree(STATE, ignore_errors=True)
    print('Nothing KDE boot animation removed.')


def main():
    args = sys.argv[1:]
    if args[:1] == ['preview'] and len(args) in (2, 3):
        draw(Path(args[1]), args[2] if len(args) == 3 else 'D71921')
        return
    if os.geteuid() != 0:
        raise SystemExit(__doc__)
    if args[:1] == ['setup'] and len(args) == 2:
        setup(args[1])
    elif args[:1] == ['accent'] and len(args) == 2:
        accent = args[1].upper()
        rgb(accent)
        if not THEME.exists():
            raise SystemExit('Nothing KDE boot animation is not installed')
        if (THEME / 'accent').read_text().strip() != accent:
            install_theme(accent)
            rebuild_later(accent)
    elif args == ['remove']:
        remove()
    else:
        raise SystemExit(__doc__)


if __name__ == '__main__':
    main()

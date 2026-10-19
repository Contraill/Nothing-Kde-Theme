#!/usr/bin/env python3
"""Dot-matrix sprite sheets for the Pet widget, from EveryThing-UI's frames.

  build-pets.py IMAGES_DIR OUTPUT_DIR

IMAGES_DIR is EveryThing-UI's @Resources/Images (Prince-1652, MIT), holding
cat/, dog/, hamster/ and robo/ with frame00000.png … frame00238.png. Each pet
is cropped to the area its frames use, averaged down to a grid of dots and
drawn as round dots in a shared palette, every third frame, into one sheet
of FRAMES frames (COLUMNS per row) plus a small JSON description.
"""
import json
from pathlib import Path
import sys

from PIL import Image, ImageDraw

PETS = ('cat', 'dog', 'hamster', 'robo')
GRID_WIDTH = 46          # dots across; the height follows the pet's shape
PITCH = 5                # pixels per dot in the sheet
DOT = 0.84               # dot diameter as a share of the pitch
STEP = 3                 # every third source frame (30 fps -> 10 fps)
COLUMNS = 8              # 8 x 230 px: the sheet stays within a 2048 px texture
ALPHA = 110              # a cell with less coverage stays empty
COLOURS = 16             # palette size per pet
SUPERSAMPLE = 4


def frame_paths(directory):
    return sorted(directory.glob('frame*.png'))[::STEP]


def crop_box(paths):
    box = None
    for path in paths:
        b = Image.open(path).getbbox()
        if b:
            box = b if box is None else (min(box[0], b[0]), min(box[1], b[1]), max(box[2], b[2]), max(box[3], b[3]))
    return box


def build(images, output, pet):
    paths = frame_paths(images / pet)
    box = crop_box(paths)
    width = GRID_WIDTH
    height = round(GRID_WIDTH * (box[3] - box[1]) / (box[2] - box[0]))
    cells = [Image.open(p).convert('RGBA').crop(box).resize((width, height), Image.BOX) for p in paths]
    # One palette for every frame, so colours do not flicker between frames.
    strip = Image.new('RGB', (width, height * len(cells)))
    for i, c in enumerate(cells):
        strip.paste(c.convert('RGB'), (0, i * height))
    palette = strip.quantize(COLOURS, method=Image.Quantize.MEDIANCUT)
    rows = (len(cells) + COLUMNS - 1) // COLUMNS
    fw, fh = width * PITCH, height * PITCH
    big = Image.new('RGBA', (COLUMNS * fw * SUPERSAMPLE, rows * fh * SUPERSAMPLE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(big)
    r = PITCH * DOT * SUPERSAMPLE / 2
    for i, c in enumerate(cells):
        ox, oy = (i % COLUMNS) * fw * SUPERSAMPLE, (i // COLUMNS) * fh * SUPERSAMPLE
        mapped = c.convert('RGB').quantize(palette=palette).convert('RGB').load()
        alpha = c.getchannel('A').load()
        for y in range(height):
            for x in range(width):
                if alpha[x, y] < ALPHA:
                    continue
                cx = ox + (x + 0.5) * PITCH * SUPERSAMPLE
                cy = oy + (y + 0.5) * PITCH * SUPERSAMPLE
                draw.ellipse((cx - r, cy - r, cx + r, cy + r), fill=mapped[x, y] + (255,))
    sheet = big.resize((COLUMNS * fw, rows * fh), Image.LANCZOS)
    # A palette image keeps the sheet small; 128 entries cover the dot edges.
    sheet.quantize(128, method=Image.Quantize.FASTOCTREE).save(output / f'{pet}.png', optimize=True)
    source = Image.open(paths[0]).size
    # Where the cropped area sits in the original frame, as shares of its size.
    place = [round(box[0] / source[0], 4), round(box[1] / source[1], 4),
             round((box[2] - box[0]) / source[0], 4), round((box[3] - box[1]) / source[1], 4)]
    return {'frames': len(cells), 'frameWidth': fw, 'frameHeight': fh, 'columns': COLUMNS,
            'frameDuration': round(1000 * STEP / 30), 'place': place}


def main():
    if len(sys.argv) != 3:
        raise SystemExit(__doc__)
    images, output = Path(sys.argv[1]), Path(sys.argv[2])
    output.mkdir(parents=True, exist_ok=True)
    info = {pet: build(images, output, pet) for pet in PETS}
    (output / 'sprites.json').write_text(json.dumps(info, indent=2) + '\n')
    print(json.dumps(info))


if __name__ == '__main__':
    main()

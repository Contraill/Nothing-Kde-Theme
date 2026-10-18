#!/usr/bin/env python3
"""Synthesise the "Nothing KDE" sound theme: short, clean digital dots.

Every sound is generated here from sine partials, so the theme is original
work under the project's licence. Needs numpy and ffmpeg (libvorbis):

  python3 assets/sounds/build-sounds.py            # writes assets/sounds/nothing-kde
"""
from pathlib import Path
import subprocess
import numpy as np

RATE = 48000
OUT = Path(__file__).resolve().parent / 'nothing-kde'

# Equal-tempered note frequencies used below.
NOTE = {name: 440 * 2 ** ((index - 9 + 12 * (octave - 4)) / 12)
        for octave in range(3, 9)
        for index, name in enumerate(n + str(octave) for n in
                                     ('C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'))}


def dot(freq, length=0.09, gain=1.0, attack=0.003, glass=True):
    """One dot: a sine with soft harmonics, a fast attack and an exponential tail.
    A faint inharmonic partial (2.76x, like a struck glass) gives it its shine."""
    t = np.arange(int(RATE * length)) / RATE
    wave = np.sin(2 * np.pi * freq * t) + 0.22 * np.sin(4 * np.pi * freq * t) + 0.06 * np.sin(6 * np.pi * freq * t)
    if glass:
        wave += 0.07 * np.sin(2 * np.pi * freq * 2.76 * t) * np.exp(-t / (length / 6))
    envelope = (1 - np.exp(-t / attack)) * np.exp(-t / (length / 3.2))
    return gain * wave * envelope


def glide(start, end, length, gain=0.8):
    """A short sweep for plug, send and question sounds."""
    t = np.arange(int(RATE * length)) / RATE
    freq = start * (end / start) ** (t / length)
    phase = 2 * np.pi * np.cumsum(freq) / RATE
    envelope = (1 - np.exp(-t / 0.006)) * np.exp(-t / (length / 2.2))
    return gain * (np.sin(phase) + 0.18 * np.sin(2 * phase)) * envelope


def swoosh(length=0.32, gain=0.5, seed=7):
    """Filtered noise for emptying the trash."""
    rng = np.random.default_rng(seed)
    noise = rng.standard_normal(int(RATE * length))
    t = np.arange(noise.size) / RATE
    # One-pole low-pass whose cut-off falls over time: a soft "shh".
    out, state = np.empty_like(noise), 0.0
    alpha = 0.35 * np.exp(-t / (length / 2)) + 0.03
    for i, sample in enumerate(noise):
        state += alpha[i] * (sample - state)
        out[i] = state
    envelope = np.sin(np.pi * np.clip(t / length, 0, 1)) ** 1.5
    return gain * out * envelope


def chord(freqs, length, gain=0.6):
    """A held chord that swells and fades (battery full, login)."""
    t = np.arange(int(RATE * length)) / RATE
    wave = sum(np.sin(2 * np.pi * f * t) + 0.15 * np.sin(4 * np.pi * f * t) for f in freqs) / len(freqs)
    envelope = np.minimum(1, t / (length * 0.25)) * np.exp(-np.maximum(0, t - length * 0.25) / (length / 3))
    return gain * wave * envelope


def place(parts, tail=0.25):
    """Mixes (start time, sound) pairs into one buffer with a short echo tail."""
    end = max(start + len(sound) / RATE for start, sound in parts) + tail
    mix = np.zeros(int(RATE * end) + 1)
    for start, sound in parts:
        offset = int(RATE * start)
        mix[offset:offset + len(sound)] += sound
    # A few feed-forward echoes: a small, glassy room.
    out = mix.copy()
    for delay, amount in ((0.031, 0.22), (0.047, 0.14), (0.071, 0.08), (0.113, 0.04)):
        shift = int(RATE * delay)
        out[shift:] += amount * mix[:-shift]
    return out


def dots(notes, step=0.075, length=0.11, gain=1.0):
    return place([(i * step, dot(NOTE[n] if isinstance(n, str) else n, length, gain)) for i, n in enumerate(notes)])


SOUNDS = {
    # Notifications and messages
    'message-new-instant': lambda: dots(['B5', 'E6', 'B6'], 0.06, 0.1, 0.8),
    'message-new-email': lambda: dots(['G6', 'G6', 'D7'], 0.085, 0.09, 0.8),
    'message-sent-instant': lambda: place([(0, glide(900, 1800, 0.12, 0.6))], 0.15),
    'message-attention': lambda: dots(['D6', 'D6'], 0.11, 0.1),
    'message-highlight': lambda: dots(['F#6', 'B6'], 0.07, 0.1, 0.8),
    'message-contact-in': lambda: dots(['E6', 'A6'], 0.07, 0.09, 0.7),
    'message-contact-out': lambda: dots(['A6', 'E6'], 0.07, 0.09, 0.7),
    'dialog-information': lambda: dots(['E6', 'B6'], 0.07, 0.11, 0.8),
    'dialog-question': lambda: place([(0, dot(NOTE['C6'], 0.08, 0.7)), (0.08, glide(1046, 1480, 0.14, 0.6))]),
    'dialog-warning': lambda: dots(['A5', 'A5'], 0.12, 0.12),
    'dialog-warning-auth': lambda: dots(['D6', 'A5'], 0.1, 0.12),
    'dialog-error': lambda: dots(['E5', 'C5'], 0.11, 0.14),
    'dialog-error-serious': lambda: dots(['E5', 'C5', 'A4'], 0.1, 0.14),
    'dialog-error-critical': lambda: dots(['A3', 'A3', 'A3'], 0.13, 0.12, 1.0),
    'bell': lambda: place([(0, dot(NOTE['G6'], 0.1))], 0.18),
    'bell-window-system': lambda: place([(0, dot(NOTE['E6'], 0.08, 0.7))], 0.15),
    # Devices and power
    'device-added': lambda: dots(['C6', 'E6', 'G6'], 0.06, 0.1),
    'device-removed': lambda: dots(['G6', 'E6', 'C6'], 0.06, 0.1),
    'power-plug': lambda: place([(0, glide(600, 1250, 0.16, 0.55)), (0.15, dot(NOTE['G6'], 0.1, 0.8))]),
    'power-unplug': lambda: place([(0, glide(1250, 600, 0.16, 0.55)), (0.15, dot(NOTE['C5'], 0.12, 0.8))]),
    'battery-low': lambda: dots(['A5', 'E5'], 0.16, 0.15),
    'battery-caution': lambda: dots(['A5', 'E5', 'A5', 'E5'], 0.15, 0.13),
    'battery-full': lambda: place([(0, chord([NOTE['C6'], NOTE['E6'], NOTE['G6']], 0.6))], 0.2),
    # Outcomes
    'completion-success': lambda: dots(['C6', 'G6', 'C7'], 0.07, 0.12),
    'outcome-success': lambda: dots(['C6', 'G6', 'C7'], 0.07, 0.12),
    'complete-media-burn': lambda: dots(['C6', 'G6', 'C7'], 0.07, 0.12),
    'completion-partial': lambda: dots(['C6', 'G6'], 0.08, 0.12),
    'completion-fail': lambda: dots(['G5', 'D#5'], 0.1, 0.14),
    'outcome-failure': lambda: dots(['G5', 'D#5'], 0.1, 0.14),
    'complete-media-error': lambda: dots(['G5', 'D#5'], 0.1, 0.14),
    'completion-rotation': lambda: dots(['B6', 'B6'], 0.05, 0.05, 0.5),
    'media-insert-request': lambda: place([(0, dot(NOTE['C6'], 0.08, 0.7)), (0.08, glide(1046, 1480, 0.14, 0.6))]),
    'trash-empty': lambda: place([(0, swoosh()), (0.28, dot(NOTE['C7'], 0.05, 0.4))]),
    # Session
    'desktop-login': lambda: place([(i * 0.11, dot(NOTE[n], 0.5, 0.7)) for i, n in enumerate(['C5', 'E5', 'G5', 'B5', 'D6'])]
                                   + [(0.5, chord([NOTE['C5'], NOTE['G5'], NOTE['D6']], 1.1, 0.35))], 0.4),
    'desktop-logout': lambda: place([(i * 0.12, dot(NOTE[n], 0.45, 0.65)) for i, n in enumerate(['D6', 'B5', 'G5', 'E5', 'C5'])], 0.4),
    'service-login': lambda: dots(['G5', 'D6'], 0.07, 0.12, 0.7),
    'service-logout': lambda: dots(['D6', 'G5'], 0.07, 0.12, 0.7),
    # Interaction
    'audio-volume-change': lambda: place([(0, dot(NOTE['A6'], 0.04, 0.45, glass=False))], 0.06),
    'button-pressed': lambda: place([(0, dot(2400, 0.025, 0.35, 0.001, False))], 0.04),
    'button-pressed-modifier': lambda: place([(0, dot(1900, 0.025, 0.35, 0.001, False))], 0.04),
    # Timers and calls
    'alarm-clock-elapsed': lambda: place([(r * 0.62 + i * 0.09, dot(NOTE['A6'], 0.08, 0.9))
                                          for r in range(3) for i in range(4)], 0.3),
    'phone-incoming-call': lambda: place([(r * 0.9 + i * 0.07, dot(NOTE['E6' if i % 2 else 'B6'], 0.08, 0.8))
                                          for r in range(3) for i in range(6)], 0.3),
    'theme-demo': lambda: dots(['C6', 'E6', 'G6', 'B6', 'G6', 'E6', 'C7'], 0.12, 0.2, 0.8),
}


def write(name, signal):
    peak = np.max(np.abs(signal)) or 1
    # Full-scale peaks at -3 dBFS; the volume tick is deliberately quieter.
    level = 0.5 if name in ('audio-volume-change', 'button-pressed', 'button-pressed-modifier') else 0.708
    mono = signal / peak * level
    fade = np.minimum(1, np.arange(mono.size)[::-1] / (RATE * 0.004))  # no click at the end
    mono *= fade
    right = np.concatenate([np.zeros(int(RATE * 0.0004)), mono])[:mono.size]  # slight width
    pcm = (np.stack([mono, right], axis=1) * 32767).astype('<i2').tobytes()
    target = OUT / 'stereo' / (name + '.oga')
    subprocess.run(['ffmpeg', '-loglevel', 'error', '-y', '-f', 's16le', '-ar', str(RATE), '-ac', '2', '-i', '-',
                    '-c:a', 'libvorbis', '-q:a', '5', '-map_metadata', '-1', '-fflags', '+bitexact',
                    '-flags:a', '+bitexact', str(target)], input=pcm, check=True)


INDEX = '''[Sound Theme]
Name=Nothing KDE
Name[tr]=Nothing KDE
Comment=Clean digital dots for Nothing KDE; generated by assets/sounds/build-sounds.py
Comment[tr]=Nothing KDE için temiz dijital noktalar; assets/sounds/build-sounds.py ile üretilir
Inherits=freedesktop
Directories=stereo
Example=theme-demo

[stereo]
OutputProfile=stereo
'''


def main():
    (OUT / 'stereo').mkdir(parents=True, exist_ok=True)
    (OUT / 'index.theme').write_text(INDEX)
    for name, build in SOUNDS.items():
        write(name, build())
    print('wrote', len(SOUNDS), 'sounds to', OUT)


if __name__ == '__main__':
    main()

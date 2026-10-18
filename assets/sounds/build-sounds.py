#!/usr/bin/env python3
"""Synthesise the "Nothing KDE" sound theme.

Inspired by Plasma's Ocean theme (none of its audio is used): warm tones in
the low and middle register, soft swelling attacks, gentle mallet partials
over a sine body, and a real room reverb. Every sound is generated here, so
the theme is original work under the project's licence. Needs numpy and
ffmpeg (libvorbis):

  python3 assets/sounds/build-sounds.py            # writes assets/sounds/nothing-kde
"""
from pathlib import Path
import subprocess
import numpy as np

RATE = 48000
OUT = Path(__file__).resolve().parent / 'nothing-kde'

NOTE = {name: 440 * 2 ** ((index - 9 + 12 * (octave - 4)) / 12)
        for octave in range(2, 8)
        for index, name in enumerate(n + str(octave) for n in
                                     ('C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'))}


def seconds(length):
    return np.arange(int(RATE * length)) / RATE


def envelope(t, attack, decay):
    """Raised-cosine swell, then an exponential fade: soft, never a click."""
    rise = np.where(t < attack, 0.5 - 0.5 * np.cos(np.pi * np.clip(t / attack, 0, 1)), 1.0)
    return rise * np.exp(-np.maximum(0, t - attack) / decay)


def tone(note, length=1.2, attack=0.06, decay=0.3, gain=1.0, mallet=0.1):
    """A warm struck tone: sine body, a soft octave, and a quickly fading
    marimba-like partial (3.93x) that gives the attack its shape."""
    f = NOTE[note] if isinstance(note, str) else note
    t = seconds(length)
    body = np.sin(2 * np.pi * f * t) + 0.18 * np.sin(4 * np.pi * f * t) * np.exp(-t / (decay * 0.6))
    strike = mallet * np.sin(2 * np.pi * f * 3.93 * t) * np.exp(-t / 0.03)
    # A slow two-cent drift keeps long tails from sounding synthetic.
    body *= 1 + 0.004 * np.sin(2 * np.pi * 0.9 * t)
    return gain * (body + strike) * envelope(t, attack, decay)


def pad(notes, length=1.6, attack=0.35, decay=0.7, gain=0.5):
    """Held chord of slightly detuned sines that swells in and fades."""
    t = seconds(length)
    wave = np.zeros_like(t)
    for note in notes:
        f = NOTE[note] if isinstance(note, str) else note
        for cents in (-4, 4):
            wave += np.sin(2 * np.pi * f * 2 ** (cents / 1200) * t)
    return gain * wave / (2 * len(notes)) * envelope(t, attack, decay)


def glide(start, end, length=0.5, attack=0.08, decay=0.22, gain=0.6):
    """A soft sweep for plugging in, sending and asking."""
    t = seconds(length)
    freq = start * (end / start) ** np.minimum(1, t / (length * 0.6))
    phase = 2 * np.pi * np.cumsum(freq) / RATE
    return gain * (np.sin(phase) + 0.12 * np.sin(2 * phase)) * envelope(t, attack, decay)


def breath(length=0.8, gain=0.35, seed=11):
    """Low-passed noise that rises and settles: emptying the trash."""
    rng = np.random.default_rng(seed)
    noise = rng.standard_normal(int(RATE * length))
    # Two one-pole low-pass stages, cut-off around 600 Hz.
    alpha = 1 - np.exp(-2 * np.pi * 600 / RATE)
    for _ in range(2):
        out, state = np.empty_like(noise), 0.0
        for i, sample in enumerate(noise):
            state += alpha * (sample - state)
            out[i] = state
        noise = out
    t = seconds(length)
    return gain * noise / np.max(np.abs(noise)) * np.sin(np.pi * t / length) ** 2


def comb(x, delay, feedback, damping, taps=12):
    """Feedback comb with a damped loop: y[n] = x[n] + feedback * lowpass(y)[n - delay].
    The loop's one-pole low-pass is a short FIR (damping^k dies out within a
    dozen samples), so each delay-length block depends only on earlier ones."""
    weights = (1 - damping) * damping ** np.arange(taps)
    y = np.concatenate([np.zeros(delay + taps), x])
    for start in range(delay + taps, len(y), delay):
        end = min(start + delay, len(y))
        source = start - delay
        filtered = sum(w * y[source - k:source - k + end - start] for k, w in enumerate(weights))
        y[start:end] += feedback * filtered
    return y[delay + taps:]


def allpass(x, delay, gain=0.5):
    y = np.zeros_like(x)
    buffer = np.zeros(len(x) + delay)
    buffer[:len(x)] = x
    for start in range(0, len(x), delay):
        end = min(start + delay, len(x))
        past = y[start - delay:end - delay] if start >= delay else np.zeros(end - start)
        past_in = x[start - delay:end - delay] if start >= delay else np.zeros(end - start)
        y[start:end] = -gain * x[start:end] + past_in + gain * past
    return y


def reverb(x, room=0.74, wet=0.28, tail=0.8):
    """Freeverb-style room: parallel damped combs, then series all-passes."""
    padded = np.concatenate([x, np.zeros(int(RATE * tail))])
    combs = sum(comb(padded, int(RATE * ms / 1000), room, 0.25) for ms in (29.7, 33.1, 37.9, 41.1, 43.7, 47.3))
    diffused = combs / 6
    for ms in (5.0, 1.7):
        diffused = allpass(diffused, int(RATE * ms / 1000))
    return (1 - wet) * padded + wet * diffused


def place(parts, wet=0.3, tail=0.9):
    """Mixes (start time, sound) pairs and puts them in the room."""
    end = max(start + len(sound) / RATE for start, sound in parts)
    mix = np.zeros(int(RATE * end) + 1)
    for start, sound in parts:
        offset = int(RATE * start)
        mix[offset:offset + len(sound)] += sound
    return reverb(mix, wet=wet, tail=tail)


def notes(sequence, step=0.12, length=1.1, decay=0.3, gain=1.0, attack=0.06):
    return place([(i * step, tone(n, length, attack, decay, gain)) for i, n in enumerate(sequence)])


SOUNDS = {
    # Messages and notices: two or three soft notes, the second one higher.
    'message-new-instant': lambda: notes(['G4', 'D5'], 0.13, 1.2, 0.38),
    'message-new-email': lambda: notes(['C5', 'E5', 'G5'], 0.11, 1.1, 0.34, 0.9),
    'message-sent-instant': lambda: place([(0, glide(NOTE['G4'], NOTE['D5'], 0.6))]),
    'message-attention': lambda: notes(['A4', 'A4'], 0.2, 1.0, 0.3),
    'message-highlight': lambda: notes(['E5', 'B5'], 0.12, 1.1, 0.34, 0.85),
    'message-contact-in': lambda: notes(['D5', 'A5'], 0.11, 1.0, 0.3, 0.8),
    'message-contact-out': lambda: notes(['A5', 'D5'], 0.11, 1.0, 0.3, 0.8),
    'dialog-information': lambda: place([(0, tone('E5', 1.2, 0.04, 0.4)), (0.02, tone('E4', 1.2, 0.08, 0.45, 0.35, 0))]),
    'dialog-question': lambda: place([(0, tone('D5', 1.0, 0.04, 0.3, 0.8)), (0.14, glide(NOTE['D5'], NOTE['G5'], 0.7, 0.06, 0.3, 0.55))]),
    'dialog-warning': lambda: notes(['A4', 'F4'], 0.22, 1.2, 0.36),
    'dialog-warning-auth': lambda: notes(['D5', 'A4'], 0.18, 1.2, 0.36),
    'dialog-error': lambda: notes(['E4', 'C4'], 0.18, 1.3, 0.4),
    'dialog-error-serious': lambda: notes(['E4', 'C4', 'A3'], 0.17, 1.3, 0.4),
    'dialog-error-critical': lambda: place([(0, tone('A3', 1.4, 0.03, 0.45)), (0.24, tone('A3', 1.4, 0.03, 0.45)),
                                            (0.0, pad(['A2', 'E3'], 1.6, 0.2, 0.6, 0.45))]),
    'bell': lambda: place([(0, tone('C5', 1.0, 0.02, 0.3))]),
    'bell-window-system': lambda: place([(0, tone('A4', 0.9, 0.02, 0.26, 0.8))]),
    # Devices and power
    'device-added': lambda: notes(['C5', 'G5'], 0.12, 1.1, 0.34),
    'device-removed': lambda: notes(['G5', 'C5'], 0.12, 1.1, 0.34),
    'power-plug': lambda: place([(0, glide(NOTE['C4'], NOTE['G4'], 0.6, 0.1, 0.25, 0.55)), (0.28, tone('G5', 1.1, 0.04, 0.34, 0.8))]),
    'power-unplug': lambda: place([(0, glide(NOTE['G4'], NOTE['C4'], 0.6, 0.1, 0.25, 0.55)), (0.28, tone('C4', 1.2, 0.04, 0.38, 0.8))]),
    'battery-low': lambda: notes(['A4', 'E4'], 0.24, 1.2, 0.38),
    'battery-caution': lambda: notes(['A4', 'E4', 'A4', 'E4'], 0.22, 1.0, 0.3),
    'battery-full': lambda: place([(0, pad(['C4', 'E4', 'G4'], 1.6, 0.25, 0.6)), (0.15, tone('C5', 1.4, 0.05, 0.45, 0.7))]),
    # Outcomes
    'completion-success': lambda: notes(['C5', 'E5', 'G5'], 0.1, 1.2, 0.36),
    'outcome-success': lambda: notes(['C5', 'E5', 'G5'], 0.1, 1.2, 0.36),
    'complete-media-burn': lambda: notes(['C5', 'E5', 'G5'], 0.1, 1.2, 0.36),
    'completion-partial': lambda: notes(['C5', 'E5'], 0.12, 1.1, 0.34),
    'completion-fail': lambda: notes(['G4', 'D#4'], 0.18, 1.2, 0.38),
    'outcome-failure': lambda: notes(['G4', 'D#4'], 0.18, 1.2, 0.38),
    'complete-media-error': lambda: notes(['G4', 'D#4'], 0.18, 1.2, 0.38),
    'completion-rotation': lambda: notes(['E5', 'E5'], 0.09, 0.5, 0.12, 0.5, 0.01),
    'media-insert-request': lambda: place([(0, tone('D5', 1.0, 0.04, 0.3, 0.8)), (0.14, glide(NOTE['D5'], NOTE['G5'], 0.7, 0.06, 0.3, 0.55))]),
    'trash-empty': lambda: place([(0, breath()), (0.45, tone('C4', 0.9, 0.02, 0.22, 0.6))]),
    # Session: a slow chord with an arpeggio over it.
    'desktop-login': lambda: place([(0, pad(['C3', 'G3', 'E4'], 2.4, 0.6, 0.9, 0.55))]
                                   + [(0.25 + i * 0.16, tone(n, 1.4, 0.05, 0.42, 0.7)) for i, n in enumerate(['G4', 'C5', 'E5', 'G5'])],
                                   wet=0.36, tail=1.4),
    'desktop-logout': lambda: place([(0, pad(['C3', 'G3', 'E4'], 2.0, 0.2, 0.7, 0.5))]
                                    + [(i * 0.17, tone(n, 1.3, 0.05, 0.4, 0.65)) for i, n in enumerate(['G5', 'E5', 'C5', 'G4'])],
                                    wet=0.36, tail=1.3),
    'service-login': lambda: notes(['G4', 'D5'], 0.12, 1.0, 0.32, 0.8),
    'service-logout': lambda: notes(['D5', 'G4'], 0.12, 1.0, 0.32, 0.8),
    # Interaction: quiet and short.
    'audio-volume-change': lambda: place([(0, tone('E5', 0.35, 0.006, 0.08, 1.0, 0.1))], wet=0.18, tail=0.25),
    'button-pressed': lambda: place([(0, tone('A4', 0.2, 0.004, 0.04, 1.0, 0.3))], wet=0.12, tail=0.15),
    'button-pressed-modifier': lambda: place([(0, tone('F4', 0.2, 0.004, 0.04, 1.0, 0.3))], wet=0.12, tail=0.15),
    # Timers and calls: gentle motifs that repeat.
    'alarm-clock-elapsed': lambda: place([(r * 0.85 + i * 0.13, tone(n, 1.0, 0.03, 0.3, 0.85))
                                          for r in range(3) for i, n in enumerate(['C5', 'E5', 'G5'])]),
    'phone-incoming-call': lambda: place([(r * 1.1 + i * 0.16, tone(n, 1.0, 0.03, 0.3, 0.8))
                                          for r in range(3) for i, n in enumerate(['E5', 'G5', 'E5', 'B5'])]),
    'theme-demo': lambda: notes(['C5', 'E5', 'G5', 'E5', 'C6'], 0.22, 1.3, 0.42, 0.85),
}

QUIET = ('audio-volume-change', 'button-pressed', 'button-pressed-modifier', 'completion-rotation')


def soften(x, cutoff=2600, taps=127):
    """Windowed-sinc low-pass: rounds off the top end like a soft speaker."""
    n = np.arange(taps) - (taps - 1) / 2
    kernel = np.sinc(2 * cutoff / RATE * n) * np.hamming(taps)
    return np.convolve(x, kernel / kernel.sum(), 'same')


def write(name, signal):
    signal = soften(signal)
    peak = np.max(np.abs(signal)) or 1
    level = 0.42 if name in QUIET else 0.6  # about -7.5 and -4.4 dBFS peaks
    mono = signal / peak * level
    # Trim the inaudible end of the tail, then fade the last 30 ms.
    audible = np.nonzero(np.abs(mono) > 1e-4)[0]
    mono = mono[:audible[-1] + 1] if audible.size else mono
    mono *= np.minimum(1, np.arange(mono.size)[::-1] / (RATE * 0.03))
    # Both channels identical: laptop speakers often sum to mono.
    pcm = (np.stack([mono, mono], axis=1) * 32767).astype('<i2').tobytes()
    target = OUT / 'stereo' / (name + '.oga')
    subprocess.run(['ffmpeg', '-loglevel', 'error', '-y', '-f', 's16le', '-ar', str(RATE), '-ac', '2', '-i', '-',
                    '-c:a', 'libvorbis', '-q:a', '5', '-map_metadata', '-1', '-fflags', '+bitexact',
                    '-flags:a', '+bitexact', str(target)], input=pcm, check=True)


INDEX = '''[Sound Theme]
Name=Nothing KDE
Name[tr]=Nothing KDE
Comment=Warm, soft tones for Nothing KDE; generated by assets/sounds/build-sounds.py
Comment[tr]=Nothing KDE için sıcak ve yumuşak tonlar; assets/sounds/build-sounds.py ile üretilir
Inherits=freedesktop
Directories=stereo
Example=theme-demo

[stereo]
OutputProfile=stereo
'''


def main():
    (OUT / 'stereo').mkdir(parents=True, exist_ok=True)
    for old in (OUT / 'stereo').glob('*.oga'):
        old.unlink()
    (OUT / 'index.theme').write_text(INDEX)
    for name, build in SOUNDS.items():
        write(name, build())
    print('wrote', len(SOUNDS), 'sounds to', OUT)


if __name__ == '__main__':
    main()

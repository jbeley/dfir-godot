#!/usr/bin/env python3
"""Generate chiptune-style sound effects for DFIR Simulator.
Uses pure math to create WAV files - no external audio libs needed.
"""

import struct
import math
import os
import random

AUDIO_DIR = os.path.join(os.path.dirname(__file__), '..', 'assets', 'audio')
SAMPLE_RATE = 22050
MAX_AMP = 32767


def save_wav(filename: str, samples: list[int], sample_rate: int = SAMPLE_RATE):
    """Save 16-bit mono WAV file."""
    path = os.path.join(AUDIO_DIR, filename)
    os.makedirs(os.path.dirname(path), exist_ok=True)

    num_samples = len(samples)
    data_size = num_samples * 2
    file_size = 36 + data_size

    with open(path, 'wb') as f:
        # RIFF header
        f.write(b'RIFF')
        f.write(struct.pack('<I', file_size))
        f.write(b'WAVE')
        # fmt chunk
        f.write(b'fmt ')
        f.write(struct.pack('<I', 16))       # chunk size
        f.write(struct.pack('<H', 1))         # PCM
        f.write(struct.pack('<H', 1))         # mono
        f.write(struct.pack('<I', sample_rate))
        f.write(struct.pack('<I', sample_rate * 2))  # byte rate
        f.write(struct.pack('<H', 2))         # block align
        f.write(struct.pack('<H', 16))        # bits per sample
        # data chunk
        f.write(b'data')
        f.write(struct.pack('<I', data_size))
        for s in samples:
            f.write(struct.pack('<h', max(-MAX_AMP, min(MAX_AMP, int(s)))))

    print(f"  {filename} ({num_samples / sample_rate:.2f}s)")


def sine(freq: float, duration: float, volume: float = 0.5, fade_out: bool = True) -> list[int]:
    samples = []
    n = int(SAMPLE_RATE * duration)
    for i in range(n):
        t = i / SAMPLE_RATE
        env = 1.0
        if fade_out:
            env = max(0, 1.0 - (i / n))
        val = math.sin(2 * math.pi * freq * t) * volume * env * MAX_AMP
        samples.append(int(val))
    return samples


def square(freq: float, duration: float, volume: float = 0.3, fade_out: bool = True) -> list[int]:
    samples = []
    n = int(SAMPLE_RATE * duration)
    period = SAMPLE_RATE / freq
    for i in range(n):
        env = max(0, 1.0 - (i / n)) if fade_out else 1.0
        val = volume * env * MAX_AMP * (1 if (i % int(period)) < int(period / 2) else -1)
        samples.append(int(val))
    return samples


def noise(duration: float, volume: float = 0.2) -> list[int]:
    n = int(SAMPLE_RATE * duration)
    return [int(random.uniform(-1, 1) * volume * MAX_AMP) for _ in range(n)]


def mix(a: list[int], b: list[int]) -> list[int]:
    length = max(len(a), len(b))
    result = []
    for i in range(length):
        va = a[i] if i < len(a) else 0
        vb = b[i] if i < len(b) else 0
        result.append(max(-MAX_AMP, min(MAX_AMP, va + vb)))
    return result


def concat(*parts: list[int]) -> list[int]:
    result = []
    for p in parts:
        result.extend(p)
    return result


def silence(duration: float) -> list[int]:
    return [0] * int(SAMPLE_RATE * duration)


# === Sound Effects ===

def sfx_keypress():
    """Short click for terminal key press."""
    return concat(
        square(800, 0.01, 0.2, False),
        noise(0.02, 0.1),
    )


def sfx_enter():
    """Enter key / command submit."""
    return concat(
        square(600, 0.02, 0.3),
        silence(0.01),
        square(900, 0.03, 0.2),
    )


def sfx_notification():
    """Soft notification chime."""
    return concat(
        sine(880, 0.1, 0.3),
        sine(1100, 0.1, 0.25),
        sine(1320, 0.15, 0.2),
    )


def sfx_error():
    """Error buzz."""
    return concat(
        square(200, 0.1, 0.3),
        silence(0.05),
        square(150, 0.15, 0.3),
    )


def sfx_case_received():
    """New case alert - urgent."""
    return concat(
        sine(660, 0.08, 0.3),
        sine(880, 0.08, 0.3),
        sine(660, 0.08, 0.3),
        sine(880, 0.08, 0.3),
        silence(0.05),
        sine(1100, 0.15, 0.25),
    )


def sfx_case_complete():
    """Case completion fanfare."""
    notes = [523, 659, 784, 1047]  # C E G C
    parts = []
    for note in notes:
        parts.append(sine(note, 0.12, 0.3))
        parts.append(silence(0.02))
    parts.append(sine(1047, 0.3, 0.25))
    return concat(*parts)


def sfx_coffee():
    """Coffee brewing / pouring sound."""
    s = noise(0.3, 0.05)
    s = mix(s, sine(200, 0.3, 0.1))
    s.extend(concat(
        silence(0.1),
        sine(500, 0.05, 0.15),
        sine(600, 0.05, 0.15),
    ))
    return s


def sfx_cat_purr():
    """Cat purring - low rumble."""
    samples = []
    n = int(SAMPLE_RATE * 0.8)
    for i in range(n):
        t = i / SAMPLE_RATE
        # Low frequency rumble with amplitude modulation
        rumble = math.sin(2 * math.pi * 25 * t) * 0.3
        mod = 0.5 + 0.5 * math.sin(2 * math.pi * 3 * t)
        env = min(1.0, i / (SAMPLE_RATE * 0.1)) * max(0, 1.0 - (i / n) * 0.5)
        samples.append(int(rumble * mod * env * MAX_AMP * 0.4))
    return samples


def sfx_cat_meow():
    """Simple cat meow."""
    samples = []
    n = int(SAMPLE_RATE * 0.3)
    for i in range(n):
        t = i / SAMPLE_RATE
        # Frequency sweep from 700 to 400 Hz
        freq = 700 - 300 * (t / 0.3)
        env = math.sin(math.pi * t / 0.3)  # bell curve envelope
        val = math.sin(2 * math.pi * freq * t) * env * 0.3 * MAX_AMP
        samples.append(int(val))
    return samples


def sfx_sleep():
    """Sleep / snore sound - low tone."""
    return concat(
        sine(100, 0.3, 0.15, True),
        silence(0.2),
        sine(90, 0.4, 0.12, True),
    )


def sfx_interact():
    """Generic interact sound."""
    return concat(
        sine(440, 0.05, 0.2),
        sine(550, 0.08, 0.2),
    )


def sfx_menu_move():
    """Menu cursor move."""
    return square(440, 0.03, 0.15)


def sfx_menu_select():
    """Menu item selected."""
    return concat(
        square(550, 0.03, 0.2),
        square(880, 0.05, 0.2),
    )


def sfx_promotion():
    """Career promotion fanfare."""
    notes = [262, 330, 392, 523, 659, 784, 1047]  # C major scale
    parts = []
    for i, note in enumerate(notes):
        vol = 0.2 + 0.1 * (i / len(notes))
        parts.append(sine(note, 0.08, vol))
    parts.append(sine(1047, 0.4, 0.3))
    return concat(*parts)


def ambient_office():
    """Ambient office background - very subtle."""
    # 5 seconds of very quiet ambience
    samples = []
    n = int(SAMPLE_RATE * 5.0)
    for i in range(n):
        t = i / SAMPLE_RATE
        # Very low hum (computer fan)
        hum = math.sin(2 * math.pi * 60 * t) * 0.02
        # Occasional quiet noise
        n_val = random.uniform(-1, 1) * 0.005
        samples.append(int((hum + n_val) * MAX_AMP))
    return samples


def main():
    print("Generating DFIR Simulator sound effects...")

    # SFX
    save_wav("sfx/keypress.wav", sfx_keypress())
    save_wav("sfx/enter.wav", sfx_enter())
    save_wav("sfx/notification.wav", sfx_notification())
    save_wav("sfx/error.wav", sfx_error())
    save_wav("sfx/case_received.wav", sfx_case_received())
    save_wav("sfx/case_complete.wav", sfx_case_complete())
    save_wav("sfx/coffee.wav", sfx_coffee())
    save_wav("sfx/cat_purr.wav", sfx_cat_purr())
    save_wav("sfx/cat_meow.wav", sfx_cat_meow())
    save_wav("sfx/sleep.wav", sfx_sleep())
    save_wav("sfx/interact.wav", sfx_interact())
    save_wav("sfx/menu_move.wav", sfx_menu_move())
    save_wav("sfx/menu_select.wav", sfx_menu_select())
    save_wav("sfx/promotion.wav", sfx_promotion())

    # Ambient
    save_wav("music/ambient_office.wav", ambient_office())

    print("Done!")


if __name__ == '__main__':
    main()

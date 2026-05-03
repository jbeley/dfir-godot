#!/usr/bin/env python3
"""Generate world-traversal SFX: secret-found, location-arrived, heat-warning,
and a short footstep. Reuses the helper math from generate_sounds.py.

Run from repo root: python3 tools/generate_world_sounds.py
"""

from __future__ import annotations

import math
import os
import random
import struct

AUDIO_DIR = os.path.join(os.path.dirname(__file__), "..", "assets", "audio")
SAMPLE_RATE = 22050
MAX_AMP = 32767


def save_wav(filename: str, samples: list[int]) -> None:
    path = os.path.join(AUDIO_DIR, filename)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    n = len(samples)
    data_size = n * 2
    file_size = 36 + data_size
    with open(path, "wb") as f:
        f.write(b"RIFF")
        f.write(struct.pack("<I", file_size))
        f.write(b"WAVE")
        f.write(b"fmt ")
        f.write(struct.pack("<I", 16))
        f.write(struct.pack("<H", 1))
        f.write(struct.pack("<H", 1))
        f.write(struct.pack("<I", SAMPLE_RATE))
        f.write(struct.pack("<I", SAMPLE_RATE * 2))
        f.write(struct.pack("<H", 2))
        f.write(struct.pack("<H", 16))
        f.write(b"data")
        f.write(struct.pack("<I", data_size))
        for s in samples:
            f.write(struct.pack("<h", max(-MAX_AMP, min(MAX_AMP, int(s)))))
    print(f"  {filename} ({n / SAMPLE_RATE:.2f}s)")


def sine(freq: float, dur: float, vol: float = 0.5, fade: bool = True) -> list[int]:
    out = []
    n = int(SAMPLE_RATE * dur)
    for i in range(n):
        t = i / SAMPLE_RATE
        env = max(0.0, 1.0 - (i / n)) if fade else 1.0
        out.append(int(math.sin(2 * math.pi * freq * t) * vol * env * MAX_AMP))
    return out


def silence(dur: float) -> list[int]:
    return [0] * int(SAMPLE_RATE * dur)


def concat(*parts: list[int]) -> list[int]:
    out: list[int] = []
    for p in parts:
        out.extend(p)
    return out


def mix(a: list[int], b: list[int]) -> list[int]:
    length = max(len(a), len(b))
    out = []
    for i in range(length):
        va = a[i] if i < len(a) else 0
        vb = b[i] if i < len(b) else 0
        out.append(max(-MAX_AMP, min(MAX_AMP, va + vb)))
    return out


def noise(dur: float, vol: float = 0.2, fade: bool = True) -> list[int]:
    out = []
    n = int(SAMPLE_RATE * dur)
    for i in range(n):
        env = max(0.0, 1.0 - (i / n)) if fade else 1.0
        out.append(int(random.uniform(-1, 1) * vol * env * MAX_AMP))
    return out


# --- World SFX ---


def sfx_secret_found() -> list[int]:
    """Sparkly arpeggio — softer than notification, more 'discovery'."""
    return concat(
        sine(740, 0.08, 0.22),
        sine(988, 0.08, 0.20),
        sine(1175, 0.10, 0.18),
        silence(0.03),
        sine(1480, 0.18, 0.22),
    )


def sfx_location_arrived() -> list[int]:
    """A soft door-thud + a single warm tone for 'you're somewhere new'."""
    thud = mix(
        sine(80, 0.14, 0.45, fade=True),
        noise(0.10, 0.06),
    )
    return concat(thud, silence(0.03), sine(330, 0.12, 0.22))


def sfx_heat_warning() -> list[int]:
    """Low double-thump — DON'T overuse this, fires only on threshold cross."""
    return concat(
        sine(120, 0.18, 0.45),
        silence(0.06),
        sine(110, 0.22, 0.40),
    )


def sfx_footstep() -> list[int]:
    """Quick noise burst, used optionally for player walking."""
    return concat(noise(0.04, 0.10), silence(0.01))


def sfx_journal_open() -> list[int]:
    """Little flip-page sound for opening the journal."""
    return concat(
        sine(420, 0.05, 0.18),
        sine(620, 0.05, 0.18),
        sine(880, 0.07, 0.16),
    )


def main() -> None:
    print("Generating world-traversal SFX...")
    save_wav("sfx/secret_found.wav", sfx_secret_found())
    save_wav("sfx/location_arrived.wav", sfx_location_arrived())
    save_wav("sfx/heat_warning.wav", sfx_heat_warning())
    save_wav("sfx/footstep.wav", sfx_footstep())
    save_wav("sfx/journal_open.wav", sfx_journal_open())
    print("Done.")


if __name__ == "__main__":
    main()

#!/usr/bin/env python3
"""Generate chiptune soundtrack for DFIR Simulator.
Adaptive music tracks: chill investigation, tense deadline, menu theme.
Uses simple waveform synthesis - no external audio libs.
"""

import struct
import math
import os

AUDIO_DIR = os.path.join(os.path.dirname(__file__), '..', 'assets', 'audio', 'music')
SAMPLE_RATE = 22050
MAX_AMP = 32767
BPM = 100


def save_wav(filename, samples, sample_rate=SAMPLE_RATE):
    path = os.path.join(AUDIO_DIR, filename)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    num_samples = len(samples)
    data_size = num_samples * 2
    with open(path, 'wb') as f:
        f.write(b'RIFF')
        f.write(struct.pack('<I', 36 + data_size))
        f.write(b'WAVE')
        f.write(b'fmt ')
        f.write(struct.pack('<IHHIIHH', 16, 1, 1, sample_rate, sample_rate * 2, 2, 16))
        f.write(b'data')
        f.write(struct.pack('<I', data_size))
        for s in samples:
            f.write(struct.pack('<h', max(-MAX_AMP, min(MAX_AMP, int(s)))))
    dur = num_samples / sample_rate
    print(f"  {filename} ({dur:.1f}s)")


def note_freq(note_name):
    """Convert note name to frequency. e.g., 'C4' -> 261.63"""
    notes = {'C': 0, 'D': 2, 'E': 4, 'F': 5, 'G': 7, 'A': 9, 'B': 11}
    name = note_name[0]
    sharp = '#' in note_name
    octave = int(note_name[-1])
    semitone = notes[name] + (1 if sharp else 0)
    return 440.0 * (2.0 ** ((semitone - 9 + (octave - 4) * 12) / 12.0))


def pulse_wave(freq, duration, volume=0.2, duty=0.5, fade=True):
    n = int(SAMPLE_RATE * duration)
    samples = []
    period = SAMPLE_RATE / freq if freq > 0 else SAMPLE_RATE
    for i in range(n):
        env = 1.0
        if fade:
            attack = min(1.0, i / (SAMPLE_RATE * 0.01))
            release = max(0.0, 1.0 - max(0, i - n * 0.7) / (n * 0.3))
            env = attack * release
        val = volume * env * MAX_AMP * (1 if (i % int(period)) < int(period * duty) else -1)
        samples.append(int(val))
    return samples


def triangle_wave(freq, duration, volume=0.2, fade=True):
    n = int(SAMPLE_RATE * duration)
    samples = []
    period = SAMPLE_RATE / freq if freq > 0 else SAMPLE_RATE
    for i in range(n):
        env = 1.0
        if fade:
            attack = min(1.0, i / (SAMPLE_RATE * 0.01))
            release = max(0.0, 1.0 - max(0, i - n * 0.7) / (n * 0.3))
            env = attack * release
        phase = (i % int(period)) / period
        val = (4 * abs(phase - 0.5) - 1) * volume * env * MAX_AMP
        samples.append(int(val))
    return samples


def sine_note(freq, duration, volume=0.15, fade=True):
    n = int(SAMPLE_RATE * duration)
    samples = []
    for i in range(n):
        t = i / SAMPLE_RATE
        env = 1.0
        if fade:
            attack = min(1.0, i / (SAMPLE_RATE * 0.02))
            release = max(0.0, 1.0 - max(0, i - n * 0.6) / (n * 0.4))
            env = attack * release
        samples.append(int(math.sin(2 * math.pi * freq * t) * volume * env * MAX_AMP))
    return samples


def rest(duration):
    return [0] * int(SAMPLE_RATE * duration)


def mix(*tracks):
    length = max(len(t) for t in tracks)
    result = [0] * length
    for track in tracks:
        for i in range(len(track)):
            result[i] = max(-MAX_AMP, min(MAX_AMP, result[i] + track[i]))
    return result


def concat(*parts):
    result = []
    for p in parts:
        result.extend(p)
    return result


def pad_to(samples, target_len):
    if len(samples) < target_len:
        samples.extend([0] * (target_len - len(samples)))
    return samples[:target_len]


def beat_duration():
    return 60.0 / BPM


# === Tracks ===

def make_chill_investigation():
    """Lo-fi chiptune for calm investigation. 16 bars, loops."""
    beat = beat_duration()

    # Chord progression: Am - F - C - G (lo-fi staple)
    chords = [
        [('A3', 'C4', 'E4')] * 4,
        [('F3', 'A3', 'C4')] * 4,
        [('C3', 'E3', 'G3')] * 4,
        [('G3', 'B3', 'D4')] * 4,
    ]

    # Melody over chords (pentatonic: A C D E G)
    melody_notes = [
        'E4', 'C4', 'A3', 'C4',  # bar 1
        'A3', 'F3', 'A3', 'C4',  # bar 2
        'G3', 'E3', 'G3', 'C4',  # bar 3
        'D4', 'B3', 'G3', 'B3',  # bar 4
        'E4', 'E4', 'D4', 'C4',  # bar 5 (repeat with variation)
        'C4', 'A3', 'F3', 'A3',  # bar 6
        'E3', 'G3', 'C4', 'E4',  # bar 7
        'D4', 'B3', 'D4', 'G3',  # bar 8
    ]

    # Bass line
    bass_notes = ['A2', 'A2', 'F2', 'F2', 'C2', 'C2', 'G2', 'G2'] * 2

    melody_track = []
    for note in melody_notes:
        melody_track.extend(pulse_wave(note_freq(note), beat * 0.9, 0.12, 0.25))
        melody_track.extend(rest(beat * 0.1))

    bass_track = []
    for note in bass_notes:
        bass_track.extend(triangle_wave(note_freq(note), beat * 2 * 0.95, 0.15))
        bass_track.extend(rest(beat * 2 * 0.05))

    # Pad chords
    pad_track = []
    for chord_bar in chords * 2:
        for chord in chord_bar:
            chord_samples = rest(int(beat * SAMPLE_RATE))
            for note_name in chord:
                chord_samples = mix(chord_samples, sine_note(note_freq(note_name), beat * 0.95, 0.06))
            pad_track.extend(chord_samples)

    # Mix all together
    max_len = max(len(melody_track), len(bass_track), len(pad_track))
    return mix(pad_to(melody_track, max_len), pad_to(bass_track, max_len), pad_to(pad_track, max_len))


def make_tense_deadline():
    """Tense, faster music for when deadline is near. 8 bars."""
    beat = 60.0 / 130  # Faster BPM

    # Minor key, driving pulse
    bass_pattern = ['D2', 'D2', 'D2', 'F2', 'D2', 'D2', 'A1', 'A1',
                    'D2', 'D2', 'D2', 'F2', 'G2', 'G2', 'A2', 'A2']

    melody = ['D4', 'F4', 'A4', 'G4', 'F4', 'E4', 'D4', 'C4',
              'D4', 'F4', 'G4', 'A4', 'A4', 'G4', 'F4', 'D4']

    bass_track = []
    for note in bass_pattern:
        bass_track.extend(pulse_wave(note_freq(note), beat * 0.8, 0.18, 0.5))
        bass_track.extend(rest(beat * 0.2))

    melody_track = []
    for note in melody:
        melody_track.extend(pulse_wave(note_freq(note), beat * 0.7, 0.10, 0.25))
        melody_track.extend(rest(beat * 0.3))

    # Arpeggio layer
    arp_notes = ['D3', 'F3', 'A3'] * 16
    arp_track = []
    for note in arp_notes:
        arp_track.extend(pulse_wave(note_freq(note), beat / 3 * 0.8, 0.06, 0.125))
        arp_track.extend(rest(beat / 3 * 0.2))

    max_len = max(len(bass_track), len(melody_track), len(arp_track))
    return mix(pad_to(bass_track, max_len), pad_to(melody_track, max_len), pad_to(arp_track, max_len))


def make_menu_theme():
    """Title screen theme. Atmospheric, mysterious. 8 bars."""
    beat = 60.0 / 80  # Slow

    # Atmospheric pads - Dm -> Am -> Bb -> Am
    pad_notes = [
        ('D3', 'F3', 'A3'), ('D3', 'F3', 'A3'),
        ('A2', 'C3', 'E3'), ('A2', 'C3', 'E3'),
        ('B2', 'D3', 'F3'), ('B2', 'D3', 'F3'),
        ('A2', 'C3', 'E3'), ('A2', 'C3', 'E3'),
    ]

    pad_track = []
    for chord in pad_notes:
        chord_len = int(beat * 2 * SAMPLE_RATE)
        chord_samples = rest(chord_len)
        for note_name in chord:
            chord_samples = mix(chord_samples,
                pad_to(sine_note(note_freq(note_name), beat * 2 * 0.95, 0.08), chord_len))
        pad_track.extend(chord_samples)

    # Sparse melody
    melody = ['A4', '', 'F4', '', 'E4', '', 'D4', '',
              '', 'C4', '', 'D4', '', 'E4', '', 'A3']
    melody_track = []
    for note in melody:
        if note:
            melody_track.extend(triangle_wave(note_freq(note), beat * 0.9, 0.10))
        else:
            melody_track.extend(rest(beat))
        if len(melody_track) < len(pad_track):
            melody_track.extend(rest(beat * 0.1))

    max_len = max(len(pad_track), len(melody_track))
    return mix(pad_to(pad_track, max_len), pad_to(melody_track, max_len))


def main():
    os.makedirs(AUDIO_DIR, exist_ok=True)
    print("Generating DFIR Simulator soundtrack...")

    save_wav("chill_investigation.wav", make_chill_investigation())
    save_wav("tense_deadline.wav", make_tense_deadline())
    save_wav("menu_theme.wav", make_menu_theme())

    print("Done!")


if __name__ == '__main__':
    main()

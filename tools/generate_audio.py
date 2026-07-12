#!/usr/bin/env python3
"""Procedural audio for Purrvivors - one cohesive chiptune family.

Generates every SFX plus the two music loops as 22.05kHz mono 16-bit WAVs.
Everything is synthesized here (sfxr-style), so the whole soundscape shares
one character and the licensing is trivially clean (ours, CC0).

Run: python3 tools/generate_audio.py
"""
import math
import os
import random
import struct
import wave

SR = 22050
random.seed(1804)

SFX_DIR = "assets/audio/sfx"
MUSIC_DIR = "assets/audio/music"


# ------------------------------- synth core --------------------------------

def silence(dur):
    return [0.0] * int(dur * SR)


def mix_into(buf, samples, at=0.0, gain=1.0):
    start = int(at * SR)
    if start + len(samples) > len(buf):
        buf.extend([0.0] * (start + len(samples) - len(buf)))
    for i, s in enumerate(samples):
        buf[start + i] += s * gain
    return buf


def envelope(n, attack=0.01, release=0.1, dur=None):
    """Linear attack, exponential-ish release."""
    dur = dur if dur is not None else n / SR
    a_n = max(1, int(attack * SR))
    r_n = max(1, int(release * SR))
    out = []
    for i in range(n):
        v = 1.0
        if i < a_n:
            v = i / a_n
        rem = n - i
        if rem < r_n:
            v *= rem / r_n
        out.append(v)
    return out


def tone(f0, f1, dur, wav="square", vol=0.5, duty=0.5, attack=0.005,
         release=0.06, vib_hz=0.0, vib_amt=0.0, curve=1.0):
    """A single swept tone. curve > 1 bends the sweep toward the end."""
    n = int(dur * SR)
    env = envelope(n, attack, release)
    out = []
    phase = 0.0
    for i in range(n):
        t = i / n
        f = f0 + (f1 - f0) * (t ** curve)
        if vib_hz > 0:
            f *= 1.0 + vib_amt * math.sin(2 * math.pi * vib_hz * i / SR)
        phase += f / SR
        p = phase % 1.0
        if wav == "square":
            s = 1.0 if p < duty else -1.0
        elif wav == "tri":
            s = 4.0 * abs(p - 0.5) - 1.0
        elif wav == "saw":
            s = 2.0 * p - 1.0
        else:  # sine
            s = math.sin(2 * math.pi * p)
        out.append(s * vol * env[i])
    return out


def noise(dur, vol=0.5, lowpass=1.0, attack=0.002, release=0.08, sweep=1.0):
    """White noise with a one-pole lowpass; sweep < 1 closes the filter."""
    n = int(dur * SR)
    env = envelope(n, attack, release)
    out = []
    last = 0.0
    for i in range(n):
        t = i / n
        alpha = max(0.02, min(1.0, lowpass * (sweep + (1 - sweep) * (1 - t))))
        last += alpha * (random.uniform(-1, 1) - last)
        out.append(last * vol * env[i])
    return out


def write_wav(path, samples, peak=0.82):
    m = max(0.0001, max(abs(s) for s in samples))
    scale = peak / m if m > peak else 1.0
    with wave.open(path, "w") as f:
        f.setnchannels(1)
        f.setsampwidth(2)
        f.setframerate(SR)
        frames = bytearray()
        for s in samples:
            frames += struct.pack("<h", int(max(-1, min(1, s * scale)) * 32767))
        f.writeframes(bytes(frames))
    print(f"  {path}  ({len(samples) / SR:.2f}s)")


# --------------------------------- the SFX ---------------------------------

def build_sfx():
    S = {}

    # eat snack: cute rising blip-blip ("nom")
    b = silence(0.16)
    mix_into(b, tone(520, 700, 0.05, "square", 0.5, duty=0.3), 0.0)
    mix_into(b, tone(760, 980, 0.07, "square", 0.45, duty=0.3), 0.06)
    S["nom"] = b

    # level up: major arpeggio sparkle
    b = silence(0.62)
    for i, f in enumerate([523, 659, 784, 1047]):
        mix_into(b, tone(f, f, 0.14, "square", 0.4, duty=0.4, release=0.1), i * 0.09)
    mix_into(b, tone(1568, 2093, 0.18, "sine", 0.3), 0.4)
    S["level_up"] = b

    # card pick: soft pop
    S["card_pick"] = mix_into(tone(340, 240, 0.07, "tri", 0.6),
                              noise(0.03, 0.25, 0.5), 0.0)

    # player hit: crunchy thud
    b = silence(0.3)
    mix_into(b, noise(0.16, 0.8, 0.9, sweep=0.25), 0.0)
    mix_into(b, tone(180, 70, 0.22, "square", 0.55, duty=0.35), 0.0)
    S["player_hit"] = b

    # enemy hit: tiny thock
    S["enemy_hit"] = mix_into(tone(300, 180, 0.05, "square", 0.4, duty=0.25),
                              noise(0.03, 0.3, 0.8), 0.0)

    # enemy die: dusty poof
    b = silence(0.3)
    mix_into(b, noise(0.26, 0.7, 0.55, sweep=0.2, release=0.18), 0.0)
    mix_into(b, tone(240, 90, 0.16, "tri", 0.35), 0.0)
    S["enemy_die"] = b

    # coin: classic bright ding-ding
    b = silence(0.3)
    mix_into(b, tone(988, 988, 0.07, "square", 0.4, duty=0.5), 0.0)
    mix_into(b, tone(1319, 1319, 0.2, "square", 0.4, duty=0.5, release=0.15), 0.07)
    S["coin"] = b

    # hairball: soft "pft"
    S["hairball"] = mix_into(noise(0.09, 0.5, 0.65, sweep=0.4),
                             tone(200, 120, 0.07, "tri", 0.3), 0.0)

    # claw: quick double swish
    b = silence(0.18)
    mix_into(b, noise(0.09, 0.55, 0.9, attack=0.01, sweep=0.5), 0.0)
    mix_into(b, noise(0.08, 0.45, 0.9, attack=0.01, sweep=0.5), 0.07)
    S["claw"] = b

    # laser: tiny zap
    S["laser"] = tone(1400, 700, 0.05, "saw", 0.3, release=0.03)

    # fish throw: airy whoosh with pitch dip
    S["fish_throw"] = mix_into(noise(0.18, 0.4, 0.8, attack=0.02, sweep=0.45),
                               tone(500, 260, 0.16, "sine", 0.25), 0.0)

    # sonic meow: chiptune meow (up then down, vibrato tail)
    b = silence(0.4)
    mix_into(b, tone(480, 900, 0.13, "square", 0.5, duty=0.3, curve=0.7), 0.0)
    mix_into(b, tone(900, 420, 0.24, "square", 0.5, duty=0.3,
                     vib_hz=9, vib_amt=0.03), 0.12)
    S["meow"] = b

    # dash: short rip
    S["dash"] = noise(0.12, 0.5, 1.0, attack=0.005, sweep=0.35)

    # heal: warm rising chime
    b = silence(0.4)
    mix_into(b, tone(392, 523, 0.3, "sine", 0.4, attack=0.03, release=0.2), 0.0)
    mix_into(b, tone(784, 784, 0.2, "sine", 0.25, release=0.15), 0.15)
    S["heal"] = b

    # revive: sparkling rise
    b = silence(0.7)
    for i, f in enumerate([392, 523, 659, 784, 1047, 1319]):
        mix_into(b, tone(f, f, 0.12, "tri", 0.4, release=0.09), i * 0.08)
    S["revive"] = b

    # vacuum pickup: everything-rushes-in shimmer
    b = silence(0.5)
    mix_into(b, noise(0.45, 0.35, 0.7, attack=0.05, sweep=1.6), 0.0)
    mix_into(b, tone(300, 900, 0.45, "sine", 0.3, attack=0.05), 0.0)
    S["vacuum"] = b

    # boss roar: big angry growl
    b = silence(0.8)
    mix_into(b, tone(110, 70, 0.7, "square", 0.6, duty=0.4,
                     vib_hz=13, vib_amt=0.06, release=0.3), 0.0)
    mix_into(b, noise(0.6, 0.4, 0.35, release=0.3), 0.05)
    S["boss_roar"] = b

    # boss charge windup: rising tension buzz
    S["boss_charge"] = tone(90, 300, 0.5, "saw", 0.4, attack=0.05, release=0.1)

    # boss summon: robo-blips
    b = silence(0.35)
    for i, f in enumerate([620, 470, 620]):
        mix_into(b, tone(f, f, 0.08, "square", 0.35, duty=0.2), i * 0.1)
    S["boss_summon"] = b

    # vacuum suck: long inward woosh
    S["vacuum_suck"] = mix_into(noise(0.9, 0.4, 0.6, attack=0.15, sweep=1.8),
                                tone(160, 420, 0.9, "tri", 0.25, attack=0.15), 0.0)

    # boss defeat: crumble + victory tail
    b = silence(1.1)
    mix_into(b, noise(0.5, 0.8, 0.7, sweep=0.15, release=0.35), 0.0)
    mix_into(b, tone(200, 60, 0.5, "square", 0.5, duty=0.4), 0.0)
    for i, f in enumerate([523, 659, 784]):
        mix_into(b, tone(f, f, 0.16, "square", 0.35, duty=0.4), 0.55 + i * 0.11)
    S["boss_defeat"] = b

    # defeat: three sad notes
    b = silence(1.0)
    for i, f in enumerate([392, 330, 262]):
        mix_into(b, tone(f, f * 0.97, 0.28, "square", 0.4, duty=0.35,
                         release=0.2), i * 0.26)
    S["defeat"] = b

    # fanfare: win jingle
    b = silence(1.5)
    seq = [(523, 0.0), (523, 0.12), (523, 0.24), (659, 0.36),
           (784, 0.58), (659, 0.76), (1047, 0.94)]
    for f, at in seq:
        mix_into(b, tone(f, f, 0.18, "square", 0.4, duty=0.45, release=0.12), at)
    mix_into(b, tone(1047, 1047, 0.4, "tri", 0.3, release=0.3), 1.0)
    S["fanfare"] = b

    # pause: muted blip
    S["pause"] = tone(440, 330, 0.09, "tri", 0.4)

    # ui click: soft wooden tap
    S["click"] = mix_into(tone(300, 210, 0.05, "tri", 0.5, release=0.04),
                          noise(0.02, 0.2, 0.5), 0.0)

    # ui hover: barely-there tick
    S["hover"] = tone(500, 470, 0.03, "sine", 0.25, release=0.02)

    return S


# -------------------------------- the music --------------------------------

NOTES = {"C": 0, "D": 2, "E": 4, "F": 5, "G": 7, "A": 9, "B": 11}


def freq(name, octave):
    semitone = NOTES[name[0]] + (1 if len(name) > 1 and name[1] == "#" else 0)
    return 440.0 * 2 ** ((semitone - 9) / 12 + (octave - 4))


def music_menu():
    """Cozy cafe loop: 84 BPM, Cmaj7 Am7 Fmaj7 G7, soft arps + sine melody."""
    bpm = 84.0
    beat = 60.0 / bpm
    bars = [("C", ["C", "E", "G", "B"]), ("A", ["A", "C", "E", "G"]),
            ("F", ["F", "A", "C", "E"]), ("G", ["G", "B", "D", "F"])]
    total = beat * 4 * len(bars) * 2
    buf = silence(total)
    melody_pool = ["C", "D", "E", "G", "A"]
    rng = random.Random(7)
    for rep in range(2):
        for b_i, (root, chord) in enumerate(bars):
            bar_at = (rep * len(bars) + b_i) * 4 * beat
            # bass: root held, warm triangle
            mix_into(buf, tone(freq(root, 2), freq(root, 2), beat * 3.6, "tri",
                               0.4, attack=0.02, release=0.4), bar_at)
            # arp: soft squares on 8ths
            for i in range(8):
                note = chord[i % len(chord)]
                octv = 4 if i % 4 < 2 else 5
                mix_into(buf, tone(freq(note, octv), freq(note, octv),
                                   beat * 0.42, "square", 0.14, duty=0.3,
                                   attack=0.01, release=0.12), bar_at + i * beat / 2)
            # melody: sparse sine phrases
            if rng.random() < 0.8:
                n1 = rng.choice(melody_pool)
                n2 = rng.choice(melody_pool)
                mix_into(buf, tone(freq(n1, 5), freq(n1, 5), beat * 1.2, "sine",
                                   0.3, attack=0.03, release=0.5), bar_at + beat)
                mix_into(buf, tone(freq(n2, 5), freq(n2, 5), beat * 1.4, "sine",
                                   0.28, attack=0.03, release=0.6), bar_at + beat * 2.5)
    return buf


def music_run():
    """Horde loop: 132 BPM, Am F C G, driving bass, lead, noise hats."""
    bpm = 132.0
    beat = 60.0 / bpm
    prog = [("A", ["A", "C", "E"]), ("F", ["F", "A", "C"]),
            ("C", ["C", "E", "G"]), ("G", ["G", "B", "D"])]
    reps = 2
    total = beat * 4 * len(prog) * reps
    buf = silence(total)
    rng = random.Random(11)
    lead_scale = ["A", "C", "D", "E", "G"]
    for rep in range(reps):
        for b_i, (root, chord) in enumerate(prog):
            bar_at = (rep * len(prog) + b_i) * 4 * beat
            # driving 8th bass
            for i in range(8):
                o = 2 if i % 2 == 0 else 3
                mix_into(buf, tone(freq(root, o), freq(root, o), beat * 0.4,
                                   "tri", 0.42, attack=0.005, release=0.08),
                         bar_at + i * beat / 2)
            # hats on 8ths, accents on beats
            for i in range(8):
                vol = 0.16 if i % 2 == 0 else 0.09
                mix_into(buf, noise(0.04, vol, 1.0, release=0.03),
                         bar_at + i * beat / 2)
            # chord stabs on 2 and 4
            for st in [1, 3]:
                for note in chord:
                    mix_into(buf, tone(freq(note, 4), freq(note, 4), beat * 0.3,
                                       "square", 0.1, duty=0.25, release=0.1),
                             bar_at + st * beat)
            # lead: energetic phrase per bar
            steps = rng.choice([[0, 2, 4, 2], [4, 2, 1, 0], [0, 1, 2, 4],
                                [2, 4, 2, 0]])
            for i, s in enumerate(steps):
                note = lead_scale[s % len(lead_scale)]
                octv = 5 if s < 4 else 6
                mix_into(buf, tone(freq(note, octv), freq(note, octv),
                                   beat * 0.5, "square", 0.2, duty=0.4,
                                   attack=0.008, release=0.12),
                         bar_at + i * beat)
    return buf


def main():
    os.makedirs(SFX_DIR, exist_ok=True)
    os.makedirs(MUSIC_DIR, exist_ok=True)
    print("SFX:")
    for name, samples in build_sfx().items():
        write_wav(f"{SFX_DIR}/{name}.wav", samples)
    print("Music:")
    write_wav(f"{MUSIC_DIR}/menu_loop.wav", music_menu(), peak=0.6)
    write_wav(f"{MUSIC_DIR}/run_loop.wav", music_run(), peak=0.6)


if __name__ == "__main__":
    main()

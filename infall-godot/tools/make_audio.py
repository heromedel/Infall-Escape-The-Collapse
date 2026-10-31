"""Synthesizes the game's sound effects and music into audio/.

Every sound is made here from oscillators, noise and envelopes, so the audio is the game's own and can be
remade or changed by editing this file:  python3 tools/make_audio.py
Effects are written as 16-bit mono WAV; music as looping stereo Ogg Vorbis (needs ffmpeg with libvorbis).
"""
import os
import subprocess
import wave

import numpy as np

RATE = 44100
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "audio")
rng = np.random.default_rng(7)


def t_axis(seconds, rate=RATE):
    return np.arange(int(seconds * rate)) / rate


def env(length, attack, decay_power=2.0, rate=RATE):
    """A quick attack then a decay to silence."""
    n = int(length * rate)
    a = max(1, int(attack * rate))
    e = np.ones(n)
    e[:a] = np.linspace(0, 1, a)
    tail = np.linspace(1, 0, n - a) ** decay_power
    e[a:] = tail
    return e


def sweep(f0, f1, seconds, shape="sine", rate=RATE):
    t = t_axis(seconds, rate)
    freq = f0 * (f1 / f0) ** (t / seconds) if f0 > 0 and f1 > 0 else np.linspace(f0, f1, len(t))
    phase = 2 * np.pi * np.cumsum(freq) / rate
    if shape == "saw":
        return 2 * ((phase / (2 * np.pi)) % 1.0) - 1
    if shape == "square":
        return np.sign(np.sin(phase))
    if shape == "tri":
        return 2 * np.abs(2 * ((phase / (2 * np.pi)) % 1.0) - 1) - 1
    return np.sin(phase)


def noise(seconds, rate=RATE):
    return rng.uniform(-1, 1, int(seconds * rate))


def spectral_filter(signal, low=0.0, high=20000.0, rate=RATE):
    spectrum = np.fft.rfft(signal)
    freqs = np.fft.rfftfreq(len(signal), 1 / rate)
    mask = np.ones_like(freqs)
    if high < rate / 2:
        mask *= 1 / (1 + (freqs / high) ** 4)
    if low > 0:
        mask *= 1 / (1 + (low / np.maximum(freqs, 1)) ** 4)
    return np.fft.irfft(spectrum * mask, len(signal))


def reverb(signal, seconds=1.6, mix=0.3, rate=RATE):
    n = int(seconds * rate)
    impulse = rng.normal(0, 1, n) * np.exp(-np.linspace(0, 7, n))
    impulse = spectral_filter(impulse, 200, 6000, rate)
    impulse /= np.sqrt(np.sum(impulse ** 2)) + 1e-9
    size = len(signal) + n
    wet = np.fft.irfft(np.fft.rfft(signal, size) * np.fft.rfft(impulse, size), size)[: len(signal)]
    return signal * (1 - mix) + wet * mix


def normalize(signal, peak=0.9):
    top = np.max(np.abs(signal)) + 1e-9
    return signal / top * peak


def write_wav(name, signal, peak=0.85):
    signal = normalize(signal, peak)
    fade = min(len(signal), 200)
    signal[-fade:] *= np.linspace(1, 0, fade)
    data = (signal * 32767).astype(np.int16)
    with wave.open(os.path.join(OUT, name + ".wav"), "wb") as file:
        file.setnchannels(1)
        file.setsampwidth(2)
        file.setframerate(RATE)
        file.writeframes(data.tobytes())


def pad(*parts):
    length = max(len(p) for p in parts)
    total = np.zeros(length)
    for p in parts:
        total[: len(p)] += p
    return total


# --- Effects ----------------------------------------------------------------------------------------------------

def make_effects():
    s = sweep(2400, 380, 0.22, "saw") * env(0.22, 0.003, 2.5)
    s = spectral_filter(s, 200, 5000) + 0.25 * noise(0.22) * env(0.22, 0.001, 6)
    write_wav("laser", reverb(s, 0.5, 0.18))

    s = sweep(1500, 160, 0.38, "saw") * env(0.38, 0.004, 1.8) + 0.5 * sweep(260, 70, 0.38) * env(0.38, 0.01, 1.5)
    write_wav("laser_heavy", reverb(spectral_filter(s, 60, 4000), 0.6, 0.2))

    whoosh = spectral_filter(noise(0.9), 300, 2500) * env(0.9, 0.08, 1.4)
    thump = sweep(120, 50, 0.4) * env(0.4, 0.005, 2)
    write_wav("missile", reverb(pad(thump, whoosh * 0.7), 0.7, 0.2))

    t = t_axis(1.2)
    buzz = (np.sin(2 * np.pi * 110 * t) + 0.6 * np.sign(np.sin(2 * np.pi * 220.5 * t)) * 0.4 + 0.3 * noise(1.2)) * env(1.2, 0.05, 0.8)
    write_wav("beam", spectral_filter(buzz, 80, 3000))

    crunch = spectral_filter(noise(0.6), 80, 2200) * env(0.6, 0.002, 3)
    thud = sweep(160, 40, 0.5) * env(0.5, 0.002, 2)
    write_wav("hit_hull", reverb(pad(thud * 1.2, crunch), 0.8, 0.22))

    write_wav("hit_soft", reverb(spectral_filter(noise(0.3), 300, 3000) * env(0.3, 0.002, 4), 0.5, 0.2), 0.6)

    t = t_axis(0.7)
    ping = sum(np.sin(2 * np.pi * f * t) * a for f, a in [(880, 1), (1320, 0.6), (1980, 0.35), (2640, 0.2)]) * env(0.7, 0.002, 3)
    fizz = spectral_filter(noise(0.7), 2000, 9000) * env(0.7, 0.001, 5) * 0.4
    write_wav("hit_shield", reverb(ping + fizz, 0.9, 0.3), 0.7)

    boom = sweep(90, 28, 2.6) * env(2.6, 0.01, 1.6) * 1.4
    roar = spectral_filter(noise(2.6), 40, 1600) * env(2.6, 0.02, 1.3)
    debris = spectral_filter(noise(2.6), 1500, 6000) * env(2.6, 0.001, 4) * 0.3
    write_wav("explosion_big", reverb(boom + roar + debris, 1.8, 0.3))

    write_wav("intercept", reverb(sweep(1800, 600, 0.15, "square") * env(0.15, 0.001, 3) * 0.5 + spectral_filter(noise(0.15), 1000, 6000) * env(0.15, 0.001, 4), 0.4, 0.2), 0.6)

    t = t_axis(1.0)
    sparkle = np.zeros(len(t))
    for index in range(14):
        start = int(index * len(t) / 16)
        f = 900 + index * 140
        seg = np.sin(2 * np.pi * f * t[: len(t) - start]) * np.exp(-t[: len(t) - start] * 9)
        sparkle[start:] += seg * 0.4
    write_wav("teleport", reverb(sparkle + sweep(200, 1200, 1.0) * env(1.0, 0.3, 1) * 0.3, 1.0, 0.35), 0.7)

    charge = sweep(80, 900, 1.4, "saw") * np.linspace(0, 1, int(1.4 * RATE)) ** 2
    charge = spectral_filter(charge, 60, 3000)
    blast = sweep(400, 40, 0.8) * env(0.8, 0.002, 1.5) + spectral_filter(noise(0.8), 100, 4000) * env(0.8, 0.001, 2)
    write_wav("jump", reverb(np.concatenate([charge, blast]), 1.4, 0.35))

    t = t_axis(0.05)
    write_wav("click", np.sin(2 * np.pi * 1800 * t) * env(0.05, 0.001, 4), 0.35)
    t = t_axis(0.09)
    write_wav("select", (np.sin(2 * np.pi * 1200 * t) + 0.5 * np.sin(2 * np.pi * 1800 * t)) * env(0.09, 0.002, 2), 0.4)
    write_wav("order", sweep(700, 1100, 0.12) * env(0.12, 0.003, 2), 0.4)
    write_wav("arm", sweep(500, 1500, 0.14, "tri") * env(0.14, 0.003, 1.5), 0.45)
    write_wav("target", (sweep(1500, 1500, 0.06) + sweep(2250, 2250, 0.06) * 0.5) * env(0.06, 0.001, 2), 0.45)
    write_wav("power_up", sweep(500, 900, 0.1, "square") * env(0.1, 0.002, 1.5) * 0.4, 0.4)
    write_wav("power_down", sweep(800, 400, 0.1, "square") * env(0.1, 0.002, 1.5) * 0.4, 0.35)
    write_wav("deny", spectral_filter(sweep(160, 150, 0.22, "square"), 50, 1500) * env(0.22, 0.005, 1), 0.45)
    door = spectral_filter(noise(0.35), 300, 2500) * env(0.35, 0.03, 2) + sweep(220, 140, 0.35) * env(0.35, 0.01, 2) * 0.4
    write_wav("door", door, 0.4)
    crackle = spectral_filter(noise(1.0), 500, 5000) * (rng.random(RATE) > 0.97) * 2 + spectral_filter(noise(1.0), 100, 800) * 0.3
    write_wav("fire", crackle * env(1.0, 0.1, 1), 0.4)
    write_wav("breach", reverb(pad(spectral_filter(noise(1.2), 1500, 9000) * env(1.2, 0.01, 1.2), sweep(100, 40, 0.4) * env(0.4, 0.002, 2)), 1.0, 0.3), 0.6)
    t = t_axis(0.9)
    write_wav("crew_death", reverb((np.sin(2 * np.pi * 220 * t) + np.sin(2 * np.pi * 207 * t)) * env(0.9, 0.01, 2), 1.0, 0.3), 0.45)
    write_wav("flare", reverb(spectral_filter(noise(2.0), 60, 1200) * env(2.0, 0.6, 1.2), 1.2, 0.3), 0.7)
    write_wav("launch", reverb(spectral_filter(noise(0.6), 400, 3500) * env(0.6, 0.02, 1.5) + sweep(300, 900, 0.6, "tri") * env(0.6, 0.02, 1.5) * 0.3, 0.6, 0.2), 0.6)
    write_wav("cloak", reverb(sweep(1200, 200, 0.8) * env(0.8, 0.05, 1.2), 1.0, 0.4), 0.5)
    t = t_axis(0.25)
    write_wav("pause", (np.sin(2 * np.pi * 523 * t) + np.sin(2 * np.pi * 392 * t)) * env(0.25, 0.005, 2), 0.35)
    write_wav("unpause", (np.sin(2 * np.pi * 523 * t) + np.sin(2 * np.pi * 784 * t)) * env(0.25, 0.005, 2), 0.35)
    t = t_axis(0.45)
    chime = (np.sin(2 * np.pi * 1318 * t) * env(0.45, 0.002, 3) + np.sin(2 * np.pi * 1760 * t) * env(0.45, 0.002, 3) * np.concatenate([np.zeros(int(0.07 * RATE)), np.ones(len(t) - int(0.07 * RATE))]))
    write_wav("buy", reverb(chime, 0.7, 0.25), 0.45)
    ratchet = np.zeros(int(0.5 * RATE))
    for index in range(6):
        start = int(index * 0.07 * RATE)
        click = spectral_filter(noise(0.03), 1000, 6000) * env(0.03, 0.001, 3)
        ratchet[start: start + len(click)] += click
    write_wav("repair", ratchet, 0.45)
    t = t_axis(0.7)
    chord = sum(np.sin(2 * np.pi * f * t) * env(0.7, 0.01 + i * 0.06, 1.5) for i, f in enumerate([523, 659, 784, 1046]))
    write_wav("upgrade", reverb(chord, 0.8, 0.3), 0.45)
    t = t_axis(1.4)
    alarm = np.sign(np.sin(2 * np.pi * 660 * t)) * (np.sin(2 * np.pi * 2.5 * t) > 0) * 0.5
    write_wav("alarm", spectral_filter(alarm, 200, 2500) * env(1.4, 0.01, 0.5), 0.35)


# --- Music ------------------------------------------------------------------------------------------------------

MUSIC_RATE = 32000


def note(midi):
    return 440.0 * 2 ** ((midi - 69) / 12)


def saw_stack(freq, seconds, detune=0.006, voices=3):
    t = t_axis(seconds, MUSIC_RATE)
    total = np.zeros(len(t))
    for v in range(voices):
        f = freq * (1 + detune * (v - (voices - 1) / 2))
        phase = rng.random()
        total += 2 * ((f * t + phase) % 1.0) - 1
    return total / voices


def chord_pad(chords, seconds_each, brightness=1100):
    total_len = int(len(chords) * seconds_each * MUSIC_RATE)
    left = np.zeros(total_len)
    right = np.zeros(total_len)
    for index, chord in enumerate(chords):
        start = int(index * seconds_each * MUSIC_RATE)
        length = int(seconds_each * 1.5 * MUSIC_RATE)
        segment_seconds = length / MUSIC_RATE
        body = np.zeros(length)
        for m in chord:
            body += saw_stack(note(m), segment_seconds)
        shape = np.minimum(1, np.minimum(np.linspace(0, 3, length), np.linspace(3, 0, length)))
        body *= shape
        for offset in range(length):
            pass
            break
        end = start + length
        wrap = max(0, end - total_len)
        main = length - wrap
        left[start: start + main] += body[:main]
        right[start: start + main] += body[:main] * 0.92
        if wrap:
            left[:wrap] += body[main:]
            right[:wrap] += body[main:] * 0.92
    return spectral_filter(left, 60, brightness, MUSIC_RATE), spectral_filter(right, 60, brightness * 0.95, MUSIC_RATE)


def bells(total_seconds, scale, density, seed_value):
    local = np.random.default_rng(seed_value)
    out = np.zeros(int(total_seconds * MUSIC_RATE))
    step = 0.5
    time = 0.0
    while time < total_seconds - 3:
        if local.random() < density:
            m = scale[local.integers(len(scale))]
            length = 2.6
            t = t_axis(length, MUSIC_RATE)
            tone = (np.sin(2 * np.pi * note(m) * t) + 0.3 * np.sin(2 * np.pi * note(m) * 2.01 * t) + 0.12 * np.sin(2 * np.pi * note(m) * 3.98 * t)) * np.exp(-t * 2.2)
            start = int(time * MUSIC_RATE)
            out[start: start + len(tone)] += tone * 0.35
        time += step
    return out


def stereo_out(name, left, right, loop_seconds):
    left = reverb(left, 3.0, 0.45, MUSIC_RATE)
    right = reverb(right, 3.2, 0.45, MUSIC_RATE)
    peak = max(np.max(np.abs(left)), np.max(np.abs(right))) + 1e-9
    left, right = left / peak * 0.8, right / peak * 0.8
    # Cross-fade the end into the start so the loop is seamless
    fade = int(2.0 * MUSIC_RATE)
    for channel in (left, right):
        channel[:fade] = channel[:fade] * np.linspace(0, 1, fade) + channel[-fade:] * np.linspace(1, 0, fade)
    left, right = left[: int(loop_seconds * MUSIC_RATE)], right[: int(loop_seconds * MUSIC_RATE)]
    data = np.stack([left, right], axis=1)
    raw = os.path.join(OUT, name + ".raw.wav")
    with wave.open(raw, "wb") as file:
        file.setnchannels(2)
        file.setsampwidth(2)
        file.setframerate(MUSIC_RATE)
        file.writeframes((data * 32767).astype(np.int16).tobytes())
    subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", raw, "-c:a", "libvorbis", "-q:a", "4", os.path.join(OUT, name + ".ogg")], check=True)
    os.remove(raw)


def make_explore():
    # A minor drift: Am - F - C - G - Am - Dm - F - E, eight seconds a chord
    chords = [[45, 57, 60, 64], [41, 53, 57, 60], [48, 55, 60, 64], [43, 55, 59, 62], [45, 57, 60, 64], [38, 50, 57, 62], [41, 53, 57, 60], [40, 52, 56, 59]]
    seconds = 8.0
    total = len(chords) * seconds
    left, right = chord_pad(chords, seconds, 900)
    sparkle = bells(total + 2, [69, 72, 74, 76, 79, 81, 84], 0.18, 3)[: len(left)]
    t = t_axis(total, MUSIC_RATE)
    drone = 0.35 * np.sin(2 * np.pi * note(33) * t) * (0.7 + 0.3 * np.sin(2 * np.pi * t / 16))
    stereo_out("music_explore", left + sparkle * 0.9 + drone, right + np.roll(sparkle, 900) * 0.9 + drone, total)


def make_combat():
    bpm = 118
    beat = 60 / bpm
    bars = 16
    total = bars * 4 * beat
    n = int(total * MUSIC_RATE)
    left = np.zeros(n)
    right = np.zeros(n)
    progression = [[50, 62, 65, 69], [46, 58, 62, 65], [41, 53, 57, 60], [48, 55, 60, 64]]
    # Pads
    pad_left, pad_right = chord_pad(progression * 4, 4 * beat, 1400)
    left += pad_left[:n] * 0.55
    right += pad_right[:n] * 0.55
    for bar in range(bars):
        chord = progression[bar % 4]
        for step in range(16):
            at = int((bar * 4 + step / 4) * beat * MUSIC_RATE)
            sixteenth = beat / 4
            # Bass on eighths
            if step % 2 == 0:
                tone = saw_stack(note(chord[0] - 12), sixteenth * 1.8, 0.003, 2) * env(sixteenth * 1.8, 0.002, 1.5, MUSIC_RATE)
                tone = spectral_filter(tone, 30, 700, MUSIC_RATE)
                left[at: at + len(tone)] += tone[: n - at] * 0.9
                right[at: at + len(tone)] += tone[: n - at] * 0.9
            # Arpeggio on sixteenths
            m = chord[1:][step % 3] + (12 if step % 8 >= 6 else 0)
            t = t_axis(sixteenth * 0.9, MUSIC_RATE)
            arp = np.sign(np.sin(2 * np.pi * note(m) * t)) * env(sixteenth * 0.9, 0.002, 2.5, MUSIC_RATE) * 0.16
            arp = spectral_filter(arp, 200, 3200, MUSIC_RATE)
            pan = 0.5 + 0.4 * np.sin(step)
            left[at: at + len(arp)] += arp[: n - at] * (1 - pan)
            right[at: at + len(arp)] += arp[: n - at] * pan
            # Drums
            if step in (0, 8) or (bar % 2 == 1 and step == 14):
                kick = sweep(140, 42, 0.32, rate=MUSIC_RATE) * env(0.32, 0.002, 2.2, MUSIC_RATE)
                left[at: at + len(kick)] += kick[: n - at] * 1.1
                right[at: at + len(kick)] += kick[: n - at] * 1.1
            if step in (4, 12):
                snare = spectral_filter(noise(0.22, MUSIC_RATE), 900, 6000, MUSIC_RATE) * env(0.22, 0.001, 3, MUSIC_RATE) * 0.55
                left[at: at + len(snare)] += snare[: n - at]
                right[at: at + len(snare)] += snare[: n - at]
            if step % 2 == 1:
                hat = spectral_filter(noise(0.05, MUSIC_RATE), 6000, 14000, MUSIC_RATE) * env(0.05, 0.001, 4, MUSIC_RATE) * 0.18
                left[at: at + len(hat)] += hat[: n - at] * 0.8
                right[at: at + len(hat)] += hat[: n - at]
    stereo_out("music_combat", left, right, total)


def make_title():
    chords = [[38, 50, 53, 57], [34, 46, 53, 58], [36, 48, 55, 60], [33, 45, 52, 57]]
    seconds = 10.0
    total = len(chords) * seconds
    left, right = chord_pad(chords, seconds, 700)
    t = t_axis(total, MUSIC_RATE)
    low = 0.45 * np.sin(2 * np.pi * note(26) * t) * (0.6 + 0.4 * np.sin(2 * np.pi * t / 20))
    sparkle = bells(total + 2, [62, 65, 69, 72, 74], 0.1, 9)[: len(left)]
    stereo_out("music_title", left + low + sparkle * 0.7, right + low + np.roll(sparkle, 1400) * 0.7, total)


if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    make_effects()
    make_explore()
    make_combat()
    make_title()
    print("audio written to", os.path.abspath(OUT))

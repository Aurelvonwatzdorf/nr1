# Hintergrundmusik für das ganze Video, lokal berechnet (keine Credits, keine Schleife):
#   python3 tools/musik.py            -> sfx/musik.wav (48 kHz stereo, genau so lang wie das Video)
# Aufbau: ruhiger Akkord-Teppich (a-Moll, 4 Akkorde je 8 s, weich überblendet) + leise einzelne
# Töne darüber. Weil die Datei in einem Stück für die ganze Länge berechnet wird, gibt es keine
# Schleifen-Naht. Die ersten 6 s und die letzten 7 s tragen die Erkennungsmelodie (Intro/Outro),
# die in denselben Teppich übergeht. Kein Gesang, keine Stimmen.
import json, os, wave
import numpy as np

os.chdir(os.path.join(os.path.dirname(os.path.abspath(__file__)), '..'))
SR = 48000
T = json.load(open('timeline.json'))
TOTAL = T[-1]['start'] + T[-1]['dur']
N = int(round(TOTAL * SR))
t = np.arange(N) / SR
rng = np.random.default_rng(7)


def hz(m):  # MIDI-Nummer -> Frequenz
    return 440.0 * 2 ** ((m - 69) / 12)


def pad(f, pan):
    """Weicher Dauerton: Grundton + leise Obertöne, links/rechts leicht verstimmt."""
    out = np.zeros((N, 2), np.float32)
    for ch, det in ((0, -0.18), (1, 0.18)):
        ph = rng.uniform(0, 6.28)
        s = (np.sin(2 * np.pi * (f + det) * t + ph) + 0.28 * np.sin(2 * np.pi * 2 * (f + det) * t + ph * 2)
             + 0.10 * np.sin(2 * np.pi * 3 * (f + det) * t))
        lfo = 1 + 0.12 * np.sin(2 * np.pi * rng.uniform(0.05, 0.11) * t + rng.uniform(0, 6.28))
        out[:, ch] = s * lfo * (0.5 + (0.5 - abs(pan - ch)) * 0.6)
    return out


CH = 8.0  # Sekunden je Akkord
CHORDS = [[45, 52, 57, 60, 64], [41, 48, 57, 60, 64], [48, 55, 59, 64, 67], [40, 52, 55, 59, 62]]  # Am, Fmaj7, Cmaj7, Em7
mix = np.zeros((N, 2), np.float32)
for ci, chord in enumerate(CHORDS):
    # Hüllkurve: dieser Akkord ist an, wenn er dran ist; Übergänge 3 s als Sinus-Blende (Summe konstant)
    pos = (t / CH - ci) % len(CHORDS)            # 0..4, Akkord aktiv für pos in [0,1)
    x = np.clip(np.minimum(pos + 0.1875, 1.1875 - pos) / 0.375, 0, 1)   # 3 s Blende um die Grenzen
    x = np.where(pos > len(CHORDS) - 0.1875, np.clip((pos - (len(CHORDS) - 0.1875)) / 0.375, 0, 1), x)
    env = np.sin(x * np.pi / 2) ** 2
    for ni, m in enumerate(chord):
        mix += pad(hz(m), ni / (len(chord) - 1)) * env[:, None].astype(np.float32) * (0.9 if ni == 0 else 0.55)
mix *= 0.11


def note(start, m, gain, dec=1.6, pan=0.5):
    """Einzelner glockiger Ton mit Echo."""
    for k, (dl, g) in enumerate(((0, 1.0), (0.42, 0.35), (0.84, 0.14))):
        a = int((start + dl) * SR)
        if a >= N or a < 0: continue
        n = min(int(dec * 3 * SR), N - a)
        tt = np.arange(n) / SR
        f = hz(m)
        s = (np.sin(2 * np.pi * f * tt) + 0.35 * np.sin(2 * np.pi * 2 * f * tt) * np.exp(-tt * 3)
             + 0.12 * np.sin(2 * np.pi * 3.01 * f * tt) * np.exp(-tt * 5))
        s *= np.exp(-tt / dec) * np.minimum(tt / 0.012, 1) * gain * g
        p = pan if k % 2 == 0 else 1 - pan
        mix[a:a + n, 0] += (s * (1 - p * 0.7)).astype(np.float32)
        mix[a:a + n, 1] += (s * (0.3 + p * 0.7)).astype(np.float32)


# leise Einzeltöne: alle 2 s ein Ton aus dem aktuellen Akkord, zufällig gewählt (kein wiederkehrendes Muster)
tt = 6.5
while tt < TOTAL - 8:
    chord = CHORDS[int(tt / CH) % len(CHORDS)]
    if rng.random() < 0.8:
        note(tt, rng.choice(chord[2:]) + 12, 0.035 * rng.uniform(0.7, 1.0), pan=rng.uniform(0.2, 0.8))
    tt += 2.0

# Erkennungsmelodie: Intro (steigt auf) und Outro (dieselben Töne, kommt zur Ruhe)
MOTIF = [(0.25, 69), (0.95, 72), (1.65, 76), (2.7, 74), (3.4, 71), (4.1, 72), (5.0, 69)]
for dt, m in MOTIF:
    note(dt, m, 0.16, dec=1.9, pan=0.4)
    note(dt, m - 12, 0.06, dec=1.9, pan=0.6)
o = TOTAL - 7.2
for dt, m in [(0.2, 76), (0.9, 72), (1.6, 74), (2.6, 71), (3.4, 72), (4.4, 69)]:
    note(o + dt, m, 0.16, dec=2.4, pan=0.4)
    note(o + dt, m - 12, 0.06, dec=2.4, pan=0.6)

# sanfter Tiefpass (zweimal gleitender Mittelwert), damit nichts spitz klingt
k = np.ones(9, np.float32) / 9
for ch in (0, 1):
    mix[:, ch] = np.convolve(np.convolve(mix[:, ch], k, 'same'), k, 'same')
# Ein- und Ausblenden
mix *= np.minimum(t / 1.2, 1)[:, None].astype(np.float32)
mix *= np.minimum((TOTAL - t) / 2.5, 1).clip(0, 1)[:, None].astype(np.float32)
# auf festen Pegel bringen: Teppich-Teil (ohne Intro/Outro) auf -25 dBFS RMS, Spitzen begrenzen
body = mix[int(8 * SR):int((TOTAL - 9) * SR)]
mix *= 10 ** (-25 / 20) / float(np.sqrt(np.mean(body ** 2)))
mix = np.tanh(mix * 1.5) / 1.5
w = wave.open('sfx/musik.wav', 'wb')
w.setnchannels(2); w.setsampwidth(2); w.setframerate(SR)
w.writeframes((np.clip(mix, -1, 1) * 32767).astype('<i2').tobytes()); w.close()
# Kontrolle: Lautstärke in 20-s-Fenstern muss gleichmäßig sein
win = [20 * np.log10(np.sqrt(np.mean(mix[int(a * SR):int((a + 20) * SR)] ** 2)) + 1e-9) for a in np.arange(10, TOTAL - 30, 20)]
print(f'sfx/musik.wav: {TOTAL:.2f} s, Teppich {np.mean(win):.1f} dBFS RMS, Schwankung {max(win) - min(win):.2f} dB, Spitze {20 * np.log10(np.abs(mix).max()):.1f} dBFS')

# Schnitt: setzt Szenen-Clips, Musik, Soundeffekte und (später) Stimmen zum Video zusammen.
#   python3 tools/assemble.py all        Zeitplan-SRT + Video + Ton -> ausgabe/video_sauber.mp4
#   python3 tools/assemble.py video|audio|mux|srt|check      einzelne Schritte
#   python3 tools/assemble.py stimmen    Favoriten aus takes/ einmischen -> ausgabe/video_final.mp4
#   python3 tools/assemble.py anpassen   Bilddauern an die echten Sprechlängen anpassen, alles neu
#                                        bauen, dann "stimmen" (kostet keine Credits)
#   python3 tools/assemble.py zuruecksetzen   Sprechlängen wieder auf den Plan (lines.json) stellen
# Es gibt keine Untertitel und keinen Text im Video. Der Sprechtext steht im Studio (tools/studio.py).
import json, os, sys, subprocess, shutil

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
os.chdir(ROOT)
sys.path.insert(0, os.path.join(ROOT, 'tools'))
W, H, FPS = 1920, 1080, 30
FF = os.environ.get('FFMPEG') or '/opt/homebrew/opt/ffmpeg-full/bin/ffmpeg'
if not os.path.exists(FF): FF = '/opt/homebrew/bin/ffmpeg'
FFPROBE = os.path.join(os.path.dirname(FF), 'ffprobe')
SEG, TMP = 'ausgabe/seg', 'ausgabe/tmp'
PAUSE = 0.6          # Sekunden Luft nach jeder Zeile (wie im Plan: Wörter/2,45 + 0,6)
VOICE_LUFS = -16.0   # Ziel-Lautheit der Stimmen
DUCK_DB = -6.0       # Musik und Effekte beim Sprechen absenken


def load():
    global T, L, TOTAL, TOTAL_FR, TOTAL_T
    T = json.load(open('timeline.json')); L = json.load(open('lines.json'))
    TOTAL = T[-1]['start'] + T[-1]['dur']
    TOTAL_FR = round(TOTAL * FPS); TOTAL_T = TOTAL_FR / FPS


def run(cmd, capture=False):
    cmd = [FF, '-hide_banner', '-v', 'error', '-y'] + cmd
    r = subprocess.run(cmd, capture_output=capture, text=capture)
    if r.returncode:
        raise SystemExit('ffmpeg-Fehler: ' + ' '.join(cmd[:30]) + ('\n' + r.stderr if capture else ''))
    return r


def probe(path, stream, what='duration'):
    out = subprocess.run([FFPROBE, '-v', 'error', '-select_streams', stream, '-count_frames' if what == 'nb_read_frames' else '-hide_banner',
                          '-show_entries', f'stream={what}', '-of', 'csv=p=0', path], capture_output=True, text=True).stdout.strip()
    try: return float(out.split('\n')[0])
    except ValueError: return None


# ---------------------------------------------------------------- Video
def scene_frames():
    """Szenengrenzen aus den Startzeiten auf Bilder runden (kein Aufsummieren von Rundungsfehlern)."""
    return [(round(T[i + 1]['start'] * FPS) if i + 1 < len(T) else TOTAL_FR) - round(x['start'] * FPS) for i, x in enumerate(T)]


def build_segment(x, n):
    """Ken-Burns-Szenen sind schon fertig kodiert (clips/kbNNN.mp4, genau n Bilder) und werden nur
    kopiert. Kling-Clips werden mit denselben Einstellungen auf genau n Bilder gebracht. Ein Clip
    wird nie verlängert: Bewegung läuft immer bis zum Schnitt."""
    import kb
    k = x['k']
    kbf, kl, out = f'clips/kb{k:03d}.mp4', f'clips/kling_{x["img"]}.mp4', f'{SEG}/seg{k:03d}.mp4'
    if x['kling'] and os.path.exists(kl):
        have = probe(kl, 'v:0')
        if have is None or have + 1e-3 < n / FPS:
            raise SystemExit(f'Szene {k}: Kling-Clip {kl} ist {have} s lang, die Szene braucht {n / FPS:.2f} s. '
                             'Szene kürzen (timeline.py deckelt auf 5 s) – kein Standbild anhängen.')
        run(['-i', kl, '-an', '-vf', f'scale={W}:{H}:force_original_aspect_ratio=increase:flags=lanczos,crop={W}:{H},setsar=1,'
             f'fps={FPS},format=yuv420p', '-frames:v', str(n), '-c:v', 'libx264'] + kb.ENC + ['-pix_fmt', 'yuv420p', '-r', str(FPS), out])
        return 'kling'
    if not os.path.exists(kbf):
        raise SystemExit(f'Szene {k}: {kbf} fehlt. Erst python3 tools/render_stills.py laufen lassen.')
    have = probe(kbf, 'v:0', 'nb_frames')
    if have != n:
        raise SystemExit(f'Szene {k}: {kbf} hat {have} Bilder, gebraucht werden {n}. python3 tools/render_stills.py')
    shutil.copyfile(kbf, out)
    return 'standbild mit kamerafahrt'


def video():
    os.makedirs(SEG, exist_ok=True); os.makedirs(TMP, exist_ok=True)
    for f in os.listdir(SEG): os.remove(os.path.join(SEG, f))
    frames = scene_frames()
    assert sum(frames) == TOTAL_FR
    from concurrent.futures import ThreadPoolExecutor
    with ThreadPoolExecutor(4) as ex:
        whats = list(ex.map(lambda a: build_segment(*a), zip(T, frames)))
    with open(f'{SEG}/list.txt', 'w') as lst:
        for x in T: lst.write(f"file 'seg{x['k']:03d}.mp4'\n")
    run(['-f', 'concat', '-safe', '0', '-i', f'{SEG}/list.txt', '-c', 'copy', f'{TMP}/video_only.mp4'])
    got = probe(f'{TMP}/video_only.mp4', 'v:0', 'nb_frames')
    print(f'  {whats.count("kling")} Kling-Clips, {len(whats) - whats.count("kling")} Standbild-Szenen, {int(got)} Bilder (Soll {TOTAL_FR})')
    assert got == TOTAL_FR, 'Bildanzahl stimmt nicht'


# ---------------------------------------------------------------- Ton (Musik + Effekte)
FMT = 'aresample=48000,aformat=sample_fmts=fltp:sample_rates=48000:channel_layouts=stereo'


def audio():
    """Musik (durchgehend, eine Datei über die ganze Länge) + Effekte -> ausgabe/tmp/ton.wav"""
    os.makedirs(TMP, exist_ok=True)
    P = json.load(open('sfx_plan.json'))
    assert abs(P['total'] - TOTAL) < 0.05, 'sfx_plan.json ist veraltet: python3 tools/sfx_plan.py'
    m = P['music']
    md = probe(m['file'], 'a:0')
    assert md and md >= TOTAL - 0.05, f'Musik ist {md} s lang, Video {TOTAL:.2f} s: python3 tools/musik.py'
    inputs, parts, labels = ['-i', m['file']], [f'[0:a]{FMT},volume={m["gain_db"]}dB[mu]'], ['[mu]']
    for ev in P['events']:
        idx = inputs.count('-i'); inputs += ['-i', ev['file']]
        c = f'[{idx}:a]{FMT},atrim=0:{ev["dur"]},asetpts=PTS-STARTPTS'
        if ev.get('fade_out'): c += f',afade=t=out:st={max(0, ev["dur"] - ev["fade_out"]):.3f}:d={ev["fade_out"]}'
        c += f',volume={ev["gain_db"]}dB,adelay={int(round(ev["t"] * 1000))}:all=1[e{idx}]'
        parts.append(c); labels.append(f'[e{idx}]')
    parts.append(''.join(labels) + f'amix=inputs={len(labels)}:normalize=0:duration=longest:dropout_transition=0,'
                 f'alimiter=limit=0.891:level=0,atrim=0:{TOTAL_T:.3f},apad=whole_dur={TOTAL_T:.3f}[out]')
    fs = f'{TMP}/audio_filter.txt'
    open(fs, 'w').write(';\n'.join(parts))
    run(inputs + ['-/filter_complex', fs, '-map', '[out]', '-ar', '48000', '-ac', '2', '-c:a', 'pcm_s16le', f'{TMP}/ton.wav'])
    print(f'  Musik + {len(labels) - 1} Effekte')


def mux(ton=None, out='ausgabe/video_sauber.mp4'):
    run(['-i', f'{TMP}/video_only.mp4', '-i', ton or f'{TMP}/ton.wav', '-map', '0:v', '-map', '1:a', '-c:v', 'copy',
         '-c:a', 'aac', '-b:a', '192k', '-t', f'{TOTAL_T:.3f}', '-movflags', '+faststart', out])


# ---------------------------------------------------------------- Zeitplan (getrennte Datei, nicht im Bild)
def srt():
    def ts(s):
        ms = int(round(s * 1000))
        return f'{ms // 3600000:02d}:{ms // 60000 % 60:02d}:{ms // 1000 % 60:02d},{ms % 1000:03d}'
    os.makedirs('ausgabe', exist_ok=True)
    txt = ''.join(f"{n}\n{ts(l['start'])} --> {ts(l['start'] + l['dur'])}\n{l['sp']}: {l['text']}\n\n" for n, l in enumerate(L, 1))
    for p in ('ausgabe/zeitplan.srt', 'zeitplan.srt'): open(p, 'w', encoding='utf-8').write(txt)


# ---------------------------------------------------------------- Stimmen
def read_wav(path):
    import numpy as np
    raw = subprocess.run([FF, '-v', 'error', '-i', path, '-f', 'f32le', '-ac', '2', '-ar', '48000', '-'], capture_output=True).stdout
    return np.frombuffer(raw, np.float32).reshape(-1, 2).copy()


def favorites():
    """{zeile: take} für alle Zeilen mit Favorit."""
    p = 'takes/takes.json'
    if not os.path.exists(p): return {}
    out = {}
    for k, v in json.load(open(p)).get('lines', {}).items():
        fav = v.get('fav')
        tk = next((t for t in v.get('takes', []) if t['n'] == fav), None)
        if tk and os.path.exists(os.path.join('takes', tk['file'])): out[int(k)] = tk
    return out


def clean_take(tk, out):
    """Stille am Rand weg, Hochpass 80 Hz, leichte Kompression, Lautheit auf VOICE_LUFS."""
    src = os.path.join('takes', tk['file'])
    a, d = tk['speech_start'], tk['speech_len']
    a0 = max(0, a - 0.04)
    pre = f'atrim={a0:.3f}:{a + d + 0.08:.3f},asetpts=PTS-STARTPTS,highpass=f=80,acompressor=threshold=-20dB:ratio=2.5:attack=8:release=160:makeup=1'
    r = subprocess.run([FF, '-hide_banner', '-i', src, '-af', pre + ',loudnorm=print_format=json', '-f', 'null', '-'], capture_output=True, text=True)
    try:
        meas = float(json.loads(r.stderr[r.stderr.rindex('{'):r.stderr.rindex('}') + 1])['input_i'])
    except (ValueError, KeyError):
        meas = None
    gain = 0.0 if meas is None or meas < -60 else max(-20.0, min(30.0, VOICE_LUFS - meas))
    run(['-i', src, '-af', pre + f',volume={gain:.2f}dB,alimiter=limit=0.84:level=0,afade=t=in:d=0.02,areverse,afade=t=in:d=0.04,areverse',
         '-ar', '48000', '-ac', '1', '-c:a', 'pcm_s16le', out])
    return gain


def stimmen():
    import numpy as np
    fav = favorites()
    missing = [l['i'] for l in L if l['i'] not in fav]
    if not fav:
        print('  Keine Favoriten in takes/takes.json. Erst im Studio aufnehmen: python3 tools/studio.py'); return
    assert os.path.exists(f'{TMP}/ton.wav') and os.path.exists(f'{TMP}/video_only.mp4'), 'Erst: python3 tools/assemble.py all'
    bed = read_wav(f'{TMP}/ton.wav')
    N = len(bed); SR = 48000
    voice = np.zeros((N, 2), np.float32); duck = np.zeros(N, np.float32)
    os.makedirs(f'{TMP}/stimmen', exist_ok=True)
    late = []
    for i, tk in sorted(fav.items()):
        l = L[i]
        out = f'{TMP}/stimmen/z{i:02d}.wav'
        clean_take(tk, out)
        v = read_wav(out)
        a = int(round(l['start'] * SR)); n = min(len(v), N - a)
        voice[a:a + n] += v[:n]
        duck[max(0, a - int(0.15 * SR)):min(N, a + n + int(0.25 * SR))] = 1
        nxt = L[i + 1]['start'] if i + 1 < len(L) else TOTAL
        if l['start'] + len(v) / SR > nxt + 0.05: late.append((i, round(l['start'] + len(v) / SR - nxt, 2)))
    # Absenkung weich ein- und ausblenden (0,3 s)
    k = int(0.3 * SR); kern = np.hanning(k).astype(np.float32); kern /= kern.sum()
    env = np.convolve(duck, kern, 'same')
    g = 10 ** (DUCK_DB / 20)
    mix = bed * (1 - env * (1 - g))[:, None] + voice
    mix = np.tanh(mix / 0.95) * 0.95 if np.abs(mix).max() > 0.95 else mix
    import wave
    w = wave.open(f'{TMP}/ton_final.wav', 'wb'); w.setnchannels(2); w.setsampwidth(2); w.setframerate(SR)
    w.writeframes((np.clip(mix, -1, 1) * 32767).astype('<i2').tobytes()); w.close()
    mux(f'{TMP}/ton_final.wav', 'ausgabe/video_final.mp4')
    print(f'  {len(fav)} von {len(L)} Zeilen mit Stimme -> ausgabe/video_final.mp4')
    if missing: print('  FEHLEN (bleiben still): Zeilen', missing)
    if late: print('  LÄNGER ALS GEPLANT (Zeile, Sekunden über den Start der nächsten Zeile):', late,
                   '\n  -> python3 tools/assemble.py anpassen')


def anpassen():
    """Bild folgt Stimme: Zeilen mit Favorit bekommen die echte Sprechlänge + Pause; alle Starts,
    Bilddauern, Musik und Effekte werden neu berechnet. Der Plan bleibt in lines.json als plan_dur."""
    fav = favorites()
    if not fav: print('  Keine Favoriten – nichts anzupassen.'); return
    t = 6.0; ch = []
    for l in L:
        l.setdefault('plan_dur', l['dur'])
        if l['i'] in fav:
            neu = round(fav[l['i']]['speech_len'] + 0.12 + PAUSE, 2)
            if abs(neu - l['dur']) > 0.05: ch.append((l['i'], l['dur'], neu))
            l['dur'] = neu
        l['start'] = round(t, 2); t += l['dur']
    json.dump(L, open('lines.json', 'w'), ensure_ascii=False, indent=1)
    print(f'  {len(ch)} Zeilen geändert (Zeile, alt, neu):', ch[:12], '…' if len(ch) > 12 else '')
    rebuild(); stimmen()


def zuruecksetzen():
    t = 6.0
    for l in L:
        l['dur'] = l.pop('plan_dur', l['dur']); l['start'] = round(t, 2); t += l['dur']
    json.dump(L, open('lines.json', 'w'), ensure_ascii=False, indent=1)
    rebuild()


def rebuild():
    for s in ('timeline.py', 'render_stills.py', 'musik.py', 'sfx_plan.py'):
        print(' ', s); r = subprocess.run([sys.executable, f'tools/{s}'], capture_output=True, text=True)
        if r.returncode: raise SystemExit(r.stdout + r.stderr)
        print('   ', r.stdout.strip().split('\n')[-1])
    load(); srt(); video(); audio(); mux(); check()


def check():
    for p in ['ausgabe/video_sauber.mp4', 'ausgabe/video_final.mp4']:
        if os.path.exists(p):
            v, a = probe(p, 'v:0'), probe(p, 'a:0')
            ok = v and a and abs(v - TOTAL) <= 0.1 and abs(a - TOTAL) <= 0.1
            print(f'  {p}: Video {v} s, Ton {a} s, Soll {TOTAL:.2f} s ->', 'OK' if ok else 'ABWEICHUNG (veraltet?)')


if __name__ == '__main__':
    st = (sys.argv[1:] or ['all'])[0]
    load()
    print(f'ffmpeg={FF}  Gesamt={TOTAL_T:.3f}s ({TOTAL_FR} Bilder)')
    if st in ('all', 'srt'): srt(); print('zeitplan.srt geschrieben')
    if st in ('all', 'video'): print('Video …'); video()
    if st in ('all', 'audio'): print('Ton …'); audio()
    if st in ('all', 'video', 'audio', 'mux'): print('Mux …'); mux()
    if st == 'stimmen': print('Stimmen …'); stimmen()
    if st == 'anpassen': print('Anpassen …'); anpassen()
    if st == 'zuruecksetzen': zuruecksetzen()
    check()

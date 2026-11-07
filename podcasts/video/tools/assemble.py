# Schnitt: setzt Szenen-Clips + Soundeffekte zum fertigen Video zusammen.
#   python3 tools/assemble.py [all|video|audio|mux|hilfe|srt] [--draft]
# Umgebungsvariablen: FFMPEG (Standard: ffmpeg-full, falls vorhanden, sonst /opt/homebrew/bin/ffmpeg),
#                     FFPROBE, TEXTMODE=drawtext|png (Standard: drawtext, wenn verfügbar)
# --draft: schnelles Encoding (Probelauf); fehlende Szenen werden als Standbild/Schwarz ersetzt.
import json, os, sys, subprocess, shutil, math
from PIL import ImageFont, Image, ImageDraw

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
os.chdir(ROOT)
W, H, FPS = 1920, 1080, 30
FULL = '/opt/homebrew/opt/ffmpeg-full/bin/ffmpeg'


def has_drawtext(ff):
    try:
        out = subprocess.run([ff, '-hide_banner', '-filters'], capture_output=True, text=True).stdout
        return ' drawtext ' in out
    except Exception:
        return False


FF = os.environ.get('FFMPEG') or (FULL if os.path.exists(FULL) else '/opt/homebrew/bin/ffmpeg')
FFPROBE = os.environ.get('FFPROBE') or (os.path.join(os.path.dirname(FF), 'ffprobe')
                                        if os.path.exists(os.path.join(os.path.dirname(FF), 'ffprobe')) else 'ffprobe')
# ffmpeg für drawtext: das gewählte, wenn es drawtext kann, sonst ffmpeg-full
FF_TEXT = FF if has_drawtext(FF) else (FULL if os.path.exists(FULL) and has_drawtext(FULL) else None)
TEXTMODE = os.environ.get('TEXTMODE') or ('drawtext' if FF_TEXT else 'png')

DRAFT = '--draft' in sys.argv
ENC = ['-c:v', 'libx264', '-preset', 'ultrafast' if DRAFT else 'medium', '-crf', '28' if DRAFT else '18',
       '-pix_fmt', 'yuv420p', '-r', str(FPS)]
T = json.load(open('timeline.json'))
L = json.load(open('lines.json'))
TOTAL = T[-1]['start'] + T[-1]['dur']
TOTAL_FR = round(TOTAL * FPS)
TOTAL_T = TOTAL_FR / FPS
SEG = 'ausgabe/seg'
TMP = 'ausgabe/tmp'
os.makedirs(SEG, exist_ok=True)
os.makedirs(TMP, exist_ok=True)


def run(cmd, ff=None):
    cmd = [ff or FF, '-hide_banner', '-v', 'error', '-y'] + cmd
    r = subprocess.run(cmd)
    if r.returncode:
        raise SystemExit('ffmpeg-Fehler: ' + ' '.join(cmd[:40]))


def probe_dur(path, stream):
    out = subprocess.run([FFPROBE, '-v', 'error', '-select_streams', stream, '-show_entries',
                          'stream=duration', '-of', 'csv=p=0', path], capture_output=True, text=True).stdout.strip()
    try:
        return float(out.split('\n')[0])
    except ValueError:
        return None


# ---------------------------------------------------------------- Video
def scene_frames():
    """Szenengrenzen aus kumulierten Startzeiten auf Frames runden (kein Aufsummieren)."""
    res = []
    for i, x in enumerate(T):
        a = round(x['start'] * FPS)
        b = round(T[i + 1]['start'] * FPS) if i + 1 < len(T) else TOTAL_FR
        res.append(b - a)
    return res


def build_segment(x, n):
    k = x['k']
    kb, kl, img = f'clips/kb{k:02d}.mp4', f'clips/kling_{k:02d}.mp4', f'img/s{k:02d}.png'
    out = f'{SEG}/seg{k:02d}.mp4'
    norm = (f'scale={W}:{H}:force_original_aspect_ratio=increase,crop={W}:{H},setsar=1,fps={FPS},'
            f'tpad=stop_mode=clone:stop_duration={x["dur"] + 2},trim=end_frame={n},setpts=PTS-STARTPTS,format=yuv420p')
    if x['kling'] and os.path.exists(kl):
        src, what = ['-i', kl], 'kling'
    elif os.path.exists(kb):
        src, what = ['-i', kb], 'kb' + (' (Ersatz für Kling)' if x['kling'] else '')
    elif os.path.exists(img):
        src, what = ['-loop', '1', '-framerate', str(FPS), '-t', str(x['dur'] + 1), '-i', img], 'PLATZHALTER Standbild'
    else:
        src, what = ['-f', 'lavfi', '-i', f'color=c=black:s={W}x{H}:r={FPS}:d={x["dur"] + 1}'], 'PLATZHALTER schwarz'
    # Kling: höchstens dur abspielen -> trim end_frame schneidet ab, tpad hält das letzte Bild
    run(src + ['-an', '-vf', norm, '-frames:v', str(n)] + ENC + [out])
    return what


def video():
    frames = scene_frames()
    assert sum(frames) == TOTAL_FR
    lst = open(f'{SEG}/list.txt', 'w')
    used = {}
    from concurrent.futures import ThreadPoolExecutor
    with ThreadPoolExecutor(4) as ex:
        whats = list(ex.map(lambda a: build_segment(*a), zip(T, frames)))
    for x, w in zip(T, whats):
        lst.write(f"file 'seg{x['k']:02d}.mp4'\n")
        used.setdefault(w, []).append(x['k'])
    lst.close()
    run(['-f', 'concat', '-safe', '0', '-i', f'{SEG}/list.txt', '-c', 'copy', f'{TMP}/video_only.mp4'])
    for w, ks in used.items():
        print(f'  {w}: {len(ks)} Szenen {ks if len(ks) < 20 else ""}')


# ---------------------------------------------------------------- Ton
def audio():
    out = f'{TMP}/ton.m4a'
    plan = os.environ.get('SFX_PLAN', 'sfx_plan.json')
    if not os.path.exists(plan):
        print('  sfx_plan.json fehlt -> Stille')
        run(['-f', 'lavfi', '-i', f'anullsrc=r=48000:cl=stereo', '-t', f'{TOTAL_T:.3f}',
             '-c:a', 'aac', '-b:a', '192k', out])
        return
    P = json.load(open(plan))
    inputs, parts, labels = [], [], []
    fmt = 'aresample=48000,aformat=sample_fmts=fltp:sample_rates=48000:channel_layouts=stereo'
    bed = P.get('bed')
    if bed and os.path.exists(bed['file']):
        inputs += ['-stream_loop', '-1', '-i', bed['file']]
        fi, fo = bed.get('fade_in', 2), bed.get('fade_out', 3)
        parts.append(f'[0:a]{fmt},atrim=0:{TOTAL_T:.3f},asetpts=PTS-STARTPTS,volume={bed.get("gain_db", -30)}dB,'
                     f'afade=t=in:d={fi},afade=t=out:st={TOTAL_T - fo:.3f}:d={fo}[bed]')
        labels.append('[bed]')
    elif bed:
        print('  WARNUNG Teppich fehlt:', bed['file'])
    missing = []
    for ev in P.get('events', []):
        f = ev['file']
        if not os.path.exists(f):
            missing.append(f)
            continue
        idx = inputs.count('-i')
        inputs += ['-i', f]
        n = len(labels)
        chain = f'[{idx}:a]{fmt}'
        if ev.get('dur'):
            chain += f',atrim=0:{ev["dur"]},asetpts=PTS-STARTPTS'
            if ev.get('fade_out'):
                chain += f',afade=t=out:st={max(0, ev["dur"] - ev["fade_out"]):.3f}:d={ev["fade_out"]}'
        elif ev.get('fade_out'):
            d = probe_dur(f, 'a') or 0
            chain += f',afade=t=out:st={max(0, d - ev["fade_out"]):.3f}:d={ev["fade_out"]}'
        ms = max(0, int(round(ev['t'] * 1000)))
        chain += f',volume={ev.get("gain_db", -22)}dB,adelay={ms}:all=1[e{n}]'
        parts.append(chain)
        labels.append(f'[e{n}]')
    if missing:
        print('  WARNUNG fehlende SFX-Dateien:', sorted(set(missing)))
    # Eingangsindizes korrekt nummerieren (bed mit -stream_loop zählt als ein Input)
    parts.append(f'anullsrc=r=48000:cl=stereo,atrim=0:{TOTAL_T:.3f}[sil]')
    labels.append('[sil]')
    parts.append(''.join(labels) + f'amix=inputs={len(labels)}:normalize=0:duration=longest:dropout_transition=0,'
                 f'alimiter=limit=0.891:level=0,atrim=0:{TOTAL_T:.3f},apad=whole_dur={TOTAL_T:.3f}[out]')
    fs = f'{TMP}/audio_filter.txt'
    open(fs, 'w').write(';\n'.join(parts))
    print(f'  {len(labels) - 1} Spuren (Teppich + Events)')
    run(inputs + ['-/filter_complex', fs, '-map', '[out]', '-ar', '48000', '-ac', '2',
                  '-c:a', 'aac', '-b:a', '192k', out])


def mux():
    run(['-i', f'{TMP}/video_only.mp4', '-i', f'{TMP}/ton.m4a', '-map', '0:v', '-map', '1:a',
         '-c', 'copy', '-t', f'{TOTAL_T:.3f}', '-movflags', '+faststart', 'ausgabe/video_sauber.mp4'])


# ---------------------------------------------------------------- Sprechhilfe
FONT = '/System/Library/Fonts/Supplemental/Arial.ttf'
FONTB = '/System/Library/Fonts/Supplemental/Arial Bold.ttf'
COL = {'JOSHUA': '#D9A441', 'AUREL': '#2FA4A0'}
BAR_Y = 838
NAME_X, NAME_Y, NAME_FS = 56, 902, 46
TXT_X, TXT_Y, TXT_FS, TXT_W, LSP = 300, 900, 42, 1570, 10
NEXT_Y, NEXT_FS = 852, 27
MAXLINES = 3


def wrap(text, font, width):
    words, lines, cur = text.split(), [], ''
    for w in words:
        t = (cur + ' ' + w).strip()
        if font.getlength(t) <= width or not cur:
            cur = t
        else:
            lines.append(cur)
            cur = w
    if cur:
        lines.append(cur)
    return lines


def pages():
    """Liefert (start, ende, sprecher, [zeilen], nächste-text). Zu lange Zeilen werden auf
    mehrere Seiten (je max. 3 Zeilen) verteilt, Zeit anteilig nach Zeichenzahl."""
    f = ImageFont.truetype(FONT, TXT_FS)
    out = []
    for i, l in enumerate(L):
        nxt = ''
        if i + 1 < len(L):
            nxt = next_text(L[i + 1])
        lines = wrap(l['text'], f, TXT_W)
        chunks = [lines[j:j + MAXLINES] for j in range(0, len(lines), MAXLINES)]
        if len(chunks) > 1 and len(chunks[-1]) == 1 and len(lines) <= 2 * MAXLINES:
            # gleichmäßiger verteilen (z. B. 4 Zeilen -> 2+2)
            h = math.ceil(len(lines) / 2)
            chunks = [lines[:h], lines[h:]]
        tot = sum(len(' '.join(c)) for c in chunks)
        t = l['start']
        for ci, c in enumerate(chunks):
            d = l['dur'] * len(' '.join(c)) / tot
            e = l['start'] + l['dur'] if ci == len(chunks) - 1 else t + d
            cont = len(chunks) > 1
            out.append(dict(a=t, b=e, sp=l['sp'], lines=c, nxt=nxt,
                            page=f'{ci + 1}/{len(chunks)}' if cont else ''))
            t = e
    return out


def next_text(n):
    s = ''
    for w in n['text'].split():
        if len(s) + len(w) > 55:
            s += '…'
            break
        s = (s + ' ' + w).strip()
    return f'nächste: {n["sp"]} – {s}'


def intro_next():
    return next_text(L[0])


def esc_path(p):
    return p.replace('\\', '\\\\').replace("'", "\\'").replace(':', '\\:')


def hilfe_drawtext():
    tdir = os.path.abspath(f'{TMP}/txt')
    shutil.rmtree(tdir, ignore_errors=True)
    os.makedirs(tdir)
    F, FB = esc_path(FONT), esc_path(FONTB)
    flt = [f'drawbox=x=0:y={BAR_Y}:w={W}:h={H - BAR_Y}:color=black@0.62:t=fill']

    def dt(fn, content, font, fs, col, x, y, a, b, extra=''):
        p = os.path.join(tdir, fn)
        open(p, 'w', encoding='utf-8').write(content)
        flt.append(f"drawtext=fontfile='{font}':textfile='{esc_path(p)}':expansion=none:fontsize={fs}:"
                   f"fontcolor={col}:x={x}:y={y}:line_spacing={LSP}{extra}:enable='gte(t,{a:.3f})*lt(t,{b:.3f})'")

    first = L[0]['start']
    dt('intro_n.txt', 'Intro', FONTB, NAME_FS, '0xA0A0A0', NAME_X, NAME_Y, 0, first)
    dt('intro_x.txt', intro_next(), FONT, NEXT_FS, '0xB4B4B4', TXT_X, NEXT_Y, 0, first)
    for j, p in enumerate(pages()):
        dt(f'p{j:03d}_n.txt', p['sp'], FONTB, NAME_FS, COL[p['sp']].replace('#', '0x'), NAME_X, NAME_Y, p['a'], p['b'])
        dt(f'p{j:03d}_t.txt', '\n'.join(p['lines']), FONT, TXT_FS, 'white', TXT_X, TXT_Y, p['a'], p['b'],
           ':shadowcolor=black@0.6:shadowx=2:shadowy=2')
        if p['nxt']:
            dt(f'p{j:03d}_x.txt', p['nxt'], FONT, NEXT_FS, '0xB4B4B4', TXT_X, NEXT_Y, p['a'], p['b'])
        if p['page']:
            dt(f'p{j:03d}_p.txt', p['page'], FONT, NEXT_FS, '0x909090', NAME_X, NAME_Y + 64, p['a'], p['b'])
    fs = f'{TMP}/hilfe_filter.txt'
    open(fs, 'w', encoding='utf-8').write(',\n'.join(flt))
    run(['-i', 'ausgabe/video_sauber.mp4', '-/vf', fs, '-map', '0:v', '-map', '0:a'] + ENC +
        ['-c:a', 'copy', '-movflags', '+faststart', 'ausgabe/video_sprechhilfe.mp4'], ff=FF_TEXT)


def bar_png(path, sp, lines, nxt, page):
    im = Image.new('RGBA', (W, H - BAR_Y), (0, 0, 0, 158))
    d = ImageDraw.Draw(im)
    fb, ft, fn = ImageFont.truetype(FONTB, NAME_FS), ImageFont.truetype(FONT, TXT_FS), ImageFont.truetype(FONT, NEXT_FS)
    y0 = -BAR_Y
    if sp:
        d.text((NAME_X, NAME_Y + y0), sp, font=fb, fill=COL.get(sp, '#A0A0A0'))
    for i, ln in enumerate(lines):
        y = TXT_Y + y0 + i * (TXT_FS + LSP)
        d.text((TXT_X + 2, y + 2), ln, font=ft, fill=(0, 0, 0, 150))
        d.text((TXT_X, y), ln, font=ft, fill='white')
    if nxt:
        d.text((TXT_X, NEXT_Y + y0), nxt, font=fn, fill='#B4B4B4')
    if page:
        d.text((NAME_X, NAME_Y + 64 + y0), page, font=fn, fill='#909090')
    im.save(path)


def hilfe_png():
    tdir = os.path.abspath(f'{TMP}/bars')
    shutil.rmtree(tdir, ignore_errors=True)
    os.makedirs(tdir)
    ent = []
    bar_png(f'{tdir}/intro.png', '', [], intro_next(), '')
    d = Image.open(f'{tdir}/intro.png')
    ImageDraw.Draw(d).text((NAME_X, NAME_Y - BAR_Y), 'Intro', font=ImageFont.truetype(FONTB, NAME_FS), fill='#A0A0A0')
    d.save(f'{tdir}/intro.png')
    ent.append((f'{tdir}/intro.png', L[0]['start']))
    t = L[0]['start']
    for j, p in enumerate(pages()):
        fn = f'{tdir}/p{j:03d}.png'
        bar_png(fn, p['sp'], p['lines'], p['nxt'], p['page'])
        ent.append((fn, p['b'] - t))
        t = p['b']
    with open(f'{tdir}/list.txt', 'w') as fl:
        fl.write('ffconcat version 1.0\n')
        for fn, du in ent:
            fl.write(f"file '{fn}'\nduration {du:.4f}\n")
        fl.write(f"file '{ent[-1][0]}'\n")
    run(['-i', 'ausgabe/video_sauber.mp4', '-f', 'concat', '-safe', '0', '-i', f'{tdir}/list.txt',
         '-filter_complex', f'[1:v]fps={FPS},format=rgba[b];[0:v][b]overlay=0:{BAR_Y}:eof_action=repeat:format=auto,format=yuv420p[v]',
         '-map', '[v]', '-map', '0:a'] + ENC + ['-c:a', 'copy', '-t', f'{TOTAL_T:.3f}', '-movflags', '+faststart',
                                                'ausgabe/video_sprechhilfe.mp4'])


def hilfe():
    print('  Textmodus:', TEXTMODE, FF_TEXT or '')
    (hilfe_drawtext if TEXTMODE == 'drawtext' else hilfe_png)()


# ---------------------------------------------------------------- SRT
def srt():
    def ts(s):
        ms = int(round(s * 1000))
        return f'{ms // 3600000:02d}:{ms // 60000 % 60:02d}:{ms // 1000 % 60:02d},{ms % 1000:03d}'
    with open('ausgabe/zeitplan.srt', 'w', encoding='utf-8') as f:
        for n, l in enumerate(L, 1):
            f.write(f"{n}\n{ts(l['start'])} --> {ts(l['start'] + l['dur'])}\n{l['sp']}: {l['text']}\n\n")


def check():
    for p in ['ausgabe/video_sauber.mp4', 'ausgabe/video_sprechhilfe.mp4']:
        if os.path.exists(p):
            v, a = probe_dur(p, 'v:0'), probe_dur(p, 'a:0')
            ok = v and a and abs(v - 581.8) <= 0.5 and abs(a - 581.8) <= 0.5
            print(f'  {p}: Video {v} s, Ton {a} s ->', 'OK' if ok else 'ABWEICHUNG')


if __name__ == '__main__':
    args = [a for a in sys.argv[1:] if not a.startswith('--')]
    st = args[0] if args else 'all'
    print(f'ffmpeg={FF}  Textmodus={TEXTMODE}  Gesamt={TOTAL_T:.3f}s ({TOTAL_FR} Frames)  draft={DRAFT}')
    if st in ('all', 'srt'): srt(); print('zeitplan.srt geschrieben')
    if st in ('all', 'video'): print('Video …'); video()
    if st in ('all', 'audio'): print('Ton …'); audio()
    if st in ('all', 'video', 'audio', 'mux') and os.path.exists(f'{TMP}/video_only.mp4'): print('Mux …'); mux()
    if st in ('all', 'hilfe'): print('Sprechhilfe …'); hilfe()
    check()

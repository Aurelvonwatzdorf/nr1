# Rendert für jede Szene ohne Kling-Clip einen Ken-Burns-Clip nach clips/kbNNN.mp4 (NNN = Szenennummer).
# Rendert nur neu, wenn sich Bild, Dauer oder Variante geändert haben (clips/kb_stand.json).
#   python3 tools/render_stills.py [--alle]
import json, os, subprocess, sys
from concurrent.futures import ThreadPoolExecutor
os.chdir(os.path.join(os.path.dirname(os.path.abspath(__file__)), '..'))
T = json.load(open('timeline.json'))
FPS = 30
TOT = round((T[-1]['start'] + T[-1]['dur']) * FPS)
NF = [(round(T[i + 1]['start'] * FPS) if i + 1 < len(T) else TOT) - round(x['start'] * FPS) for i, x in enumerate(T)]
ST = 'clips/kb_stand.json'
stand = {} if '--alle' in sys.argv or not os.path.exists(ST) else json.load(open(ST))


def job(a):
    i, x = a; k = x["k"]; src = f'img/{x["img"]}.png'; out = f'clips/kb{k:03d}.mp4'
    if x["kling"] and os.path.exists(f'clips/kling_{x["img"]}.mp4'): return None
    if not os.path.exists(src): return f'FEHLT {src}'
    key = f'{x["img"]}|{NF[i]}|{k % 5}|{os.path.getmtime(src):.0f}'
    if stand.get(str(k)) == key and os.path.exists(out): return None
    subprocess.run([sys.executable, 'tools/kb.py', src, out + '.tmp.mp4', str(NF[i]), str(k)], check=True)
    os.replace(out + '.tmp.mp4', out); stand[str(k)] = key
    return k


with ThreadPoolExecutor(6) as ex: res = [r for r in ex.map(job, enumerate(T)) if r is not None]
json.dump(stand, open(ST, 'w'))
print(len([r for r in res if isinstance(r, int)]), 'Clips gerendert;', [r for r in res if isinstance(r, str)] or 'nichts fehlt')

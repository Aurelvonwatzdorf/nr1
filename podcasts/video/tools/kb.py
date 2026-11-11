# Ken-Burns-Clip aus einem Standbild: python3 kb.py in.png out.mp4 bildanzahl variante (30 Bilder = 1 s)
# Jedes Bild wird mit Pillows resize(box=…) berechnet: der Ausschnitt hat Kommastellen
# (Subpixel) und wird sauber gefiltert. Das alte transform(EXTENT, BILINEAR) rundete den
# Ausschnitt und ließ die Papierkörnung flimmern -> leichtes Zittern.
import sys, subprocess
from PIL import Image
FF = '/opt/homebrew/opt/ffmpeg-full/bin/ffmpeg'
W, H, FPS = 1920, 1080, 30
# Ein Durchgang, gleiche Einstellungen wie der Endschnitt: Die Segmente werden später nur kopiert.
# Ohne B-Bilder und mit -tune grain, weil x264 sonst die Papierkörnung in Viertelpixel-Schritten
# verschiebt (gemessen: Ruck 0,29 px statt 0,08 px).
ENC = ['-preset', 'medium', '-crf', '16', '-tune', 'grain', '-bf', '0', '-g', '60', '-video_track_timescale', '15360']
VAR = {0: (1.0, 1.10, 0, 0), 1: (1.10, 1.0, 0, 0), 2: (1.08, 1.08, -1, 0), 3: (1.08, 1.08, 1, 0), 4: (1.08, 1.08, 0, 1)}
# Varianten: 0 zoom rein, 1 zoom raus, 2 schwenk rechts, 3 schwenk links, 4 schwenk hoch


def box(iw, ih, a, v):
    z0, z1, dx, dy = VAR[v % 5]
    base = min(iw / W, ih / H)
    z = z0 + (z1 - z0) * a
    cw, ch = W * base / z, H * base / z
    mx, my = (iw - cw) / 2, (ih - ch) / 2
    cx = mx + dx * mx * (2 * a - 1) * 0.9
    cy = my + dy * my * (1 - 2 * a) * 0.9
    return (cx, cy, cx + cw, cy + ch)


def render(src, out, n, v, a0=0.0, a1=1.0):
    im = Image.open(src).convert('RGB')
    iw, ih = im.size
    p = subprocess.Popen([FF, '-v', 'error', '-y', '-f', 'rawvideo', '-pix_fmt', 'rgb24', '-s', f'{W}x{H}',
                          '-r', str(FPS), '-i', '-', '-c:v', 'libx264', *ENC,
                          '-pix_fmt', 'yuv420p', out], stdin=subprocess.PIPE)
    for f in range(n):
        a = f / (n - 1) if n > 1 else 0
        a = a0 + (a1 - a0) * a          # gleichmäßiges Tempo von Anfang bis Schnitt (kein Abbremsen)
        fr = im.resize((W, H), Image.Resampling.BICUBIC, box=box(iw, ih, a, v))
        p.stdin.write(fr.tobytes())
    p.stdin.close()
    p.wait()


if __name__ == '__main__':
    render(sys.argv[1], sys.argv[2], int(sys.argv[3]), int(sys.argv[4]))

# Aufnahmestudio: kleiner lokaler Webserver (nur Python-Standardbibliothek, nur 127.0.0.1).
#   python3 tools/studio.py            -> im Browser http://127.0.0.1:8765 öffnen
# Liefert tools/studio.html, das Video (mit Range-Unterstützung zum Springen) und lines.json,
# nimmt Takes per POST an, speichert sie als takes/zNN_tK.wav (48 kHz mono) und führt takes/takes.json.
import json, os, re, struct, sys, wave, array, math, threading
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import urlparse, parse_qs

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
os.chdir(ROOT)
PORT = int(os.environ.get('STUDIO_PORT', '8765'))
VIDEO = 'ausgabe/video_sauber.mp4'
TAKES, TJ = 'takes', 'takes/takes.json'
LOCK = threading.Lock()


def load_takes():
    if os.path.exists(TJ):
        return json.load(open(TJ))
    return {"info": "Takes je Zeile; fav = Nummer des Favoriten; speech_start/speech_len = Sprache ohne Stille (s); latency_ms = Latenz-Ausgleich", "lines": {}}


def save_takes(d):
    os.makedirs(TAKES, exist_ok=True)
    tmp = TJ + '.tmp'
    json.dump(d, open(tmp, 'w'), ensure_ascii=False, indent=1)
    os.replace(tmp, TJ)


def analyse(samples, sr):
    """Findet Anfang und Länge der Sprache (ohne Stille am Rand) über die Lautstärke in 20-ms-Fenstern."""
    win = sr // 50
    rms = []
    for a in range(0, len(samples) - win + 1, win):
        s = 0
        for v in samples[a:a + win]: s += v * v
        rms.append(math.sqrt(s / win))
    if not rms: return 0.0, 0.0, -99.0
    peak = max(rms)
    if peak < 60: return 0.0, 0.0, -99.0                 # praktisch Stille
    noise = sorted(rms)[len(rms) // 10]                   # leisestes Zehntel = Grundrauschen
    thr = max(noise * 3, peak * 0.06, 80)
    on = [i for i, r in enumerate(rms) if r > thr]
    if not on: return 0.0, 0.0, -99.0
    a, b = on[0], on[-1] + 1
    return round(a * win / sr, 3), round((b - a) * win / sr, 3), round(20 * math.log10(peak / 32768), 1)


class H(BaseHTTPRequestHandler):
    protocol_version = 'HTTP/1.1'

    def log_message(self, *a): pass

    def send(self, code, body=b'', ctype='application/json', extra=None):
        if isinstance(body, (dict, list)): body = json.dumps(body, ensure_ascii=False).encode()
        self.send_response(code)
        self.send_header('Content-Type', ctype)
        self.send_header('Content-Length', str(len(body)))
        self.send_header('Cache-Control', 'no-store')
        for k, v in (extra or {}).items(): self.send_header(k, v)
        self.end_headers()
        if self.command != 'HEAD': self.wfile.write(body)

    def file(self, path, ctype):
        """Datei mit Range-Unterstützung (nötig, damit der Browser im Video springen kann)."""
        if not os.path.exists(path): return self.send(404, {"error": f"{path} fehlt"})
        size = os.path.getsize(path)
        a, b = 0, size - 1
        m = re.match(r'bytes=(\d*)-(\d*)', self.headers.get('Range', ''))
        code = 200
        if m and (m.group(1) or m.group(2)):
            if m.group(1): a = int(m.group(1)); b = int(m.group(2)) if m.group(2) else size - 1
            else: a = max(0, size - int(m.group(2)))
            if a >= size: return self.send(416, b'', ctype, {'Content-Range': f'bytes */{size}'})
            b = min(b, size - 1); code = 206
        self.send_response(code)
        self.send_header('Content-Type', ctype); self.send_header('Accept-Ranges', 'bytes')
        self.send_header('Content-Length', str(b - a + 1))
        if code == 206: self.send_header('Content-Range', f'bytes {a}-{b}/{size}')
        self.end_headers()
        if self.command == 'HEAD': return
        with open(path, 'rb') as f:
            f.seek(a); left = b - a + 1
            try:
                while left > 0:
                    chunk = f.read(min(1 << 18, left))
                    if not chunk: break
                    self.wfile.write(chunk); left -= len(chunk)
            except (BrokenPipeError, ConnectionResetError):
                pass

    def do_HEAD(self): self.do_GET()

    def do_GET(self):
        p = urlparse(self.path).path
        if p in ('/', '/index.html'): return self.file('tools/studio.html', 'text/html; charset=utf-8')
        if p == '/video': return self.file(VIDEO, 'video/mp4')
        if p == '/lines.json': return self.file('lines.json', 'application/json')
        if p == '/takes.json':
            with LOCK: return self.send(200, load_takes())
        m = re.fullmatch(r'/takes/(z\d\d_t\d+\.wav)', p)
        if m: return self.file(os.path.join(TAKES, m.group(1)), 'audio/wav')
        self.send(404, {"error": "nicht gefunden"})

    def do_POST(self):
        u = urlparse(self.path); q = parse_qs(u.query)
        n = int(self.headers.get('Content-Length', 0))
        if n > 40_000_000: return self.send(413, {"error": "zu groß"})
        body = self.rfile.read(n)
        try:
            lines = json.load(open('lines.json'))
            line = int(q.get('line', ['-1'])[0])
            if not 0 <= line < len(lines): return self.send(400, {"error": "Zeile unbekannt"})
            if u.path == '/take': return self.take(line, body, q)
            if u.path == '/fav': return self.fav(line, q)
            if u.path == '/delete': return self.delete(line, q)
        except Exception as e:                                  # dem Browser die Ursache zeigen
            return self.send(500, {"error": str(e)})
        self.send(404, {"error": "nicht gefunden"})

    def take(self, line, body, q):
        # erwartet: WAV, 16 Bit, mono, 48 kHz (so erzeugt es studio.html)
        if body[:4] != b'RIFF' or body[8:12] != b'WAVE': return self.send(400, {"error": "kein WAV"})
        import io
        w = wave.open(io.BytesIO(body))
        if (w.getnchannels(), w.getsampwidth(), w.getframerate()) != (1, 2, 48000):
            return self.send(400, {"error": f"WAV muss 48 kHz mono 16 Bit sein, ist {w.getframerate()} Hz, {w.getnchannels()} Kanal, {w.getsampwidth() * 8} Bit"})
        pcm = w.readframes(w.getnframes())
        smp = array.array('h'); smp.frombytes(pcm)
        if sys.byteorder == 'big': smp.byteswap()
        a, d, peak = analyse(smp, 48000)
        with LOCK:
            T = load_takes(); e = T['lines'].setdefault(str(line), {"takes": [], "fav": None})
            k = max([t['n'] for t in e['takes']], default=0) + 1
            name = f'z{line:02d}_t{k}.wav'
            os.makedirs(TAKES, exist_ok=True)
            out = wave.open(os.path.join(TAKES, name), 'wb')
            out.setnchannels(1); out.setsampwidth(2); out.setframerate(48000); out.writeframes(pcm); out.close()
            tk = {"n": k, "file": name, "len": round(len(smp) / 48000, 3), "speech_start": a, "speech_len": d,
                  "peak_db": peak, "latency_ms": int(float(q.get('latency', ['0'])[0]))}
            e['takes'].append(tk); save_takes(T)
        self.send(200, tk)

    def fav(self, line, q):
        with LOCK:
            T = load_takes(); e = T['lines'].get(str(line))
            k = int(q.get('take', ['0'])[0])
            if not e or k not in [t['n'] for t in e['takes']]: return self.send(400, {"error": "Take unbekannt"})
            e['fav'] = k; save_takes(T)
        self.send(200, {"ok": True, "fav": k})

    def delete(self, line, q):
        with LOCK:
            T = load_takes(); e = T['lines'].get(str(line)); k = int(q.get('take', ['0'])[0])
            if not e: return self.send(400, {"error": "Zeile ohne Takes"})
            for t in [t for t in e['takes'] if t['n'] == k]:
                try: os.remove(os.path.join(TAKES, t['file']))
                except FileNotFoundError: pass
                e['takes'].remove(t)
            if e['fav'] == k: e['fav'] = None
            if not e['takes']: del T['lines'][str(line)]
            save_takes(T)
        self.send(200, {"ok": True})


if __name__ == '__main__':
    if not os.path.exists(VIDEO): print(f'Hinweis: {VIDEO} fehlt noch (python3 tools/assemble.py all).')
    srv = ThreadingHTTPServer(('127.0.0.1', PORT), H)
    print(f'Studio läuft: http://127.0.0.1:{PORT}   (beenden mit Strg+C)\nTakes landen in {ROOT}/takes/')
    try: srv.serve_forever()
    except KeyboardInterrupt: print('\nStudio beendet.')

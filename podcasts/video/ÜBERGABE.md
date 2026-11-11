# Video „¿Quién nos está mirando?“ – Übergabe (Stand 11.11.2026)

Erklärvideo zum Podcast `../vigilancia_ia_podcast_es.md` (Joshua & Aurel, Spanischunterricht).
Flache, gezeichnete Illustrationen, gedämpfte Farben, langsame Kamerafahrten, harte Schnitte.
**Kein Text und keine Untertitel im Video.** Die Stimmen sprechen Joshua und Aurel selbst im
Aufnahmestudio ein (`tools/studio.py`). Stimmen (`takes/`) werden nie gepusht.

## Stand: zweite Fassung FERTIG (ohne Stimmen)
- `ausgabe/video_sauber.mp4`: 1920×1080, 30 fps, 568,8 s (9:29), ca. 950 MB, Musik + Effekte, −23 LUFS.
- Text neu (44 Zeilen, 1302 Wörter, Joshua 49,5 % / Aurel 50,5 %), Schwerpunkt Palantir.
  Alle Aussagen mit Quelle in `quellen.md` (Status A selbst gelesen / B indirekt / C Behauptung einer Seite).
- 98 Szenen, jede 3,3–8,9 s. 41 alte Bilder (`sNN`), 57 neue (`nNN`), 8 Kling-Clips
  (s00, s20, s28, s32, s39, s45, s56, n75). Kling-Szenen sind höchstens 5 s lang: nie Bewegung und dann Standbild.
- Credits dieser Runde: 58 Bilder × 1 + 1 Kling-Clip (ca. 7,5) ≈ 66. Musik lokal berechnet (0 Credits).

## Dateien
- `lines.json` – Sprechzeilen (Sprecher, Start, Dauer = Wörter/2,45 + 0,6 s; Intro 6 s). Aus dem Text: `python3 tools/lines.py`.
- `tools/scenes_src.py` → `scenes.json` – Szenen: Zeile, Gewicht, Kling ja/nein, Bildname, Prompt (Zeile −1 Intro, −2 Outro).
- `timeline.json` – Start/Dauer je Szene (`python3 tools/timeline.py`; deckelt Kling auf 5 s, prüft 3–9 s).
- `bilder_job_ids.txt`, `bilder_urls.txt`, `kling_job_ids.txt` – Bildname → Job-ID / Link.
- `sfx_plan.json` – Musik + Effekte (`python3 tools/sfx_plan.py`; Effekte hängen an Bildnamen, wandern also mit).
- `quellen.md` – Quellen. `zeitplan.srt` – Zeitplan als getrennte Datei.
- Lokal, nicht im Git: `img/`, `clips/`, `sfx/`, `ausgabe/`, `takes/`.

## Neu bauen (Mac)
Werkzeuge: `brew install ffmpeg-full`, `pip3 install --user Pillow numpy`.
```bash
cd podcasts/video
while read n u; do curl -sSf -o img/$n.png "$u"; done < bilder_urls.txt
while read n j u; do curl -sSf -o clips/kling_$n.mp4 "$u"; done < kling_job_ids.txt
# Effekte: Links in sfx_quellen.txt (WAV 48 kHz, auf −1 dBFS normalisiert)
python3 tools/timeline.py && python3 tools/render_stills.py && python3 tools/musik.py && python3 tools/sfx_plan.py
python3 tools/assemble.py all        # -> ausgabe/video_sauber.mp4
```
- Neue Bilder: `python3 tools/req.py n01 n02 n03` druckt die Higgsfield-Requests (höchstens 3 gleichzeitig),
  danach `python3 tools/holen.py n01 JOBID LINK …`. Kontaktblatt: `python3 tools/contact.py out.png s03 n12 …`.
- Kamerafahrt: `tools/kb.py` rechnet jeden Ausschnitt mit Kommastellen (Pillow `resize(box=…)`) und kodiert
  ohne B-Bilder mit `-tune grain`. Prüfen: `python3 tools/kb_check.py clips/kb010.mp4` (bei dunklen,
  flächigen Bildern misst das Werkzeug ungenau: dort zeigt auch eine verlustfreie Fassung ~0,3 px).
- Musik: `tools/musik.py` berechnet eine Datei über die ganze Länge (keine Schleife), mit Intro- und Outro-Melodie.

## Aufnahmestudio
```bash
python3 tools/studio.py              # dann http://127.0.0.1:8765 im Browser öffnen
python3 tools/assemble.py stimmen    # Favoriten einmischen -> ausgabe/video_final.mp4
python3 tools/assemble.py anpassen   # Bilddauern an die echten Sprechlängen anpassen und alles neu bauen
python3 tools/assemble.py zuruecksetzen   # zurück zu den geplanten Zeiten
```
Takes: `takes/zNN_tK.wav` (48 kHz mono), `takes/takes.json` (Takes, Favorit, Sprechlänge ohne Stille, Latenz).
Stimmen: Stille weg, Hochpass 80 Hz, leichte Kompression, −16 LUFS, Musik/Effekte −6 dB beim Sprechen.
Getestet mit drei künstlichen Testtönen (Lage auf 0,03 s genau, −15,9 LUFS, Absenkung 5 dB).
**Nicht getestet:** die Seite im echten Browser mit Mikrofon (kein Bildschirmfoto möglich); nur Server und JS-Syntax geprüft.

## Offen / bekannt
- Musik und Ton hat noch niemand angehört (nur gemessen).
- `quellen.md`: Maven-Angaben sind Status B (über Wikipedia). Karp-Zitat von 2020 (Axios) fehlt bewusst: Wortlaut nicht belegbar.
- Stand Deutschland ist Juni 2026 (taz); vor der Vorstellung kurz prüfen, ob sich bei Dobrindt/NRW etwas geändert hat.

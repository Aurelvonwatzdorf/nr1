# Video „¿Quién nos está mirando?“ – Übergabe (Stand 07.11.2026)

Ziel: ~9:45-min-Erklärvideo zum Podcast `../vigilancia_ia_podcast_es.md` (Joshua & Aurel, ESBZ),
im Stil ruhiger deutscher Doku-Erklärvideos: flache, gezeichnete Illustrationen, gedämpfte
Farben (Petrolblau, Teal, Ocker, Koralle), Papierkörnung, langsame Zooms/Schwenks, harte Schnitte.
**Keine Stimmen** (sprechen Joshua & Aurel selbst ein), aber **Soundeffekte + leiser Atmo-Teppich**.
Kein Kanalname/Logo eines echten YouTube-Kanals verwenden.

## Entscheidungen des Nutzers
- „Mischung“: ~77 Standbilder mit Ken-Burns-Bewegung + 12 echte KI-Clips (Kling, 5 s, Startbild = Standbild).
- Zwei Ausgaben: `video_sauber.mp4` (ohne Text) und `video_sprechhilfe.mp4` (Sprecher + Zeile unten
  eingeblendet, damit sie im Takt einsprechen). Dazu `zeitplan.srt`/`zeitplan.txt`.

## Dateien
- `lines.json` – 52 Sprechzeilen mit Sprecher, Start, Dauer (2,45 Wörter/s + 0,6 s; Intro 6 s).
- `scenes.json` – 77 Szenen: `[zeile, gewicht, kling(0/1), bildprompt]` (Zeile -1 = Intro).
- `timeline.json` – Start/Dauer je Szene (`python3 tools/timeline.py`, Gesamt 581,8 s).
- `stilvorlage.txt` – Job-ID der Stilvorlage (als `image_references` an jedes Bild hängen).
- `bilder_job_ids.txt` / `bilder_urls.txt` – fertige Bilder (Szene-Index → Job-ID / URL).
- `tools/req.py <idx…>` – druckt fertige Higgsfield-Batch-Requests (Modell `gpt_image_2_6`,
  quality medium, 2k, 16:9, Stilvorlage als Referenz).
- `tools/kb.py in.png out.mp4 dauer variante` – Ken-Burns-Clip (1920×1080, 30 fps).
- `tools/render_stills.py` – rendert alle vorhandenen `img/sNN.png` nach `clips/kbNN.mp4`.
- `img/`, `clips/`, `sfx/`, `ausgabe/` sind lokal (in .gitignore). Bilder neu laden mit:
  `while read i u; do curl -sSf -o img/s$(printf %02d $i).png "$u"; done < bilder_urls.txt`

## Stand (07.11.2026, abends): FERTIG
- `ausgabe/video_sauber.mp4` (ohne Text) und `ausgabe/video_sprechhilfe.mp4` (Sprecher + Zeile +
  „nächste:“-Vorschau unten), je 1920×1080, 30 fps, AAC 48 kHz stereo, Länge 581,77 s.
  Lange Zeilen (bis 429 Zeichen) sind in der Sprechhilfe auf Seiten à max. 3 Zeilen verteilt
  (Zeit nach Zeichenzahl, „1/2“, „2/2“ unter dem Namen; 68 Seiten für 52 Zeilen).
  Dazu `zeitplan.srt` (Kopie auch in `ausgabe/`). Videos liegen nur lokal (in .gitignore).
- Alle 77 Bilder (Kontaktblätter geprüft: einheitlicher Stil, keine Schrift; Bild 34 zeigt bewusst
  Schriftzeichen als Übersetzungssymbole), 12 Kling-Clips (`kling_job_ids.txt`, 1276×720, ohne Ton,
  im Schnitt hochskaliert), 22 Soundeffekte (`sfx_quellen.txt`, WAVs auf −1 dBFS normalisiert).
- Ton: `sfx_plan.json` (erzeugt von `tools/sfx_plan.py`), 43 Events, Teppich −30 dB als Schleife,
  Effekte −20 bis −24 dB, Whoosh 0,9 s vor den Zeilen 4/12/20/28/38/46 (Höhepunkt auf dem Schnitt).
  Gemessen: Spitze −23 dB, Mittel −46 dB, viel Platz für die Stimmen.
- Kosten dieser Runde ≈ 179 Credits (57 Bilder, 12 Kling à 7,5 mit sound off, 24 Effekte).
  Guthaben 399. Gesamt bisher ≈ 201.
- **Higgsfield-Limit: max. 4 Aufträge gleichzeitig pro Konto** (sonst 429 rate_limit_reached).

## Neu bauen (Mac)
- Werkzeuge: `brew install ffmpeg ffmpeg-full` (drawtext gibt es nur in ffmpeg-full,
  `/opt/homebrew/opt/ffmpeg-full/bin/ffmpeg`), `pip3 install --user Pillow`.
- Bilder laden (s. oben), Kling-Clips: `while read i j u; do curl -sSf -o clips/kling_$(printf %02d $i).mp4 "$u"; done < kling_job_ids.txt`,
  Effekte über die URLs in `sfx_quellen.txt` (danach WAV 48 kHz, normalisiert; siehe `tools/sfx_plan.py`).
- `python3 tools/render_stills.py` → `python3 tools/assemble.py all` (Teilschritte: video|audio|mux|hilfe|srt).
- `python3 tools/contact.py out.png 20 21 22 …` baut ein Kontaktblatt zum Prüfen.

## Kling-Szenen (scenes.json, kling=1)
Index: 0, 9, 20, 28, 32, 38, 39, 45, 56, 60, 63, 76
(Feld kling in scenes.json). Modell `kling3_0`, duration 5, 16:9, `medias:[{role:"start_image", value:<Bild-Job-ID>}]`,
Prompt: ruhige, langsame Bewegung, flacher 2D-Stil bleibt erhalten, keine neuen Personen, kein Text.
Im Schnitt: Clip abspielen, danach letztes Bild halten bis Szenenende.

## Soundeffekte (Modell `mirelo_text_to_audio`, prompt + duration)
Intro-Drone/Riser (6 s), dunkler Atmo-Teppich (30 s, loopbar), Kamera-Servo/Klick, Stadtverkehr,
Schritte, Herzmonitor-Piep, Daten-Blips/Glitch, Schulklingel leise, vorbeifahrendes Auto,
Scanner-Piep (Kennzeichen), Papierrascheln, Telefonrauschen, Serverraum-Brummen, Hebel + Strom aus,
Richterhammer, Münzen/Kasse, Whoosh (Abschnittswechsel bei Zeilen 4, 12, 20, 28, 38, 46),
Menschenmenge, Tastatur, Schiffshorn, Spannungs-Riser, Outro „Strom aus“.
Mischung: Effekte −20 bis −24 dB, Teppich −30 dB, Platz für die Stimmen lassen.

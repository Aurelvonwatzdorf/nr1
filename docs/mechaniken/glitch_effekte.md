# Bildstörungen (Glitch) mit Bedeutung

- **Status:** Idee
- **Vorbild (nur Inspiration):** Bildstörungen bei Hacks, Implantat-Problemen
  und Erinnerungen in Cyberpunk 2077. Keine Effekte übernommen; eigene Regeln,
  wann und warum es flackert.
- **Für wen:** Grafik, Rückmeldung; Spiegelrealitäten, Hacking, Körpergrenze

## Was der Spieler erlebt
Das Bild **stört sich nur, wenn es etwas bedeutet**, und jede Störung sieht
anders aus:
- **Gehackt werden** (Netzwächter): blaue Blockverschiebung am Rand, Zeilen
  springen.
- **Überlastung** (Körpergrenze): Farbkanäle laufen auseinander, kurz ein
  falsches Bild (ein Gegner, der nicht da ist).
- **Hohe Verankerung** (Spiegelrealität): Die Welt „rutscht“ – Kanten doppeln
  sich, das HUD bröckelt (gibt es teilweise schon).
- **Spiegeljäger nahen**: Spiegelflächen und Bildschirme flackern in Weiß.
- **Riss in der Realität**: um den Riss herum bricht das Bild wie Glas.
- **Eigene Hacks**: Am Ziel kurze Störung, eigene Sicht bleibt ruhig.

## Warum es zu unserem Spiel passt
- Glitches als **Sprache**: Der Spieler lernt, Störungen zu lesen (Gefahr,
  Illusion, Technik). Passt zu „hinter die Realität sehen“.
- Nutzt den vorhandenen Overlay-Shader (`reality_sight.gdshader` hat schon
  `strength`, `distortion`, `pressure`, `time_stop`, `afterimage`).
- Barrierefreiheit: Schalter „Bildstörungen reduzieren“ (Flackern kann
  unangenehm sein).

## Eigene Startwerte (zum Feintunen)
| Störung | Dauer | Stärke |
|---|---|---|
| Gehackt werden | solange Aufspüren läuft | wächst mit Fortschritt |
| Überlastung | 0,4 s alle ~60 s | mittel |
| Verankerung ≥ 50 | dauernd leicht, ≥ 80 stark | vorhanden ausbauen |
| Spiegeljäger | 6 s Vorwarnung | wachsend |
| Riss | im Umkreis 6 m | Glasbruch |
| „Reduzieren“-Schalter | Stärke × 0,3, kein Blitzen | Barrierefreiheit |

## Umsetzung im Projekt
- Overlay-Shader erweitern: `glitch_blocks`, `channel_split`, `glass_crack`
  (eigene, einfache Rechnungen mit `screen_texture`). Ein Shader für alles
  (Leistung).
- `RealitySightOverlay` (vorhanden) bekommt Funktionen `pulse_glitch(kind, time)`.
- Einstellung `GameState.reduce_flashing` (gespeichert), Pausenmenü.
- Prüfung: Screenshots mit jeder Störung (Tour-Ort mit gesetztem Parameter).

## Offene Fragen an den Nutzer
- Wie stark dürfen Störungen sein? (Am Mac ansehen und entscheiden.)

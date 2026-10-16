# Wandlauf

- **Status:** gebaut
- **Vorbild (nur Inspiration):** Wandlaufen aus Bewegungs-Spielen
  (z. B. Titanfall, Prince of Persia, Ghostrunner). Keine Werte übernommen.
- **Für wen:** beide (Implantat, Erweiterung der Cyberbeine)

## Was der Spieler erlebt
Rennt man (Shift) schräg auf eine Wand zu und springt, läuft die Figur ein
Stück **seitlich an der Wand entlang**, ohne zu fallen. Die Kamera kippt leicht
zur Wand. Gegen Ende sinkt man langsam ab. Mit der Leertaste springt man
schräg von der Wand weg, auch auf die Wand gegenüber (in Gassen hin und her).
Die Ausdauer läuft dabei leer. Ist sie alle, fällt man herunter.

## Warum es zu unserem Spiel passt
- Santo Santiago hat enge, gewundene Gassen und hohe Häuser: ideal zum Erkunden
  und für Abkürzungen auf Dächer und Emporen.
- Kostet **Ausdauer** wie Sprint und Sprung, also kein Gratis-Fliegen.
- Fügt sich an die Cyberbeine (Doppelsprung) an: zweite Stufe derselben Technik.
- Später in Spiegelrealitäten: Wände, die nur mit Q da sind, kann man belaufen.

## Eigene Startwerte (zum Feintunen)
| Wert | Start | Begründung |
|---|---|---|
| Höchstdauer | 1,2 s | ca. 8 m Strecke |
| Mindesttempo zum Starten | 5 m/s | nur aus dem Rennen |
| Winkel zur Wand | 20°–70° | frontal = kein Wandlauf |
| Ausdauer | 25 pro Sekunde | wie Sprint, etwas mehr |
| Absinken | Schwerkraft × 0,15 | spürbar, nicht schwebend |
| Absprung | 6 m/s weg + Sprunghöhe | erreicht die Wand gegenüber |
| Preis Schwarzmarkt | 700 Geld | eigenständig (ohne Cyberbeine) |

## Umsetzung im Projekt
- Neuer Zustand `WallRun` (`scripts/player/states/wall_run_state.gd`, Name
  &"wall_run"). Übergang aus Move/Luft, wenn `is_on_wall()`, sprintend, in der
  Luft, Winkel passt und Flag `grants_wall_run` da ist.
- Wandnormale aus `get_wall_normal()`, Laufrichtung = Wand-Tangente.
- `PlayerAnimator.play_wall_run(side)` (Platzhalter: Figur kippt zur Wand),
  `CameraRig` neigt sich leicht.
- Neues Implantat „Haftsehnen“ (`grip_tendons`, PERMANENT, 700 Geld), wirkt auch ohne Cyberbeine.
- Test im Rauchtest: Testwand in der Arena, Spieler rennt schräg hin und
  springt → Zustand `wall_run`, Höhe fällt kaum; nach 1,2 s oder ohne
  Ausdauer → fällt; Sprung → Geschwindigkeit weg von der Wand.

## Offene Fragen an den Nutzer
- Implantat für beide, oder soll es nur eine Figur können?
- Auch senkrecht die Wand hoch (kurzes Hochlaufen)?

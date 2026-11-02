# Musik, die sich der Lage anpasst

- **Status:** Idee
- **Vorbild (nur Inspiration):** Musik, die zwischen Erkunden, Anspannung und
  Kampf wechselt, in Cyberpunk 2077 (und vielen Spielen). Keine Musik übernommen.
- **Für wen:** alles

## Was der Spieler erlebt
Die Musik folgt dem Geschehen, ohne hart zu schneiden: Beim Erkunden ruhige
Flächen je Viertel/Region; bemerkt einen ein Gegner, kommt ein Puls dazu; im
Kampf Trommeln und Bass; bei Bossen eigene Stücke mit **Phasen**. Nach dem Kampf
klingt es aus. In Spiegelrealitäten ist die Musik **zu schön** und leicht
verstimmt; mit hoher Verankerung verschwindet sie. Am Ankerspiegel ein eigenes,
ruhiges Thema; bei Aurels Zigarette eine kurze Melodie.

## Warum es zu unserem Spiel passt
- Soulslike: In der Welt oft wenig Musik, bei Bossen viel. Das stärkt Bosse.
- **Figurenthemen**: Aurel (Glut, treibend) und Tahirou (ruhig, tiefe Töne,
  Rabenflügel als Klang) – dieselbe Kampfmusik in zwei Färbungen.
- Verankerung als Musik-Regler: Die Illusion „nimmt einem die Musik“.

## Eigene Startwerte (zum Feintunen)
| Zustand | Auslöser | Übergang |
|---|---|---|
| Ruhe | nichts los | – |
| Anspannung | Verdacht > 0,5 oder Fahndung ≥ 1 | 2 s einblenden |
| Kampf | Gegner im Kampf-Zustand in 25 m | auf nächsten Takt |
| Nachklang | 6 s ohne Kampf | 4 s ausblenden |
| Boss Phase 2 | Boss-Leben ≤ 50 % | auf nächsten Takt |
| Verankerung ≥ 80 | Musik × 0,3, Tiefpass | schleichend |

## Umsetzung im Projekt
- Godot 4.7: `AudioStreamInteractive` (Übergänge auf Takt) +
  `AudioStreamSynchronized` (Schichten ein-/ausblenden). Eine Datei je Gebiet mit
  Schichten Ruhe/Puls/Kampf.
- `MusicDirector` (Autoload): bewertet die Lage (`EventBus`-Signale, Gegner-
  Zustände, `GameState.wanted_level`, Verankerung), setzt Schicht-Lautstärken.
- Musik-Bus mit `AudioEffectLowPassFilter` (Verankerung, Unterwasser, Zeitlupe).
- Test im Rauchtest: Wache wird aggressiv → `MusicDirector.state == COMBAT`;
  nach 6 s ohne Kampf → RUHE.

## Offene Fragen an den Nutzer
- Wenig Musik in der Welt (Souls-Gefühl) oder fast immer Musik?

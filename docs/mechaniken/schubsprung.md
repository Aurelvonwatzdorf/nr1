# Schubsprung (Dash)

- **Status:** Idee
- **Vorbild (nur Inspiration):** Kurze Schub-Sprints aus Action-Spielen
  (z. B. Cyberpunk 2077, Devil May Cry, Hades). Keine Werte übernommen.
- **Für wen:** beide (Implantat vom Schwarzmarkt)

## Was der Spieler erlebt
Mit dem Implantat ersetzt ein **Schubsprung** die Ausweichrolle in zwei
Fällen:
- **In der Luft** (Strg): ein kurzer, waagerechter Stoß in die gedrückte
  Richtung, z. B. über eine Lücke oder hinter einen Gegner.
- **Am Boden beim Rennen** (Shift + Strg): ein schneller, flacher Satz nach
  vorn statt der Rolle, weiter, aber mit kürzeren I-Frames.
Kurzer Lichtschweif hinter der Figur, Zischen, Kamera-Sichtfeld wird kurz weiter.
Im Stand und beim Gehen bleibt die normale Rolle (Soulslike-Kern).

## Warum es zu unserem Spiel passt
- Die Rolle bleibt das sichere Ausweichen, der Schubsprung ist für Bewegung
  und Angriff (hinter den Gegner kommen). Unterschiedliche Rollen, kein Ersatz.
- Kostet **Ausdauer**, einmal pro Luftphase (wie der Doppelsprung).
- Passt zu Wandlauf und Cyberbeinen: zusammen ein Bewegungs-Set fürs Erkunden.
- Optional mit Nachhall kombinierbar (Schubsprung kurz vor dem Treffer).

## Eigene Startwerte (zum Feintunen)
| Wert | Start | Begründung |
|---|---|---|
| Strecke | 6 m in 0,2 s | schnell, klar kürzer als ein Sprint |
| I-Frames | 0,05–0,15 s | weniger als die Rolle (0,05–0,35) |
| Ausdauer | 15 | billiger als die Rolle (20) |
| Luft-Schub | 1 pro Sprung, ohne Absinken | über Lücken |
| Abklingzeit | 0,6 s | kein Dauer-Dash |
| Preis Schwarzmarkt | 600 Geld | |

## Umsetzung im Projekt
- Neuer Zustand `Dash` (`scripts/player/states/dash_state.gd`, &"dash");
  `PlayerDodgeState`/Move entscheiden: Luft oder Sprint + Flag `grants_dash` →
  `dash`, sonst Rolle.
- `CharacterData`: `dash_distance`, `dash_duration`, `dash_stamina_cost`,
  `dash_iframe_start/end`.
- `PlayerAnimator.play_dash()` (Platzhalter: Strecken + Schweif),
  `CameraRig` kurz weiteres Sichtfeld.
- Neues Implantat `ItemData` (PERMANENT), Eintrag in `ItemDatabase.PATHS`.
- Test im Rauchtest: mit Implantat in der Luft Strg → ca. 6 m waagerecht,
  zweites Mal in derselben Luftphase nicht; am Boden ohne Sprint → Rolle.

## Offene Fragen an den Nutzer
- Soll der Schubsprung die Rolle beim Rennen ersetzen oder nur in der Luft gehen?
- Implantat oder Teil eines Fähigkeitenbaums?

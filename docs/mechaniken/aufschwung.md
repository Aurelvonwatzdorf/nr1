# Aufschwung (Kanten greifen, Hochziehen, Klettern)

- **Status:** gebaut (Hochziehen und Darübersetzen; Festhalten/Hangeln offen)
- **Vorbild (nur Inspiration):** Hochziehen an Kanten in Cyberpunk 2077 (auch
  Dying Light, Elden Ring). Keine Werte oder Animationen übernommen.
- **Für wen:** beide (Grundbewegung)

## Was der Spieler erlebt
Springt man gegen eine Kante, die etwa auf Brust- bis Armhöhe liegt, zieht sich
die Figur von selbst hoch (Mauern, Container, Dächer der Hütten in der Senke,
Brüstungen der Empore im Konzernturm). Niedrige Kanten (bis Hüfthöhe) überspringt
man im Laufen fließend, ohne anzuhalten. Höhere Kanten bekommt man nur mit
Doppelsprung, Wandlauf oder Schubsprung zu fassen. Kurzes Ruckeln der Kamera
nach oben, Griffgeräusch.

## Warum es zu unserem Spiel passt
- Die Stadt ist vertikal (Hüttentürme, Containerstapel, Hochhäuser). Ohne
  Hochziehen bleiben Sprünge knapp an Kanten hängen und fühlen sich unfair an.
- Macht die Implantate (Cyberbeine, Haftsehnen, Schubknoten) wertvoller: Sie
  erreichen neue Kanten, statt nur höher zu springen.
- Erlaubt versteckte Wege und Fundstücke auf Dächern, Abkürzungen zu
  Ankerspiegeln, Wege im Konzernturm (wie die versteckte Rampe).
- Kein freies Klettern an jeder Wand (das würde Level-Design sprengen): nur Kanten.

## Eigene Startwerte (zum Feintunen)
| Wert | Start | Begründung |
|---|---|---|
| Überspringen ohne Halt | Kante 0,4–1,1 m über den Füßen | fließend laufen |
| Hochziehen | Kante 1,1–2,3 m über den Füßen | Sprunghöhe ~1,8 m + Arme |
| Dauer Hochziehen | 0,45 s | schnell, aber verwundbar |
| Dauer Überspringen | 0,25 s | kaum Tempoverlust |
| Ausdauer | 6 | kleiner als ein Sprung (8) |
| Mindestfläche oben | 0,6 m tief, 1,8 m frei | sonst kein Griff |
| Im Kampf getroffen | bricht ab, man fällt | Soulslike-fair |

## Umsetzung im Projekt
- Neuer Zustand `scripts/player/states/mantle_state.gd` (`Mantle`). Erkennung in
  `Player.try_mantle()`: Strahl nach vorn auf Brusthöhe trifft eine Wand, Strahl
  von oben (vor der Wand, 0,4 m dahinter) findet eine Fläche; Platz für die Kapsel
  per `ShapeCast3D` prüfen. Aufruf aus `PlayerMoveState`/Luft, wenn Sprung
  gedrückt ist oder man im Sprung gegen die Kante läuft.
- Bewegung als zwei Phasen (hoch, dann vor) per Tween auf die Position,
  `velocity` = 0, keine Physik währenddessen.
- `PlayerAnimator.play_mantle(height)` (Platzhalter: Kapsel hebt sich und kippt vor).
- Gegner bekommen später dasselbe nicht (sie nutzen Wege); Spiegeljäger evtl. doch.
- Test im Rauchtest: Box 1,6 m hoch, Spieler davor, springen → Zustand `mantle`,
  danach steht er oben (`global_position.y` ≈ 1,6). Box 0,8 m im Lauf → kein Halt.

## Offene Fragen an den Nutzer
- Soll man sich an einer Kante auch **festhalten** und seitlich hangeln können
  (mehr Arbeit, mehr Möglichkeiten in der Geisterwelt/Bergtempel)?

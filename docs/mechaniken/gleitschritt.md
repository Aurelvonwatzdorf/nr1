# Gleitschritt (Rutschen aus dem Sprint)

- **Status:** Idee
- **Vorbild (nur Inspiration):** Rutschen beim Sprinten in Cyberpunk 2077 (auch
  Titanfall, Apex). Keine Werte oder Namen übernommen.
- **Für wen:** beide (Grundbewegung, keine Freischaltung nötig)

## Was der Spieler erlebt
Beim Rennen drückt man **Ducken** und die Figur rutscht flach über den Boden,
etwas schneller als beim Sprint, und wird dann langsamer. Man passt unter
niedrigen Hindernissen durch (Rohre, Schranken, Marktstände) und unter hohen,
waagerechten Schlägen hindurch. Aus dem Rutschen geht ein **Gleitstoß** (leichter
Angriff), ein Sprung mit Schwung oder direkt Schleichen. Die Kamera senkt sich
und das Sichtfeld weitet sich kurz, Funken/Staub an den Füßen.

## Warum es zu unserem Spiel passt
- Gibt dem Sprint in den engen Gassen von Santo Santiago einen Zweck und verbindet
  Bewegung mit Kampf (Risiko/Belohnung, passt zu Aurel).
- Ausdauer statt Abklingzeit: im Soulslike-Kampf darf es nicht gratis sein.
- **Keine** I-Frames (die gehören der Rolle). Nur die niedrigere Trefferfläche
  schützt, und auch nur vor Schlägen, die hoch gezielt sind. So bleibt die Rolle
  das Ausweich-Werkzeug.

## Eigene Startwerte (zum Feintunen)
| Wert | Start | Begründung |
|---|---|---|
| Startgeschwindigkeit | 1,3 × Sprint | spürbarer Schub |
| Dauer | 0,7 s | kurz, nicht als Fortbewegung missbrauchbar |
| Abbremsen | linear auf Gehtempo | weiches Ende |
| Ausdauer | 12 | etwas weniger als die Rolle (20) |
| Abklingzeit | 0,4 s | kein Dauerrutschen |
| Körperhöhe beim Rutschen | 0,9 m (statt 1,8) | passt unter Hindernisse |
| Gleitstoß | Schaden 1,1 × leichter Schlag, wirft leicht um | Belohnung fürs Anlaufen |
| Bergab | Dauer +50 % | Gefühl für Gelände |

## Umsetzung im Projekt
- Neue Aktion `crouch` (Tastatur C; Gamepad-Vorschlag: B kurz = Ausweichen,
  B halten = Ducken, siehe offene Fragen; Touch: eigener Knopf).
- Neuer Zustand `scripts/player/states/slide_state.gd` (`Slide`), Start aus
  `PlayerMoveState`, wenn gerannt wird. Kapsel des `CollisionShape3D` verkleinern
  und am Ende prüfen, ob Platz zum Aufstehen ist (sonst in `Crouch` bleiben).
- Werte in `CharacterData`, neue Gruppe „Gleitschritt“.
- `Hurtbox` beim Rutschen tiefer/kleiner. Gegnerangriffe bekommen in `AttackData`
  ein Feld `height` (LOW/HIGH/ALL), damit hohe Schläge darüber gehen.
- `PlayerAnimator.play_slide()` (Platzhalter: Kapsel kippen), `CameraRig.punch_fov()`.
- Test im Rauchtest: rennen + `crouch` → Zustand `slide`, Ausdauer −12, Höhe
  kleiner; nach 0,7 s wieder `move`; unter einer niedrigen Box hindurch ohne Stopp.

## Offene Fragen an den Nutzer
- Welche Taste am Gamepad (die Belegung ist fast voll)?
- Soll der Gleitstoß Gegner umwerfen oder nur Schaden machen?

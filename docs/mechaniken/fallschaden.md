# Fallschaden, Abrollen und Aufschlag

- **Status:** gebaut (Fallschaden, tödlicher Sturz, Abrollen, Taumeln, Implantat
  „Aufschlag“ beim Schwarzhändler für 750). Offen: kein Schaden im Wasser.
- **Vorbild (nur Inspiration):** Fallschaden und Landeangriff aus großer Höhe in
  Cyberpunk 2077 (auch Souls-Spiele für Fallschaden). Keine Werte/Namen übernommen.
- **Für wen:** beide; „Aufschlag“ als Implantat vom Schwarzmarkt

## Was der Spieler erlebt
Wer tief fällt, nimmt Schaden: erst ein dumpfer Aufprall, ab einer gewissen Höhe
viel Schaden, sehr tief ist tödlich. Drückt man **kurz vor der Landung Ausweichen**,
rollt die Figur ab und nimmt weniger Schaden (Zeitfenster sichtbar durch ein
kurzes Aufblitzen der Füße). Mit dem Implantat **Aufschlag** kann man in der Luft
**schwerer Angriff** drücken: Die Figur stürzt senkrecht herab, schlägt auf und
stößt Gegner im Umkreis weg. Der eigene Fallschaden entfällt dabei bis zu einer
Höhe.

## Warum es zu unserem Spiel passt
- Höhe braucht Gefahr, sonst sind Dächer und Hochhäuser bedeutungslos. Souls-Gefühl:
  Ein Sturz ist eine echte Strafe.
- Abrollen belohnt Timing (wie Parieren), ohne neue Taste.
- Aufschlag verbindet Wandlauf/Schubsprung/Doppelsprung mit Kampf: von oben in
  eine Gruppe Wachen. Passt zu Aurels Aufstieg-Ast und zu „Wucht“.
- In der Geisterwelt/Bergtempel-Weg (M8.5) Sturzgefahr als Hindernis.

## Eigene Startwerte (zum Feintunen)
| Wert | Start | Begründung |
|---|---|---|
| Sichere Höhe | bis 5 m | normaler Sprung von Containern |
| Schaden | 8 Leben pro Meter über 5 m | 15 m ≈ 80 Schaden |
| Tödlich ab | 18 m (Cyberbeine: 24 m) | Hochhäuser bleiben gefährlich |
| Abrollen Zeitfenster | 0,25 s vor Bodenkontakt | fair, aber lernbar |
| Abrollen | halber Schaden, keine Taumel-Zeit | Belohnung |
| Landung ohne Abrollen ab 8 m | 0,6 s taumeln | Strafe |
| Aufschlag: Mindesthöhe | 3 m | nicht vom Boden aus |
| Aufschlag: Schaden / Radius | 30 / 3,5 m, + Fallhöhe × 2 | Höhe lohnt sich |
| Aufschlag: Ausdauer | 25 | wie ein schwerer Angriff |
| Aufschlag: kein Fallschaden bis | 15 m | darf nicht tödlich sein |
| Preis (Schwarzmarkt) | 750 Geld | zwischen Haftsehnen und Nachhall |

## Umsetzung im Projekt
- `Player`: höchsten Punkt seit Bodenkontakt merken (`_fall_start_y`), bei Landung
  in `_physics_process` Fallhöhe berechnen → `health.damage()` (eigener
  `HitData` ohne Quelle, ignoriert Blocken). Abroll-Fenster: Zeitpunkt des
  letzten `dodge`-Drucks in der Luft.
- Zustand `Land` (kurzes Taumeln) oder `Hurt` wiederverwenden.
- Implantat `ItemData.grants_ground_slam` (neues Feld), Item
  `resources/items/impact_frame.tres` („Aufschlag“), Eintrag in `ItemDatabase.PATHS`,
  Schwarzmarkt-Angebot in `santo_santiago.tscn`.
- Zustand `GroundSlam` (`ground_slam_state.gd`): Geschwindigkeit nach unten,
  beim Aufkommen `release_wildfire()`-ähnliche Fläche (Hitbox-Kugel, Rückstoß),
  `HitStop.apply()`, Kamerawackeln.
- Wasser/tiefes Meer auf dem Kontinent: kein Fallschaden.
- Test im Rauchtest: Spieler aus 12 m fallen lassen → Leben −56; mit Ausweichen
  0,1 s vor dem Boden → −28; mit Implantat und schwerem Angriff aus 6 m → Puppe
  nimmt Schaden, Spieler nicht.

## Offene Fragen an den Nutzer
- Soll ein Sturz aus sehr großer Höhe wirklich töten (Souls-Stil) oder nur auf
  1 Leben setzen?

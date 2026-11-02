# Schusswaffen-Klassen (Stoß, Lanze, Spürer)

- **Status:** Idee
- **Vorbild (nur Inspiration):** Die drei Bauarten von Feuerwaffen in Cyberpunk
  2077 (normale, aufladbare durch Wände, zielsuchende). Keine Namen, Werte oder
  Waffenmodelle übernommen.
- **Für wen:** beide; Waffenschmied (legal) und Schwarzmarkt (illegal)

## Was der Spieler erlebt
Jede Schusswaffe gehört zu einer von drei Bauarten, die man schon am Aussehen
erkennt:
1. **Stoßwaffen** (Pulver/Magnet, die heutige Pistole): sofort, zuverlässig,
   Rückstoß, Kugeln prallen an Metall ab (spätere Mod).
2. **Lanzen** (aufladbar): Abzug halten lädt (Lichtstreifen an der Waffe füllt
   sich), voll geladen geht der Schuss **durch dünne Wände und Deckung** und trifft
   Gegner dahinter, die man mit Realitätsblick oder Scanner sieht.
3. **Spürer** (zielsuchend): Lock-on-Ziel wird markiert, die Geschosse fliegen in
   Kurven hinterher. Wenig Schaden pro Treffer, aber kaum zu verfehlen.

## Warum es zu unserem Spiel passt
- Schusswaffen sind bei uns **Nebenwaffen** (Taste V) neben dem Soulslike-Nahkampf.
  Drei klare Bauarten geben Auswahl ohne Waffen-Flut.
- Lanzen + Realitätsblick: Man sieht Gegner hinter Wänden in der wahren Welt und
  schießt hindurch. Die Wände sind ja manchmal nur Illusion.
- Spürer + Aurels Insider-Ast: Ziele „markieren“ ist Konzerntechnik.
- Munition bleibt knapp und kostet Geld; Schüsse holen Fahndung und Lärm.

## Eigene Startwerte (zum Feintunen)
| Wert | Stoß (Pistole) | Lanze | Spürer |
|---|---|---|---|
| Schaden | 14 (heute) | 10 ungeladen, 40 voll | 6 je Geschoss, 3 Geschosse |
| Ladezeit | – | 0,9 s | – |
| Durch Wände | nein | ab 70 % Ladung, Wand ≤ 0,5 m, Schaden × 0,6 | nein |
| Zielsuche | nein | nein | nur mit Lock-on, Drehrate 240°/s |
| Schussabstand | 0,45 s | 1,2 s | 0,8 s (Salve) |
| Reichweite | 40 m | 60 m | 30 m |
| Munition | Pistolenmunition | Lanzenzellen | Spürpfeile |
| Preis | 300 (heute) | 1100 (Schwarzmarkt) | 900 (Waffenschmied, Konzernware) |

## Umsetzung im Projekt
- `ItemData`: neues Feld `firearm_class` (enum STANDARD, CHARGE, SMART),
  `charge_time`, `pierce_thickness`, `projectile_count`, `homing_rate`.
- `Player.fire_firearm()` aufteilen: `_fire_hitscan()` (heute), `_fire_charged()`
  (Halten über `fire` gedrückt → Strahl mit `exclude` der ersten Wand, Dicke per
  zweitem Strahl von der Gegenseite messen), `_fire_smart()` (neue Szene
  `scenes/combat/homing_projectile.tscn`, `Area3D` mit Hitbox, lenkt pro Frame
  zum `lock_on.target`).
- HUD: Ladebalken an der Zielhilfe.
- Neue Items: `charge_rifle.tres`, `smart_pistol.tres` + Munition; eigene Namen
  (Vorschläge: „Glutlanze“, „Spürer M-3“).
- Test im Rauchtest: Lanze voll geladen auf Puppe hinter 0,3-m-Wand → Schaden 24;
  Spürer mit Lock-on auf seitlich laufende Puppe → alle 3 Geschosse treffen.

## Offene Fragen an den Nutzer
- Sollen Schusswaffen eher selten bleiben (Nebenwaffe) oder gleichwertig zum
  Nahkampf werden?

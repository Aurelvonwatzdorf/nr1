# Luftsteuerung und Feinschliff der Sprung-Implantate

- **Status:** Idee
- **Vorbild (nur Inspiration):** Bewegung in der Luft und die Bein-Implantate in
  Cyberpunk 2077 (zweiter Sprung bzw. aufladbarer Sprung, Luftstoß). Keine Werte
  oder Namen übernommen.
- **Für wen:** beide; vorhandene Implantate (Cyberbeine, Schubknoten, Haftsehnen)
  und ein neues: **Sprungfeder**

## Was der Spieler erlebt
Sprünge fühlen sich genauer an: Wer die Leertaste kurz tippt, springt flach, wer
sie hält, springt voll hoch. Kurz nach dem Verlassen einer Kante darf man noch
springen, und ein Sprung, der kurz vor der Landung gedrückt wurde, wird beim
Aufkommen ausgeführt. In der Luft lenkt man nur noch begrenzt, damit sich der
Schwung echt anfühlt. Neues Bein-Implantat **Sprungfeder** (Alternative zu den
Cyberbeinen): Sprung gedrückt halten lädt einen hohen Sprung auf (Figur geht in
die Knie, Summen), loslassen schleudert sie hoch. Mit Sprungfeder gibt es keinen
Doppelsprung; man wählt eins von beiden.

## Vergleich: was wir schon haben
| Bei uns | Vorbild | Verbessern |
|---|---|---|
| Doppelsprung (Cyberbeine): zweiter Sprung gleich stark | zweiter Sprung, gibt Richtung neu vor | 2. Sprung darf die Richtung sofort ändern (heute behält er den alten Schwung), kleiner Luftstoß-Effekt unter den Füßen |
| Schubsprung (Schubknoten): waagerecht, einmal pro Sprung | ähnlich, auch am Boden | am Boden auch aus dem Stand (heute nur beim Rennen) → nein, die Rolle soll bleiben. Stattdessen: Schubsprung setzt den Doppelsprung **nicht** zurück, aber nach einem Wandsprung wieder frei |
| Wandlauf (Haftsehnen) | gibt es im Vorbild nicht | eigene Stärke behalten: Wand-zu-Wand-Ketten belohnen (jeder neue Wandlauf ohne Bodenkontakt +10 % Tempo, höchstens 3) |
| keine Luftsteuerung (Beschleunigung wie am Boden: 30 m/s²) | deutlich weniger Kontrolle in der Luft | Luft-Beschleunigung 9 m/s² |
| kein Kanten-Puffer | großzügig | Koyote-Zeit und Sprung-Puffer (s. u.) |
| Sprunghöhe immer gleich | variabel | kurzer Druck = flacher Sprung |

## Eigene Startwerte (zum Feintunen)
| Wert | Start | Begründung |
|---|---|---|
| Luft-Beschleunigung | 9 m/s² (Boden 30) | Schwung bleibt spürbar |
| Koyote-Zeit | 0,12 s | Kanten fühlen sich fair an |
| Sprung-Puffer | 0,12 s | Eingabe geht nicht verloren |
| Kurzer Sprung | Steigen ab Loslassen × 0,5 | einfache Höhensteuerung |
| Sprungfeder: Ladezeit | 0,7 s bis voll | kurz genug für Kampf |
| Sprungfeder: Höhe voll | 2,2 × normaler Sprung | Dächer erreichen |
| Sprungfeder: Ausdauer | 8 + 12 bei voller Ladung | hoher Sprung kostet |
| Sprungfeder: Preis | 650 Geld, ersetzt Cyberbeine | Wahl statt Stapeln |
| Wandketten-Bonus | +10 %/Kette, max. 3 | belohnt Können |

## Umsetzung im Projekt
- `Player.try_jump()`: `_coyote_left`, `_jump_buffer_left`; in `apply_gravity()`
  stärkere Schwerkraft, wenn `jump` losgelassen und `velocity.y > 0`.
- `CharacterData`: `air_acceleration`, `coyote_time`, `jump_buffer_time`,
  Gruppe „Sprungfeder“. `accelerate_to()` nimmt `air_acceleration`, wenn nicht
  am Boden (gilt für `PlayerMoveState` und Idle).
- Doppelsprung: waagerechte Geschwindigkeit auf die Eingabe setzen.
- Neues Implantat `resources/items/spring_coil.tres` mit `grants_charge_jump`;
  `Inventory`/Händler: Kauf ersetzt Cyberbeine (Hinweis im Kaufdialog).
- `wall_run_state.gd`: Kettenzähler im `Player`, beim Landen zurück.
- Test im Rauchtest: Spieler läuft über eine Kante, 0,08 s später Sprung → springt;
  Sprung kurz tippen → Gipfel niedriger als bei gehaltenem Sprung; Sprungfeder
  0,7 s halten → Gipfel ≈ 2,2-fach.

## Offene Fragen an den Nutzer
- Sprungfeder als Wahl **statt** Cyberbeinen, oder beides kaufbar?
- Ist dir das heutige Sprunggefühl am Mac zu „schwebend“ oder zu schwer?

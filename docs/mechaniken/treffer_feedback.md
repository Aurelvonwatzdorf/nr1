# Treffer-Rückmeldung (Zahlen, Zielhilfe, Klang, Bild)

- **Status:** Idee
- **Vorbild (nur Inspiration):** Treffermarker, Schadenszahlen und Kopfschuss-
  Rückmeldung in Cyberpunk 2077. Kein Symbol, keine Farben oder Laute übernommen.
- **Für wen:** beide, alle Waffen

## Was der Spieler erlebt
Jeder Treffer meldet sich klar: Die Zielhilfe zuckt kurz zu einem Kreuz, ein
Treffer am Kopf färbt es gold, ein tödlicher Treffer zeigt ein kleines Rabenauge
(Tahirou) bzw. einen Funken (Aurel). Schadenszahlen sind **abschaltbar** und
steigen klein über dem Gegner auf. Getroffene Gegner blitzen hell auf (gibt es
schon), zucken in Schlagrichtung und bluten. Eigene Treffer: Rand des Bildes färbt
sich kurz rot, aus der Richtung des Angreifers.

## Warum es zu unserem Spiel passt
- Vorhanden: Hitstop, Kamerawackeln, Aufblitzen, Blut, Kamera-Ruck (Wucht). Es
  fehlt die **Richtung** (woher kam der Treffer?) und die **Bestätigung bei
  Schüssen** auf Entfernung.
- Figurenbezogene Symbole verstärken die beiden Spielweisen.
- Abschaltbare Zahlen: Souls-Puristen wollen keine.

## Eigene Startwerte (zum Feintunen)
| Wert | Start | Begründung |
|---|---|---|
| Treffer-Kreuz | 0,12 s | kurz, klar |
| Schadenszahlen | Standard aus, im Pausenmenü schaltbar | Souls-Gefühl |
| Richtungs-Rot | 0,6 s, Stärke nach Schaden | Orientierung |
| Gegner-Zucken | 6° in Schlagrichtung, 0,15 s | `play_lean()` gibt es schon |
| Schuss-Treffer-Ton | hell, Kopf höher | Klang folgt mit Bereich 10 |

## Umsetzung im Projekt
- `EventBus.hit_confirmed(target, damage, zone, killed)` aus `Player._on_hit_landed()`
  und `fire_firearm()`.
- HUD: Zielhilfe (`hud.gd`) bekommt Treffer-Kreuz; neue Szene
  `scenes/ui/damage_number.tscn` (Label3D, steigt, verblasst).
- Richtungs-Rot im vorhandenen Overlay-Shader (`reality_sight.gdshader`,
  Parameter `hurt_direction`, `hurt_strength`) statt eigenem Shader: spart Leistung.
- Einstellung `GameState.show_damage_numbers` (gespeichert), Schalter im Pausenmenü.
- Test im Rauchtest: Treffer auf Puppe → Signal `hit_confirmed` mit Schaden;
  Schalter aus → keine `DamageNumber` im Baum.

## Offene Fragen an den Nutzer
- Schadenszahlen standardmäßig an oder aus?

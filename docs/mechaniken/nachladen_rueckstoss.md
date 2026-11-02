# Magazin, Nachladen, Rückstoß und Streuung

- **Status:** Idee
- **Vorbild (nur Inspiration):** Schießgefühl in Cyberpunk 2077 und modernen
  Shootern. Keine Werte oder Muster übernommen.
- **Für wen:** beide, alle Schusswaffen

## Was der Spieler erlebt
Waffen haben ein Magazin. Ist es leer, lädt die Figur nach (Taste oder von
selbst), was Zeit kostet und angreifbar macht. Wer nachlädt, **bevor** das
Magazin leer ist, ist schneller fertig. Schnelles Feuern lässt die Waffe nach oben
wandern und streuen; ruhiges Feuern trifft genau. Tahirou (Stille-Ast) hält
ruhiger, Aurel schießt schneller, aber unruhiger.

## Warum es zu unserem Spiel passt
- Nachladen ist ein **Zeitfenster der Verwundbarkeit**, genau wie Ausholen im
  Nahkampf: passt zum Soulslike-Rhythmus „Angriff gegen Risiko“.
- Rückstoß gibt Waffen Charakter, ohne neue Werte-Tabellen für Schaden.
- Skillknoten „Ruhige Hand“ (Tahirou) bekommt eine zweite Bedeutung.

## Eigene Startwerte (zum Feintunen)
| Wert | Start | Begründung |
|---|---|---|
| Magazin Pistole | 8 | kurze Feuerstöße |
| Nachladen voll leer / taktisch | 1,4 s / 1,0 s | taktisch belohnen |
| Nachladen abbrechen | durch Ausweichen (Magazin bleibt leer) | Ausweichen geht immer vor |
| Rückstoß pro Schuss | Kamera +1,2° hoch | spürbar, nicht wild |
| Erholung | 8°/s zurück | ruhige Hand = schneller |
| Streuung | 0,5° + 0,8° je schnellem Schuss, max 4° | Tempo kostet Genauigkeit |
| Lock-on | Streuung halbiert | Lock-on bleibt hilfreich |
| „Ruhige Hand“ (Tahirou) | Rückstoß −40 % | Stille-Ast |

## Umsetzung im Projekt
- `ItemData` (Schusswaffe): `magazine_size`, `reload_time`, `tactical_reload_time`,
  `recoil_pitch`, `spread_base`, `spread_per_shot`, `spread_max`.
- `GameState`: Munition im Magazin je Waffe (`firearm_magazine`), gespeichert.
- Neue Aktion `reload` (Taste T, Gamepad: X halten; X = Interaktion bleibt kurz).
- Zustand `Reload` (`reload_state.gd`) oder Zähler im `Player`, Bewegung erlaubt
  (Gehen), kein Angriff/Sprint.
- `CameraRig.add_recoil(pitch)`; Streuung im Strahl von `fire_firearm()`.
- HUD: Patronen „6 / 24“ neben der Waffe.
- Test im Rauchtest: 8 Schüsse, 9. löst Nachladen aus; nach 1,4 s wieder 8.

## Offene Fragen an den Nutzer
- Nachladen automatisch, wenn leer, oder nur per Taste?

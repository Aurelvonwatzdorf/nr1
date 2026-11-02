# Fernzugriff-Programme (Auswahl an Hacks gegen Gegner)

- **Status:** Idee (baut auf dem gebauten `fernzugriff.md` auf)
- **Vorbild (nur Inspiration):** Schnellhacks in Cyberpunk 2077 (aus der Ferne
  Programme auf Gegner laden, mit Upload-Zeit, Kosten und Gegen-Hackern). Keine
  Programmnamen, Werte oder Symbole übernommen.
- **Für wen:** Aurel (Ast **Insider**), nur gegen Konzern-Technik und Cyborgs

## Was der Spieler erlebt
Heute hat Aurel genau einen Hack (F: Störung, mit Waffensperre stärker). Neu:
**F halten** öffnet ein kleines Rad mit bis zu vier freigeschalteten Programmen
(die Zeit läuft dabei auf 20 % weiter, wie beim Nachhall), **F tippen** startet
das zuletzt gewählte. Programme:
1. **Störung** (gibt es): taumeln.
2. **Waffensperre** (gibt es): halber Schaden.
3. **Blendung**: Augenimplantate fallen aus, Gegner verliert den Spieler aus
   der Sicht (Schleichgang!) und tappt 6 s blind.
4. **Überhitzung**: Implantate glühen, Brandschaden (passt zu Aurels Glut-Ast:
   mit „Glutnarben“ länger).
5. **Fehlbefehl** (war geplant): Wache greift 6 s andere Konzernkräfte an.
6. **Kurzschluss** (Spät-Programm): springt auf alle vernetzten Gegner über
   (siehe `konzernnetz.md`).
Konzern-**Netzwächter** (neuer Gegnertyp) hacken zurück: Ein Balken zeigt, dass
Aurel aufgespürt wird; ist er voll, verliert Aurel Fokus und wird markiert,
außer er bricht Sicht oder erledigt den Netzwächter.

## Warum es zu unserem Spiel passt
- Aurel war Konzernangestellter: „Ich kenne eure Systeme“ ist seine Identität.
- Kosten bleiben **Ehrgeiz + Fokus**: Wer nicht angreift, verliert Ehrgeiz und
  kann weniger hacken. So bleibt Aurel aggressiv, Hacken ist Würze, kein Ersatz.
- Hacks wirken nur auf Technik: Geister, Wesen und Illusionswesen sind immun.
  Gibt Gegnern in Spiegelrealitäten einen eigenen Charakter.
- Gegen-Hacker geben Hack-Kämpfen ein Risiko (Soulslike: nichts ist gratis).

## Eigene Startwerte (zum Feintunen)
| Programm | Hochladen | Ehrgeiz + Fokus | Wirkung | Abklingzeit je Ziel |
|---|---|---|---|---|
| Störung | 1,0 s | 40 + 10 | taumeln 1,5 s | 12 s |
| Waffensperre | (mit Störung) | – | −50 % 8 s | – |
| Blendung | 0,8 s | 30 + 10 | blind 6 s | 15 s |
| Überhitzung | 1,2 s | 45 + 15 | 8 Schaden/s, 5 s | 15 s |
| Fehlbefehl | 1,5 s | 60 + 15 | 6 s Seitenwechsel | 25 s |
| Kurzschluss | 1,5 s | 80 + 20 | Störung auf alle im Netz | 40 s |
| Rad offen | Zeit × 0,2 | – | Auswahl in Ruhe | – |
| Aufspüren durch Netzwächter | 6 s | – | −20 Fokus, Fahndung +15 | – |

## Umsetzung im Projekt
- Neue Resource `HackProgramData` (`scripts/skills/hack_program_data.gd`, .tres in
  `resources/hacks/`): Name, Upload, Kosten, Wirkung (enum), Werte,
  `required_skill`.
- `Player.start_hack()` nimmt das gewählte Programm; Wirkung in `Enemy.receive_hack()`
  erweitert (`blind_left`, `apply_burn`, `faction_override`).
- Rad: `scenes/ui/hack_wheel.tscn` (`GameMenu`-artig, aber ohne Pause; nutzt
  `GameState.world_time_scale`).
- Skills in `aurel_tree.tres` (Insider-Ast): `aurel_hack_blind`,
  `aurel_hack_overheat`, `aurel_hack_misdirect` (Story), `aurel_hack_cascade`.
- Gegner `resources/enemies/net_warden.tres` + `EnemyData.counter_hacks`.
- Test im Rauchtest: Blendung auf Wache → `EnemyPerception` sieht Spieler 6 s
  nicht; Überhitzung → Leben sinkt 5 s lang; Netzwächter in Sicht → nach 6 s
  Fokus −20.

## Offene Fragen an den Nutzer
- Rad beim Halten von F, oder Programme fest auf Tasten verteilen?
- Darf Tahirou etwas Ähnliches haben (z. B. Raben stören Technik), oder bleibt
  Hacken nur Aurels Sache?

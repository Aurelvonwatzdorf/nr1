# Zeitdehnung (Vergleich mit dem Nachhall, aktive Variante)

- **Status:** Idee (Nachhall ist gebaut, siehe `nachhall.md`)
- **Vorbild (nur Inspiration):** Die zwei Zeit-Implantate in Cyberpunk 2077: eins
  verlangsamt die Welt auf Knopfdruck für eine Weile, ein anderes nur kurz beim
  Ausweichen/Zielen. Keine Namen, Werte oder Effekte übernommen.
- **Für wen:** beide; Implantat (Nervensystem)

## Vergleich: was wir haben
| | Nachhall (gebaut) | Vorbild „aktiv“ | Vorbild „reaktiv“ |
|---|---|---|---|
| Auslöser | Treffer in den I-Frames | Taste | Ausweichen/Zielen in der Luft |
| Dauer | 2,5 s, Welt × 0,25 | mehrere Sekunden | Bruchteile |
| Kosten | 20 Fokus, 6 s Abklingzeit | Ladung, lange Abklingzeit | gering |
| Gefühl | Belohnung fürs Können | Machtfantasie | Präzision |

**Fazit:** Der Nachhall passt am besten zum Souls-Kampf und bleibt. Verbessern:
1. **Sichtbarer**: Nachbild der Figur an der Ausweichstelle (das „Nachhall“-Bild),
   Welt kurz entsättigt, Geräusche dumpf (Ton-Bereich 10).
2. **Kette**: In der Zeitlupe erneut perfekt ausweichen verlängert sie um 1 s
   (höchstens einmal).
3. **Aurel-Ausbau** (Aufstieg-Ast): Treffer in der Zeitlupe füllen Ehrgeiz doppelt.

## Neu: Zeitdehner (aktive Variante, spätes Implantat)
Auf Taste verlangsamt sich die Welt deutlich, die Figur bleibt schnell. Teuer,
selten, mit **Überlastung** (siehe `koerpergrenze.md`): Nach dem Ende ist die
Figur 3 s erschöpft (Ausdauer-Erholung aus). Konkurriert mit dem Nachhall um
denselben Platz (Nervensystem): man wählt eins.

## Eigene Startwerte (zum Feintunen)
| Wert | Nachhall (neu) | Zeitdehner |
|---|---|---|
| Welt-Tempo | 0,25 | 0,35 |
| Dauer | 2,5 s (+1 s Kette) | 4 s |
| Kosten | 20 Fokus | 35 Fokus |
| Abklingzeit | 6 s | 45 s |
| Danach | – | 3 s keine Ausdauer-Erholung |
| Preis | 900 (heute) | 2200 |

## Umsetzung im Projekt
- Vorhanden: `GameState.world_time_scale`, `WorldTime.move_slowed()`,
  `Player.start_afterimage()`. Zeitdehner nutzt dieselbe Leitung.
- Nachbild: Kopie des Platzhalter-Meshes mit transparentem Material, Tween aus.
- Kette: in `Player._on_hit_evaded()` prüfen, ob Nachhall schon läuft.
- Neues Item `time_stretcher.tres`, `grants_time_stretch`; Platz-Regel über
  `ItemData.implant_slot` (siehe `koerpergrenze.md`).
- Test im Rauchtest: Nachhall läuft, zweites Ausweichen → Restzeit +1 s;
  Zeitdehner aktiv → `world_time_scale` = 0,35 für 4 s, danach Ausdauer-Erholung 3 s aus.

## Offene Fragen an den Nutzer
- Aktive Zeitlupe überhaupt? Sie macht Kämpfe leichter (Souls-Gefühl leidet).

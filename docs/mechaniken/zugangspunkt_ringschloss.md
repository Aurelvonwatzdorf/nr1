# Zugangsknoten mit Minispiel „Ringschloss“

- **Status:** Idee
- **Vorbild (nur Inspiration):** Zugangspunkte mit Hack-Minispiel in Cyberpunk
  2077. **Bewusst ein anderes Minispiel** (kein Raster aus Codes), eigene Regeln,
  eigenes Aussehen.
- **Für wen:** Aurel (Insider-Ast); Tahirou kann Zugangsknoten nicht nutzen,
  dafür hat er andere Belohnungen (Raben-Ratschläge, Geisterorte)

## Was der Spieler erlebt
An Wänden im Konzernviertel, im Konzernturm und auf Schwarzmarkt-Dächern hängen
**Zugangsknoten** (blinkende Kästen). E startet das **Ringschloss**: drei bis
fünf ineinander liegende Ringe drehen sich, jeder hat eine Lücke. Man hält einen
Ring an (Taste/Tippen), wenn seine Lücke oben ist; dann kommt der nächste
innere Ring. Sind alle Lücken in einer Linie, ist das Schloss offen. Ein Fehlgriff
kostet Zeit; Zeit um = Alarm. Je nachdem, wie viele Ringe man schafft, gibt es
Belohnungen (Geld, Daten für Missionen, Karte der Kameras, Gegner im Gebiet
geschwächt). Während des Minispiels läuft die Welt verlangsamt weiter.

## Warum es zu unserem Spiel passt
- Eigene, einfache Idee, die auch auf dem iPhone mit einem Finger geht (Tippen).
- Timing-Spiel passt zum Souls-Gefühl (Parieren = Timing).
- Schwierigkeit steigt im Konzernviertel; die besten Knoten sitzen an schwer
  erreichbaren Stellen (Bewegungs-Mechaniken!).
- Daten aus Knoten können Hinweise auf Spiegelrealitäten oder Caspars Geschäfte
  enthalten: Story-Futter.

## Eigene Startwerte (zum Feintunen)
| Wert | Start | Begründung |
|---|---|---|
| Ringe | 3 (Markt) bis 5 (Konzernturm) | Schwierigkeit über Ort |
| Drehtempo | 90°/s außen, +25°/s je Ring innen | innen schwerer |
| Treffer-Toleranz | ±12° | fair auf Touch |
| Zeitlimit | 12 s | Druck |
| Fehlgriff | −2 s | Strafe ohne Abbruch |
| Belohnung je Ring | 40 Geld; ab 4 Ringen: Kamera-Karte; 5: Gegner im Gebiet −20 % Leben | Teilerfolg lohnt |
| Alarm bei Zeitablauf | Fahndung +20, Wachen kommen | Risiko |
| Skill „Firmenausweis“ | +3 s Zeit | vorhandener Knoten wird nützlicher |
| Welt während des Spiels | Tempo × 0,25 | angreifbar, aber fair |

## Umsetzung im Projekt
- `AccessNode` (`scripts/world/access_node.gd`, erbt von `Interactable`),
  `difficulty`, `node_id` (einmal knackbar, gespeichert in
  `GameState.cracked_nodes`).
- Minispiel als `scenes/ui/ring_lock.tscn` (`Control`, gezeichnet mit
  `draw_arc`), Signal `finished(rings_solved)`.
- Belohnungen über Level/`WantedSystem`/`MapData` (Kameras markieren).
- Test im Rauchtest: Minispiel mit festem Zufallswert, simuliertes Drücken zum
  richtigen Zeitpunkt → `finished(3)`; Zeitablauf → Fahndung +20.

## Offene Fragen an den Nutzer
- Gefällt dir das Ringschloss, oder lieber ein ganz anderes Minispiel?

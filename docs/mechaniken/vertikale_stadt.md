# Vertikale Stadt (Ebenen, Aufzüge, Dächer, Brücken)

- **Status:** Idee
- **Vorbild (nur Inspiration):** Die übereinander gebaute Stadt mit Aufzügen,
  Hochwegen und begehbaren Hochhäusern in Cyberpunk 2077. Kein Stadtplan, keine
  Gebäude oder Namen übernommen.
- **Für wen:** Welt (Santo Santiago), Level-Design

## Was der Spieler erlebt
Santo Santiago hat **Ebenen**: Unten die Straßen und Gassen, darüber
**Hochwege** und Brücken zwischen Türmen im Konzernviertel, oben Dachgärten der
Reichen und Landeplätze für Gleiter. In der Senke stapeln sich Hütten zu Türmen
mit Leitern und Seilbahnen. **Aufzüge** (E: „Nach oben“) fahren in Hochhäuser
und auf Dächer; manche brauchen einen Ausweis (Firmenausweis-Skill) oder einen
Hack. Von oben sieht man weit – und kann mit Fallschaden-Abrollen oder dem
Aufschlag-Implantat wieder herunter.

## Warum es zu unserem Spiel passt
- **Arm/Reich wird senkrecht**: Die Reichen leben oben im Licht, die Armen unten
  im Nebel. Starkes Bild für die Konzernwelt.
- Gibt den Bewegungs-Mechaniken (Aufschwung, Wandlauf, Doppelsprung, Sprungfeder)
  Orte.
- Aufzüge sind billige „Teleporter“ zwischen Ebenen, ohne Ladebildschirm.

## Eigene Startwerte (zum Feintunen)
| Wert | Start | Begründung |
|---|---|---|
| Ebenen Konzernviertel | Straße, Hochweg (+18 m), Dach (+45 m) | drei klare Höhen |
| Aufzugfahrt | 3 s mit Blick nach draußen | kurz, stimmungsvoll |
| Hochwege | 6–10 Brücken | Anfang |
| Senke | Hüttentürme mit Leitern bis +15 m | arm, improvisiert |
| Zugang Aufzug | frei / Ausweis / Hack | Fortschritt |

## Umsetzung im Projekt
- `CityGenerator`: neue Bauteile „Hochweg“ (Brücke zwischen zwei Türmen,
  `KIT_*`-Maße beachten), Dachflächen begehbar (Kollision oben auf Türmen).
  Achtung: `_batch_geometry()` fasst Bauteile zusammen – Kollision getrennt halten.
- `Elevator` (Interactable): zwei Haltepunkte, Kabine fährt per Tween, Spieler
  wird Kind der Kabine; `requires_skill`/`requires_hack`.
- Leitern: `Ladder` (Zustand `Climb` beim Spieler, rauf/runter mit W/S).
- Minimap: Ebene der Figur berücksichtigen (Dächer heller zeichnen).
- Test im Stadt-Test: Aufzug benutzen → Spieler nach 3 s auf Dachhöhe; nichts
  steckt in einem Haus.

## Offene Fragen an den Nutzer
- Wie hoch soll die Stadt werden? (Höher = mehr Aufwand und mehr Leistung.)

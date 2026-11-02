# Verkehr (Fahrzeuge und Gleiter in der Stadt)

- **Status:** Idee
- **Vorbild (nur Inspiration):** Verkehr auf den Straßen und in der Luft in
  Cyberpunk 2077. Keine Modelle, Werte oder Namen übernommen.
- **Für wen:** Welt (Santo Santiago); hängt an `fahrzeuge_fahren.md`

## Was der Spieler erlebt
Auf den Hauptstraßen und der Prachtstraße fahren Fahrzeuge, halten an Plätzen für
Fußgänger, hupen, wenn man im Weg steht, und weichen aus oder halten an, wenn
man vor ihnen steht. In den Gassen der Senke fährt fast niemand (zu eng), dafür
Lastenräder. Über dem Konzernviertel ziehen **Gleiter** in festen Bahnen
(Kulisse, nicht erreichbar) – die Reichen fliegen, die Armen laufen. Bei Gewalt
halten Fahrer an und fliehen zu Fuß; Fahrzeuge kann man dann nehmen.

## Warum es zu unserem Spiel passt
- Arm/Reich wird sichtbar: Verkehr im Norden, kaum Verkehr im Süden.
- Gleiter als Hintergrund kosten fast nichts (wenige Meshes auf Bahnen) und geben
  dem Himmel Tiefe.
- Fahrzeuge zum Mitnehmen, ohne ein Kaufsystem bauen zu müssen.
- Fahrzeug nehmen von einem Fahrer: Moral (Gier, wenn man ihn hinauszerrt).

## Eigene Startwerte (zum Feintunen)
| Wert | Start | Begründung |
|---|---|---|
| Fahrzeuge gleichzeitig | 12 im Umkreis 150 m (Web/iPhone 6) | Leistung |
| Tempo | 10–14 m/s | Stadt, Fußgänger |
| Anhalten vor Hindernis | 6 m | sicher |
| Gleiter | 8 auf 3 Bahnen | Kulisse |
| Erscheinen/Verschwinden | außerhalb der Sicht, > 120 m | kein Aufploppen |
| Fahrer hinauszerren | Moral −2 „Gier“ | Tat zählt |

## Umsetzung im Projekt
- `CityGenerator` liefert schon das Wegenetz; Fahrspuren nur auf Hauptstraßen
  (Straßen-Kennzeichen `is_main_road` im Bauplan `CityLayout`).
- `TrafficManager` (Level-Knoten): hält eine Anzahl `Vehicle` mit `VehicleAI`
  (Modus CRUISE) im Umkreis, ersetzt ferne durch neue.
- Gleiter: `Path3D` + `PathFollow3D`, einfache Meshes, kein Physik-Körper.
- Test im Stadt-Test: nach 5 s fahren Fahrzeuge; Spieler auf der Straße → das
  vordere hält in ≥ 4 m.

## Offene Fragen an den Nutzer
- Verkehr erst bauen, wenn Fahrzeuge selbst fahrbar sind? (Empfehlung: ja.)

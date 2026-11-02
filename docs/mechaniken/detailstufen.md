# Detailstufen und Leistungsstufen (Mac, iPhone, Web)

- **Status:** Idee
- **Vorbild (nur Inspiration):** Detailstufen (LOD) und Grafikstufen großer
  Open-World-Spiele wie Cyberpunk 2077. Eigene Lösung mit Godot-Werkzeugen.
- **Für wen:** Technik

## Was der Spieler erlebt
Das Spiel läuft auf dem iPhone flüssig und sieht auf dem Mac trotzdem reich aus.
Im Menü gibt es **Grafik: Akku / Ausgewogen / Schön**, Standard je Gerät. Ferne
Häuser werden einfacher, ohne dass man es sieht; Pflanzen und Kleinkram blenden
weich aus; Schatten nur in der Nähe.

## Warum es zu unserem Spiel passt
- R2 (iPhone/Web) ist offen: „noch nicht auf einem echten iPhone geprüft
  (Leistung!)“. Viele neue Ideen aus dieser Studie (Regen, Neon, Menschenmengen,
  Verkehr) brauchen Leistungs-Spielraum.
- Godot hat das meiste schon: automatische Mesh-LOD, Sichtweiten
  (`visibility_range`), Schatten-Abstände. Es muss nur eingestellt werden.

## Eigene Startwerte (zum Feintunen)
| Einstellung | Akku (iPhone) | Ausgewogen | Schön (Mac) |
|---|---|---|---|
| Ziel-Bildrate | 30 | 60 | 60 |
| Renderauflösung | 70 % | 85 % | 100 % |
| Schatten-Abstand | 25 m | 50 m | 90 m |
| Pflanzen-Sichtweite | 40 m | 80 m | 140 m |
| Echte Lichter | 6 | 10 | 16 |
| Volumetrischer Nebel / SSR | aus | aus / nur Regen | an |
| Menschen (Logik / Kulisse) | 30 / 60 | 50 / 120 | 70 / 200 |
| Umrisse (`outline.gdshader`) | nur Figuren | Figuren + nah | alles |

## Umsetzung im Projekt
- `GameState.graphics_tier` (gespeichert), Standard aus `OS.has_feature("mobile")`
  bzw. `"web"`. Menü-Eintrag in Pausen-/Hauptmenü.
- `GraphicsSettings` (Autoload oder statische Hilfe): setzt `Viewport.scaling_3d_scale`,
  `RenderingServer`-Schatten, `Environment`-Schalter, Budgets für
  `LightBudget`/`TrafficManager`/Bürger.
- Gebäude: `GeometryInstance3D.visibility_range_end` + Silhouetten-Ersatz
  (`visibility_range_begin` beim groben Mesh) je 48-m-Stück.
- Pflanzen (`ContinentPlants`, MultiMesh): Sichtweite + Ausblenden im Shader.
- Messen: kleines Debug-Overlay (F3) mit Bildrate, Draw-Calls, Lichtern.
- Test: Rauchtest setzt jede Stufe einmal und prüft, dass nichts abstürzt.

## Offene Fragen an den Nutzer
- Am iPhone 13 Pro lieber 30 Bilder/s mit schönerer Grafik oder 60 mit einfacherer?

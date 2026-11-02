# Welt ohne Ladebildschirm (Streaming)

- **Status:** Idee
- **Vorbild (nur Inspiration):** Die große Stadt ohne Ladebildschirme in
  Cyberpunk 2077 (Teile der Welt werden im Hintergrund nachgeladen). Keine
  Technik übernommen; eigene Lösung mit Godot-Mitteln.
- **Für wen:** Technik; Santo Santiago, Kontinent Aurion, Übergänge

## Was der Spieler erlebt
Man läuft vom Markt durch das Südtor auf den Kontinent, ohne dass das Bild
schwarz wird: Hinter dem Tor liegt die Straße schon da. Weit entfernte Teile der
Welt erscheinen als grobe Silhouetten und werden beim Näherkommen fein. Das
Spiel startet schneller, weil nicht mehr die ganze Stadt beim Laden gebaut wird.

## Warum es zu unserem Spiel passt
- Heute baut `CityGenerator` beim Laden die ganze Stadt (6600 Teile → ~250
  Meshes), `ContinentGenerator` den ganzen Kontinent. Das geht, wird aber mit
  jeder Region und jeder Ebene (Hochwege, Dächer) langsamer, besonders auf dem
  iPhone.
- Übergänge (`TravelGate`) wechseln heute die Szene. Mit Streaming könnten Stadt
  und Kontinent **eine** Welt sein – oder der Wechsel geschieht hinter einer
  kurzen Tor-Animation, während im Hintergrund geladen wird.
- **Spiegelrealitäten bleiben eigene Szenen** (mit Übergangs-Effekt): Der Bruch
  zwischen Welt und Illusion ist gewollt.

## Eigene Startwerte (zum Feintunen)
| Wert | Start | Begründung |
|---|---|---|
| Stück-Größe | 48 m (wie das vorhandene Zusammenfassen) | passt zum Batching |
| Fein geladen | Umkreis 150 m (iPhone 100 m) | Leistung |
| Grob (Silhouette) | bis 600 m | Skyline |
| Bauen pro Bild | höchstens 4 ms | kein Ruckeln |
| Tor-Übergang | 1,2 s Animation, Laden im Hintergrund | wirkt nahtlos |

## Umsetzung im Projekt
- **Schritt 1 (klein):** `TravelGate` lädt das Ziel per
  `ResourceLoader.load_threaded_request()`, sobald man sich dem Tor nähert;
  Wechsel ohne Wartezeit. **Achtung Web-Version:** ohne Threads → dort normal
  laden (Prüfen mit `OS.has_feature("threads")`).
- **Schritt 2:** `CityGenerator` baut die Daten (Häuser, Straßen) wie heute
  berechnet, aber die **Meshes je 48-m-Stück erst bei Bedarf** (`ChunkStreamer`
  im Level, Warteschlange, Zeitbudget pro Bild). Kollision für Stücke in der
  Nähe, Silhouetten-Mesh (ein Quader je Haus, ein Material) für ferne.
- **Schritt 3:** gleiche Technik für `ContinentGenerator` (Höhenraster in
  Kacheln, Pflanzen-MultiMesh je Kachel).
- Gespeicherter Seed sorgt dafür, dass jedes Stück immer gleich aussieht
  (wichtig für die Spiegelstadt-Kopien, `extra_clear_circles`).
- Test im Stadt-Test: Spieler 300 m bewegen → Stücke laden/entladen, nichts
  steckt in Häusern; Bildzeit-Spitzen < 30 ms (Messung über `Performance`).

## Offene Fragen an den Nutzer
- Sollen Stadt und Kontinent langfristig **eine** zusammenhängende Welt werden?

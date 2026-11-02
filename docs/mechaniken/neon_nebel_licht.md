# Neon, Nebel und Lichtkegel

- **Status:** Idee
- **Vorbild (nur Inspiration):** Neon-Schilder, dichter Dunst und sichtbare
  Lichtkegel in Cyberpunk 2077. Keine Schilder, Schriften oder Logos übernommen.
- **Für wen:** Welt; Grafik

## Was der Spieler erlebt
Nachts tauchen Neon-Schilder in Gold, kaltem Blau und Glut-Orange die Gassen in
Farbe. Laternen, Scheinwerfer der Gleiter und Fenster werfen **sichtbare
Lichtkegel** in den Nebel, der aus der Senke hochkriecht. Schilder flackern
manchmal, ein Buchstabe ist kaputt. Die Schriften sind **eigene Zeichen** der
Welt (Mischung aus Japanisch, mongolischer Schrift und eigenen Glyphen,
keine echte religiöse Schrift).

## Warum es zu unserem Spiel passt
- Stil-Leitfaden: Nur Neon, Gold, kaltes Blau, Augen und Magie leuchten. Neon-
  Schilder liefern genau diese Akzente in den sonst dunklen Vierteln.
- Viertel bekommen Licht-Persönlichkeit: Konzernviertel kaltes Blau, Markt Gold,
  Senke flackerndes Orange und kaputte Schilder.
- Lichtkegel im Nebel geben Tiefe, auch auf dem einfachen Grafikmodus.

## Eigene Startwerte (zum Feintunen)
| Wert | Start | Begründung |
|---|---|---|
| Echte Lichter (OmniLight) nahe Kamera | 16 Mac / 6 iPhone | Leistung |
| Fern-Lichter | nur leuchtendes Material + Glow, kein Licht | günstig |
| Volumetrischer Nebel | Mac: an, Dichte 0,02 in der Senke; iPhone/Web: aus | Leistung |
| Lichtkegel-Ersatz | weiche Kegel-Meshes, additiv, verblassen zur Kamera | billig, sieht gut aus |
| Flackern | 1 von 12 Schildern | lebendig |

## Umsetzung im Projekt
- `CityGenerator`: Neon-Schilder als Bauteile (Rahmen + leuchtende Fläche,
  Glyphen aus einer eigenen kleinen Atlas-Textur, im Code erzeugt oder selbst
  gezeichnet). Leuchten über COLOR/UV in `building.gdshader` (vorhanden).
- `LightBudget` (Level-Knoten): schaltet die nächsten N `OmniLight3D` zur Kamera
  an, ferne aus (Licht-„Streaming“).
- Lichtkegel: `assets/materials/light_cone.gdshader` (additiv, Fresnel-Rand,
  Abstands-Ausblendung), Mesh `CylinderMesh` mit Radius oben 0.
- Volumetrischer Nebel nur über Projekt-Override (`.mobile`/`.web` aus).
- Prüfung: Screenshots Senke/Konzernviertel nachts; Bildrate messen.

## Offene Fragen an den Nutzer
- Eigene Schriftzeichen für Schilder: Möchtest du eine eigene „Stadtschrift“
  (Claude entwirft einfache Glyphen), oder lieber lesbare deutsche Wörter?

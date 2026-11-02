# Nasse Straßen und Regen (Spiegelungen, günstig)

- **Status:** Idee
- **Vorbild (nur Inspiration):** Regennasse, spiegelnde Neon-Straßen in Cyberpunk
  2077 (und Blade Runner). Keine Texturen oder Shader übernommen; eigener Shader
  im ToonStyle.
- **Für wen:** Welt; Grafik (Mac, iPhone, Web)

## Was der Spieler erlebt
Bei Regen werden die Straßen dunkler und glänzen; Pfützen spiegeln Neon,
Laternen und Fenster als verwischte Farbstreifen. Regentropfen fallen schräg im
Licht von Laternen, platschen in Pfützen, Rinnsale laufen an Wänden. Nach dem
Regen trocknet es langsam, zuerst die Ränder. Die Figur bekommt nasse,
dunklere Kleidung und hinterlässt kurz Fußspuren in Pfützen.

## Warum es zu unserem Spiel passt
- Der Stil-Leitfaden will dunkel mit leuchtenden Akzenten: **Spiegelungen
  verdoppeln jedes Neon** ohne mehr Lichter.
- **Spiegel** sind das Thema des Spiels: In Pfützen kann sich im Realitätsblick
  die wahre Welt spiegeln, nicht die Illusion (kleines, starkes Detail).
- Muss gezeichnet bleiben: Spiegelungen als **weiche Farbflächen** im
  Toon-Look, nicht fotorealistisch.

## Eigene Startwerte (zum Feintunen)
| Wert | Start | Begründung |
|---|---|---|
| Nässe hoch/runter | 40 s / 180 s | Wechsel sichtbar |
| Pfützen-Anteil | 25 % der Straße (Rauschmaske) | nicht alles Spiegel |
| Spiegelung Mac | Bildschirm-Spiegelung (SSR) nur auf Straßen + Reflexionssonde | Qualität |
| Spiegelung iPhone/Web | vorgebackene Neon-Streifen-Textur, die mit der Kamera wandert | sehr günstig |
| Regen-Partikel | 2000 Mac / 500 iPhone, nur um die Kamera | Leistung |
| Tropfen-Streifen in Laternenlicht | Billboards an Laternen | billig, wirkt stark |

## Umsetzung im Projekt
- Globaler Shader-Parameter `wetness` (0–1) aus `WeatherSystem`
  (`tag_nacht_wetter.md`).
- **Boden-Shader**: Straßen bekommen eigenes Material (heute meist
  `ToonStyle.make()`), z. B. `assets/materials/street.gdshader`: `wetness` senkt
  Rauheit, dunkelt Grundfarbe, Pfützen-Maske aus Rauschtextur (eigene, im Code
  erzeugt: `NoiseTexture2D`). Toon-Stufen beibehalten (Licht in 2–3 Bänder).
- Mac (Forward+): `Environment.ssr_enabled` nur bei Regen; iPhone/Web: Fake-
  Spiegelung (Neon-Farben der Umgebung als Gradient, über `VIEW`-Richtung
  verschoben).
- Regen: `GPUParticles3D` an der Kamera (`CPUParticles3D` für Web/Compatibility).
- Realitätsblick-Pfützen: Pfützen-Shader liest `GameState.reality_sight_active`
  über globalen Parameter `true_sight` und färbt die Spiegelung um.
- Prüfung: `./game/tools/screenshots.sh` mit neuem Ort `regen_markt`; Leistung
  auf dem Mac messen (Bildrate vorher/nachher).

## Offene Fragen an den Nutzer
- Wie oft soll es regnen? (Häufig = mehr Stimmung, aber weniger Abwechslung.)

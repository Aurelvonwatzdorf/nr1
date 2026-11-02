# Hologramme und Konzern-Werbung

- **Status:** Idee
- **Vorbild (nur Inspiration):** Riesige Werbe-Hologramme und Bildschirme an
  Hochhäusern in Cyberpunk 2077. **Keine** Werbung, Marken, Figuren oder Texte
  übernommen; alles für unsere eigenen Konzerne neu.
- **Für wen:** Welt; Story (Konzerne)

## Was der Spieler erlebt
Über dem Konzernviertel drehen sich riesige, halbdurchsichtige Hologramme:
Ein Gesicht lächelt, eine Hand bietet eine Ampulle an, ein Schriftzug verspricht
„Ruhe“. Auf dem Markt flimmern kleine Hologramme über Ständen (Waren, Preise).
Werbung **spricht einen an**, wenn man vorbeigeht. Im **Realitätsblick** zeigen
manche Hologramme ihre wahre Botschaft: ein Auge, das beobachtet; Werbung für
„Ruhe“ wird zur Werbung für Spiegelrealitäten.

## Warum es zu unserem Spiel passt
- Die Konzerne beherrschen die Welt: Ihre Werbung ist überall. Das erzählt die
  Welt, ohne Text-Tafeln.
- **Realitätsblick** bekommt in der normalen Stadt etwas zu tun: Werbung lügt.
- Eigene Konzerne der Welt (Vorschläge, nur in der Werbung): **Spiegelwerk**
  (Hersteller der Spiegelrealitäten, offiziell „Erholungswelten“), **Halcón
  Sicherheit** (Konzernwachen), **Ampulla** (Arznei, Kraftampullen).

## Eigene Startwerte (zum Feintunen)
| Wert | Start | Begründung |
|---|---|---|
| Große Hologramme | 5 im Konzernviertel, 1 am Markt | Wahrzeichen |
| Kleine Stand-Hologramme | 1 je 3 Stände | Leben |
| Durchsichtigkeit | 55 %, Abtastlinien, leichtes Zittern | erkennbar „Licht“ |
| Sprechende Werbung | Radius 6 m, 1 Satz, 60 s Pause | nicht nerven |
| Wahre Botschaft | nur im Realitätsblick | Belohnung für Q |

## Umsetzung im Projekt
- `Hologram` (`scripts/world/hologram.gd`): Mesh/Sprite3D mit
  `assets/materials/hologram.gdshader` (unshaded, additiv, Abtastlinien über
  `UV.y + TIME`, Rand-Fresnel, Störung über Rauschen). Zweite Fläche mit
  `RealityLayerObject` (TRUE_WORLD) für die wahre Botschaft.
- Bilder für Hologramme: eigene, einfache Formen (Gesicht als Umriss, Hand,
  Ampulle) aus Meshes/2D-Zeichnungen. Keine fremden Bilder.
- `CityGenerator` stellt sie an festen Orten im Bauplan auf (`CityLayout`).
- Durchsichtig → wird nicht zusammengefasst (siehe CLAUDE.md, Batch-Ausnahme).
- Prüfung: Screenshot Konzernviertel nachts, einmal mit Realitätsblick.

## Offene Fragen an den Nutzer
- Konzern-Namen „Spiegelwerk“, „Halcón Sicherheit“, „Ampulla“ – passen sie, oder
  hast du eigene?

# Musterblick (Scanner) und Rabenspäher

- **Status:** Idee
- **Vorbild (nur Inspiration):** Der Scanner in Cyberpunk 2077 (Ziel ansehen,
  Infos über Gegner, Schwächen, Geräte, Kopfgeld). Keine Darstellung, Namen oder
  Werte übernommen.
- **Für wen:** Aurel (Augen-Implantat „Musterlinse“), Tahirou (Rabenspäher)

## Was der Spieler erlebt
**Aurel** hält eine Taste (oder Lock-on + kurz warten) und die Welt wird
entsättigt, Konzern-Technik blau, Gegner gelb: Über dem Ziel stehen Name, Stufe,
Gefahr, Widerstände (z. B. „immun gegen Hacks“), Schwachstelle und ob es zu einem
Konzernnetz gehört. Bürger zeigen ein Detail (Beruf, Schulden bei Caspar!),
Gegenstände ihren Wert.
**Tahirou** hat keine Linse. Er schickt einen **Raben**, der über dem Gebiet
kreist: Alle Gegner darunter werden für eine Weile durch Wände sichtbar markiert,
und die alten Raben flüstern eine Einschätzung („Der Große links ist langsam,
aber trifft hart“).

## Warum es zu unserem Spiel passt
- **Abgrenzung zum Realitätsblick (Q)**: Der Realitätsblick zeigt, was **wahr**
  ist (Illusion gegen Wirklichkeit, Geist). Der Musterblick zeigt **Daten**
  (Technik, Werte). Zwei verschiedene Fragen, zwei Figuren-Wege.
- Für Aurel natürlich (Konzerntechnik), für Tahirou über seine Raben (Ressource
  Rabenbund, „Alte Stimmen“-Fähigkeit wird stärker).
- Gegner-Infos helfen beim Souls-Lernen, ohne das Erkunden zu verderben: Erst nach
  dem ersten Kampf mit einem Gegnertyp gibt es alle Werte.

## Eigene Startwerte (zum Feintunen)
| Wert | Start | Begründung |
|---|---|---|
| Musterblick | gratis, solange gehalten; Welt-Tempo × 0,5 | Werkzeug, keine Waffe |
| Reichweite | 35 m | – |
| Infos vor erstem Kampf | Name, Gefahr | Rest nach Begegnung |
| Rabenspäher | 25 Rabenbund, 12 m Radius, 15 s markiert | eigene Kosten |
| Raben-Einschätzung | 1 Satz pro Gegnertyp, dann still | Gaben-Regel: nichts Offensichtliches |
| Preis Musterlinse | 500 (Schwarzmarkt) oder Startausrüstung Aurel | Aurel kann früh |

## Umsetzung im Projekt
- Einträge zu Gegnertypen: `EnemyData.scan_text`, `resistances` (Liste),
  `GameState.known_enemy_types` (gespeichert).
- Aktion `scan` (Taste: Q halten? → nein, Q bleibt Realitätsblick; Vorschlag:
  Mittelklick halten = Scannen, kurz = Lock-on) – siehe offene Frage.
- HUD: `scenes/ui/scan_panel.tscn` am Lock-on-Punkt.
- Overlay: Parameter `scan` im vorhandenen Overlay-Shader (Entsättigung).
- Tahirou: `RavenComponent` + Markierung über `Enemy.set_marked(seconds)`
  (Umriss durch Wände: zweiter Pass des `outline.gdshader` mit `depth_test_disabled`).
- Test im Rauchtest: Aurel scannt Wache → Panel zeigt `display_name`; Tahirou
  Rabenspäher → Wachen in 12 m `is_marked()`.

## Offene Fragen an den Nutzer
- Welche Taste für den Scanner? (Lock-on halten wäre ein Vorschlag.)

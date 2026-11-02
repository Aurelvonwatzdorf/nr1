# Wurfklingen

- **Status:** Idee
- **Vorbild (nur Inspiration):** Messer werfen in Cyberpunk 2077 (auch
  Wurfmesser in Souls-Spielen). Keine Werte übernommen.
- **Für wen:** beide; als verbrauchbarer Gegenstand oder Nahkampfwaffe mit
  Wurf-Eigenschaft

## Was der Spieler erlebt
Mit einer Wurfklinge in der Hand (Messer, Dolch, später Rabenfeder-Klingen für
Tahirou) zielt man kurz und wirft. Die Klinge fliegt im Bogen, steckt im Gegner
oder in der Wand und muss **wieder aufgesammelt** werden (E), außer man hat sie
als billige Stapelware gekauft. Kopftreffer aus dem Verborgenen sind tödlich
gegen schwache Gegner. Leise: Wurf macht keinen Lärm.

## Warum es zu unserem Spiel passt
- Leiser Fernkampf für den Schleichgang (Schüsse holen Fahndung, Klingen nicht).
- Souls-Gefühl: knappe Wurfwaffen als Werkzeug, nicht als Hauptwaffe.
- Tahirou: **Rabenfedern** (Rabenbund-Ast): kehren von selbst zurück, kosten
  etwas Rabenbund statt Munition. Eigene Variante statt Kopie.

## Eigene Startwerte (zum Feintunen)
| Wert | Start | Begründung |
|---|---|---|
| Schaden | 18, Kopf ×2 (Hinterhalt ×3) | Hinterhalt belohnen |
| Flugtempo | 22 m/s, leichter Bogen | treffbar, aber nicht sofort |
| Ausdauer | 10 | wie leichter Schlag |
| Stapel Wurfmesser | 6 Stück, 60 Geld | knapp |
| Liegen bleiben | 120 s, dann weg | Ordnung in der Welt |
| Rabenfedern | 3 Stück, 8 Rabenbund je Wurf, kommen in 1,5 s zurück | eigene Variante |

## Umsetzung im Projekt
- Item `throwing_knife.tres` (CONSUMABLE, neues Feld `throwable`), Taste: wie
  Schusswaffe (`fire`), wenn keine Schusswaffe ausgerüstet, oder Schnellwahl
  (siehe offene Frage).
- Szene `scenes/combat/thrown_blade.tscn` (`RigidBody3D` oder eigenes Fliegen mit
  `ShapeCast3D`, Hitbox, bleibt stecken, wird `ItemPickup` ohne `pickup_id`
  im Speicherstand).
- Tahirou-Knoten im Rabenbund-Ast (`tahirou_feather_blades`).
- Test im Rauchtest: Wurf auf Puppe in 8 m → Treffer nach ~0,4 s, Klinge liegt
  danach als Fundstück.

## Offene Fragen an den Nutzer
- Brauchen wir eine **Schnellwahl** (Rad oder Steuerkreuz) für Wurfklingen,
  Granaten, Tränke? Das wäre eine größere UI-Entscheidung.

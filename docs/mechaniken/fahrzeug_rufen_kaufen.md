# Eigenes Fahrzeug: rufen, kaufen, Garage

- **Status:** Idee
- **Vorbild (nur Inspiration):** Eigene Fahrzeuge herbeirufen und bei Händlern
  kaufen in Cyberpunk 2077. Keine Namen, Preise oder Modelle übernommen.
- **Für wen:** beide

## Was der Spieler erlebt
Man besitzt Fahrzeuge (das erste bekommt man in einer frühen Mission, z. B. ein
altes Motorrad von einem Bekannten aus der Senke). Mit einer Taste (oder über das
Pausenmenü) **ruft man sein Fahrzeug**: Es fährt von selbst über die Straßen
heran und hält neben der Figur. Weitere Fahrzeuge kauft man bei einem **Händler
am Stadtrand** oder bekommt sie als Belohnung. Auf dem Kontinent ruft man statt
eines Fahrzeugs sein **Steppenross** mit einem Pfiff. In Spiegelrealitäten,
Konzerngebäuden und der Geisterwelt kann man nicht rufen.

## Warum es zu unserem Spiel passt
- Geldziel neben Waffen und Implantaten (und Schulden bei Caspar!).
- Rufen über das vorhandene Wegenetz (`CityGenerator.find_route()`) – das gibt es
  schon für das Navi.
- Kein Rufen in Realitäten/Geisterwelt erhält die Regel „Verbündete und Hilfe
  lassen sich nicht herbeirufen“ dort, wo es um Spirituelles geht.
- Caspar-Schulden: Bei langen Schulden kann er ein Fahrzeug pfänden lassen
  (spätere Idee für M10).

## Eigene Startwerte (zum Feintunen)
| Wert | Start | Begründung |
|---|---|---|
| Rufen: Ankunft | 4–12 s, je nach Weg | sichtbar heranfahren |
| Rufen: Erscheinen außer Sicht | ≥ 40 m entfernt hinter einer Ecke | kein Aufploppen vor der Kamera |
| Abklingzeit | 30 s | kein Spam |
| Erstes Motorrad | Mission „Altes Eisen“ (Vorschlag) | an Story binden |
| Preise | 1500 (Motorrad) – 6000 (gepanzerter Wagen) | Langzeitziel |
| Zerstört | 60 s bis wieder rufbar, Reparatur 10 % Preis | kleine Strafe |

## Umsetzung im Projekt
- `GameState.owned_vehicles`, `active_vehicle` (gespeichert).
- Aktion `call_vehicle` (Taste B / Gamepad: Steuerkreuz rechts halten).
- `VehicleCaller` im Level: sucht Startpunkt auf dem Wegenetz außerhalb der
  Kamera, fährt per KI (`VehicleAI`: Route folgen, langsam am Ende).
- Händler: `Merchant`-Abwandlung, Waren = `VehicleData`.
- `Level.allows_vehicle_call` (aus in `RealityLevel`, `SpiritWorld`,
  `CorporateTower`).
- Test im Rauchtest: Fahrzeug besitzen, rufen → nach höchstens 15 s steht es
  in < 6 m Abstand.

## Offene Fragen an den Nutzer
- Erstes Fahrzeug über Mission oder einfach kaufen?

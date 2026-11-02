# Fahrzeuge fahren (Wagen, Motorrad, Steppenross)

- **Status:** Idee
- **Vorbild (nur Inspiration):** Autos und Motorräder in Cyberpunk 2077 (und GTA).
  Keine Fahrzeugmodelle, Marken, Namen oder Fahrwerte übernommen.
- **Für wen:** beide; Welt (Santo Santiago, Kontinent Aurion)

## Was der Spieler erlebt
An geparkten Fahrzeugen erscheint „E: Einsteigen“. Die Kamera geht hinter das
Fahrzeug, WASD gibt Gas, bremst und lenkt, Leertaste ist die Handbremse
(Driften), Shift ein kurzer Schub. Drei Arten:
1. **Wagen** (Stadt): stabil, schützt vor Schüssen, schwer in engen Gassen.
2. **Motorrad**: schnell, wendig, passt durch Gassen; bei Zusammenstößen fliegt
   man herunter (Fallschaden!).
3. **Steppenross** (Kontinent): ein mechanisches Reittier im Stil der
   Reiterclans der Ewigen Steppe. Springt über Hindernisse, fährt durch Gelände,
   wo Räder hängen bleiben.
Fahrzeuge haben Leben; zu viel Schaden → sie qualmen, dann brennen sie. Bürger
springen zur Seite; wer sie anfährt, verletzt sie (Moral!).

## Warum es zu unserem Spiel passt
- Santo Santiago und vor allem der Kontinent mit neun Regionen sind groß.
  Fahrzeuge machen die Strecken zwischen Zeitinseln spielbar.
- **Steppenross** ist unsere eigene Mischung aus mongolischem Stil und Technik
  (Stil-Mix aus CLAUDE.md, Abschnitt 2), statt Autos in Mittelalter-Regionen.
- Bürger anfahren zählt im Moral-Gedächtnis (wie NPC verletzen).
- Fahrzeuge in Spiegelrealitäten verhalten sich falsch (fahren rückwärts,
  verschwinden): Hinweis auf die Illusion.

## Eigene Startwerte (zum Feintunen)
| Wert | Wagen | Motorrad | Steppenross |
|---|---|---|---|
| Höchsttempo | 32 m/s | 38 m/s | 20 m/s |
| Beschleunigung 0 → 20 m/s | 4,0 s | 2,5 s | 2,0 s |
| Lenkung | mittel | stark, kippt in Kurven | sehr stark |
| Gelände | nur Straße/flach | Straße/flach | alles bis 35° Steigung |
| Leben | 400 | 150 | 250 |
| Schutz für Fahrer | 80 % Schüsse | 0 % | 30 % |
| Abwurf bei Aufprall | – | ab 12 m/s | ab 16 m/s |
| Bürger anfahren | wie NPC verletzen/töten (Moral) | gleich | gleich |

## Umsetzung im Projekt
- **Kein** `VehicleBody3D` (zu zickig, teuer auf iPhone/Web), sondern ein
  eigenes **Arcade-Fahrzeug**: `CharacterBody3D` bzw. `RigidBody3D` mit vier
  Strahlen nach unten (Federung), eigenes Gas/Lenken/Driften:
  `scripts/vehicles/vehicle.gd` (`Vehicle`), Daten in `VehicleData` (.tres in
  `resources/vehicles/`).
- Einsteigen: `Vehicle` hat ein `Interactable`-Kind; Spieler-Zustand `Drive`
  (`drive_state.gd`): Spieler wird Kind des Fahrzeugs, Kollision aus,
  `CameraRig` folgt dem Fahrzeug (eigener Abstand/Sichtfeld).
- Neue Physik-Ebene 8 = Fahrzeug (Wert 128).
- Bürger weichen aus (`Citizen` prüft nahende Fahrzeuge), Treffer über
  `Hurtbox` mit Schaden aus Tempo.
- Touch: links Lenken/Gas als Stick, rechts Bremse/Schub.
- Test im Rauchtest: Spieler steigt ein → Zustand `drive`; Gas 2 s → Tempo > 8;
  aussteigen → Spieler steht neben dem Fahrzeug.

## Offene Fragen an den Nutzer
- Fahrzeuge in der Stadt **und** auf dem Kontinent, oder nur auf dem Kontinent
  (die Stadt ist eng und voller Fußgänger)?
- Gefällt dir das mechanische Steppenross?

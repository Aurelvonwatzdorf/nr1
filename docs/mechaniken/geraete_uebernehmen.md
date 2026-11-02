# Geräte übernehmen und Ablenkungen

- **Status:** Idee
- **Vorbild (nur Inspiration):** Kameras, Geschütztürme und Geräte in der Welt
  hacken und zur Ablenkung nutzen (Cyberpunk 2077, Watch Dogs). Keine Namen oder
  Werte übernommen.
- **Für wen:** Aurel (Insider-Ast), Tahirou mit eigener Variante (Raben)

## Was der Spieler erlebt
Konzern-Technik in der Stadt reagiert auf Aurel. Mit Realitätsblick oder Scanner
sieht er sie hervorgehoben. Mit F (anvisiert) kann er:
- **Kamera übernehmen**: Bild wechselt in die Kamera, man schaut sich um, markiert
  Gegner und springt in die nächste verbundene Kamera. Der eigene Körper steht
  derweil schutzlos.
- **Kamera abschalten**: Sie meldet keine Sichtungen mehr (Fahndung).
- **Wachturm/Geschütz umdrehen**: schießt kurz auf Konzernkräfte.
- **Ablenken**: Lautsprecher, Werbetafeln, Getränkeautomaten, Ampeln, Lichter
  spielen verrückt. Wachen in der Nähe gehen nachsehen und drehen sich weg.
- **Türen/Tore** des Konzerns öffnen (Abkürzungen, verschlossene Räume im
  Konzernturm).
Tahirou kann keine Technik hacken, aber einen **Raben schicken**: Er krächzt an
einem Ort (Ablenkung) oder setzt sich auf eine Kamera und verdeckt sie.

## Warum es zu unserem Spiel passt
- Füllt Aurels offene Frage aus `fernzugriff.md` („Darf Aurel später auch Technik
  in der Welt hacken?“).
- Der Konzernturm und das Konzernviertel bekommen Schleich-Lösungen neben dem
  Kampf.
- Kameras sind die „Augen“ der Fahndung: Sie zu blenden senkt die Fahndung
  schneller, sie zu übersehen erhöht sie.
- Beide Figuren können ablenken, aber auf ihre eigene Art.

## Eigene Startwerte (zum Feintunen)
| Wert | Start | Begründung |
|---|---|---|
| Reichweite | 25 m, Sicht nötig | weiter als Gegner-Hacks |
| Kamera übernehmen | 10 Fokus, solange man schaut 2 Fokus/s | Zeitlimit über Fokus |
| Kamera abschalten | 15 Ehrgeiz, 60 s | Aurel muss kämpfen, um zu schleichen |
| Ablenkung | 10 Ehrgeiz, Lärm 8 m, Wachen schauen 6 s | billig |
| Geschütz umdrehen | 50 Ehrgeiz + 15 Fokus, 10 s | stark, teuer |
| Tür öffnen | gratis mit „Firmenausweis“ | nutzt vorhandenen Skill |
| Rabe (Tahirou) | 15 Rabenbund, Lärm 8 m | eigene Ressource |
| Kamera sieht Spieler | Fahndung +5 alle 2 s | Kameras zählen |

## Umsetzung im Projekt
- Basis-Klasse `HackableDevice` (`scripts/world/hackable_device.gd`, Gruppe
  `hackable`, `is_targetable()`, `get_lock_on_point()` → Lock-on findet sie) mit
  `available_actions()` und `hack(action, player)`.
- Unterklassen: `SecurityCamera` (Sichtkegel, meldet an `WantedSystem`),
  `Turret`, `DistractionDevice` (sendet `EventBus.noise_made`), `CorporateDoor`.
- Kamerablick: zweite `Camera3D` in der Kamera, `CameraRig` gibt die
  Steuerung ab; HUD-Rahmen im Stil Konzern-Monitor.
- `CityGenerator` stellt Kameras und Automaten im Konzernviertel/Markt auf.
- Tahirou: `RavenComponent.spend()` + Rabe als kleine Szene, die hinfliegt.
- Test im Rauchtest: Ablenkung neben Wache → Wache läuft hin; Kamera abgeschaltet
  → Spieler in ihrem Kegel erhöht Fahndung nicht.

## Offene Fragen an den Nutzer
- Ist der „Blick durch die Kamera“ gewünscht (größerer Umbau der Kamera), oder
  reicht Abschalten/Ablenken?

# Stand des Projekts (Übergabe-Notiz)

Diese Datei sagt jeder neuen Claude-Sitzung (Browser oder Terminal), wo es
weitergeht. **Am Ende jeder Arbeitsrunde aktualisieren.** Alles Dauerhafte
(Design, Regeln) steht in `CLAUDE.md`.

## Zuletzt erledigt
- **Mechanik-Studie 1** (`/mechanik-studie`, Notizen in `docs/mechaniken/`),
  alles gebaut und im Rauchtest geprüft:
  - Wucht: schwere Schläge mit Ausholen, nicht unterbrechbar durch leichte
    Treffer, stärkerer Hitstop, Kamera-Ruck; Zweihand-Hammer beim Waffenschmied.
  - Schwarzmarkt-Implantate: Schubknoten (Schubsprung), Haftsehnen
    (Wandlauf), Nachhallkern (Zeitlupe beim Ausweichen im letzten Moment).
  - Aurel: Fernzugriff (F) und Waffensperre im Insider-Ast.
  - Am Mac noch zu prüfen: Gefühl/Tempo von Wandlauf und Schubsprung in den
    Gassen, Nachhall-Bildeffekt, Hammer-Ausholen.
- **M8.3 Einladung der Geister**: Am Schrein der alten Geister (Westrand von
  Santo Santiago, ✧) erscheinen ab Spiritualität 3 Geister, die Zeit steht
  still, „Mit ihnen gehen“ führt in eine erste Geisterwelt (Lichtung, Der
  Älteste, Tor zurück).
- **Zusammenarbeit Browser und Terminal** eingerichtet:
  - Regeln in `CLAUDE.md`, REA-Skill mit Regeln.
  - Test-Skript `./game/tools/run_tests.sh`.
  - Speichern mit einem Befehl: `./game/tools/speichern.sh "Nachricht"`.
  - Cloud-Start-Hook (Godot in ca. 3 s statt Bauen aus dem Quellcode).
  - Screenshots per Befehl: `./game/tools/screenshots.sh` (Cloud sieht jetzt Bilder).
  - Tests auf GitHub bei jedem Push (GitHub Actions).
- Nutzer-Entscheidung Design: zuerst **Figuren mit Animationen** (freie Pakete,
  z. B. Quaternius, KayKit, Mixamo). Noch nicht begonnen.

## Testversion
- Spiritualität startet mindestens auf Stufe 3 (`test_start_spirituality`),
  damit der Nutzer den Schrein ohne langes Beten testen kann.

## Noch vom Nutzer zu prüfen (nur am Mac sichtbar)
- Wie sehen der Grau-Effekt der angehaltenen Zeit, die Geister und die
  Geisterwelt aus? Passen Farben und Leuchten?

## Gerade: Warten auf den Nutzer
- Nutzer stellt auf GitHub den Spiel-Branch als Standard ein und testet M8.3
  am Mac. Erst nach seiner Rückmeldung mit M8.4 weitermachen.
- Der alte REA-Branch `claude/funny-goodall-e0rf8b` bleibt bestehen (Wunsch des
  Nutzers), wird aber nicht benutzt.

## Nächster Schritt
- **M8.4 Geisterwelt ausbauen**: mehr Wege und Orte, eigene Geisterwesen
  (friedliche und gefährliche), ein Bereich, in dem Rafa lebt (noch nicht
  betretbar, das kommt mit M9).
- Vorher den Nutzer fragen: Wünsche zu Aussehen und Wesen der Geisterwelt?

## Offene Fragen an den Nutzer
- Siehe `CLAUDE.md`, Abschnitt 9 (u. a. Ritual-Gegenstände, Bergtempel,
  wie man Rafa im Kampf „manipuliert“).

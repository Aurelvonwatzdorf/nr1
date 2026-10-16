---
name: region-ausbau
description: Baut eine Region des Kontinents Aurion weiter aus (neue Wahrzeichen, Siedlungen, Pflanzen, Bewohner, Stimmung). Nutzen, wenn der Nutzer eine Region verbessern oder erweitern möchte oder "/region-ausbau <Region>" tippt. Arbeitet mehrere Regionen nacheinander ab.
---

# Region-Ausbau

Ziel: Eine Region des Kontinents (siehe `docs/welt/KONTINENT.md`) Schritt für
Schritt lebendiger machen, möglichst automatisch, mit einer Rückfrage.
Antworten auf Deutsch, Nutzer ist Anfänger.

## Wo was steht
- Daten aller Regionen: `game/tools/make_continent.gd` (danach neu erzeugen:
  `godot --headless --path game -s res://tools/make_continent.gd` → schreibt
  `game/resources/world/continent.tres`). Felder: `ContinentRegion`.
- Gelände, Straßen, Flüsse, Bauplätze: `game/scripts/world/continent_generator.gd`
  (`_plan_landmarks()` legt fest, welche Bauten wo stehen).
- Bauten: `game/scripts/world/continent_landmarks.gd` (`_build_<art>()`, Helfer
  box/cylinder/gable/pyramid/marker/inspect_point).
- Pflanzen: `game/scripts/world/continent_plants.gd` (`pick()` je Stil).
- Test: `game/tests/continent_test.gd`; Bilder: `CONTINENT_VIEWS` in
  `game/tools/screenshot_tour.gd`.

## Regeln
- Nur Inspiration von beliebten Spielen (Stimmung, Aufbau), **nie** fremde
  Namen, Assets, Texte oder Code. Eigene Namen und Sätze auf Deutsch.
- Kulturen und Epochen respektvoll, ohne Klischees (CLAUDE.md, Abschnitt 4).
- Wahrzeichen nicht auf Straßen oder in steilen Hängen; Wege bleiben begehbar
  (Test „Alle Wege sind begehbar“).
- Neue Kollisionen: erst Position setzen, dann `add_child()`.

## Ablauf (je Region)
1. **Ansehen**: Region in `KONTINENT.md` und `make_continent.gd` lesen,
   `SHOT=<region> ./game/tools/screenshots.sh` und das Bild öffnen.
2. **Ideen**: 3–5 Vorschläge (Ort, Bau, Bewohner, Mechanik, Stimmung), jeweils
   ein Einzeiler, was der Spieler davon hat.
3. **EINE Rückfrage** (AskUserQuestion, multiSelect): Welche bauen? Empfohlenes
   zuerst mit „(Empfohlen)“. Nichts bauen ohne OK (außer der Nutzer hat freie
   Hand gegeben).
4. **Bauen** in kleinen Schritten, Prüfung im `continent_test` ergänzen.
5. **Prüfen**: `./game/tools/run_tests.sh`, Screenshots ansehen, nachbessern.
6. **Speichern**: `./game/tools/speichern.sh "Region <Name>: …"`, dann
   `KONTINENT.md`, CLAUDE.md und STAND.md aktualisieren.
7. **Berichten**: was neu ist und wo man es im Spiel findet (Karte M, Region).

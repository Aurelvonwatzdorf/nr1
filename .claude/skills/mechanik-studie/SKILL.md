---
name: mechanik-studie
description: Studiert Spielmechaniken als Vorbild (z. B. aus Cyberpunk 2077 oder anderen Spielen) und macht daraus eigene Designs für unser Godot-Spiel. Nutzen, wenn der Nutzer eine Mechanik, Fähigkeit, Waffe, Bewegung oder einen Stil aus einem anderen Spiel haben möchte, oder "/mechanik-studie" tippt. Arbeitet mehrere Mechaniken auf einmal ab.
---

# Mechanik-Studie

Ziel: Aus Vorbildern **eigene** Mechaniken für unser Spiel machen, möglichst
automatisch, aber mit Überblick für den Nutzer. Antworten auf Deutsch.

## Grenze (immer einhalten)
- Verstehen ja, übernehmen nie: **kein** fremder Code (auch nicht dekompiliert
  und "übersetzt"), keine Werte/Tabellen, Assets, Animationen, Texte oder Namen
  (z. B. keine Markennamen von Implantaten oder Fähigkeiten).
- Eigene Namen, eigene Werte, abgestimmt auf unser System (Ausdauer, Fokus,
  Ehrgeiz, Rabenbund, Soulslike-Kampf). Siehe CLAUDE.md, Abschnitt REA.
- REA nur für eine **gezielte Detailfrage** (z. B. "wie lange etwa ist das
  Zeitfenster?"), wenn Beschreibung/Video nicht reichen, und nur am Mac.

## Ablauf (für jede genannte Mechanik)
1. **Sammeln**: Was erlebt der Spieler? Auslöser, Ablauf, Dauer, Kosten,
   Gegenmittel, Risiko/Belohnung, Rückmeldung (Bild, Ton, Kamera). Quellen:
   Beschreibung des Nutzers, Videos/Bilder in `docs/stil/` oder
   `docs/mechaniken/vorlagen/`, allgemeines Spieldesign-Wissen.
2. **Übertragen**: Wozu passt es bei uns? (Aurel/Tahirou, Fähigkeitenast,
   Implantat vom Schwarzmarkt, Gegner, Realitätsblick …) Was muss anders sein,
   damit es zu Ausdauer-Kampf, Stil und Story passt?
3. **Notiz schreiben**: `docs/mechaniken/<snake_case_name>.md` nach der Vorlage
   `docs/mechaniken/VORLAGE.md` (eigener Name, eigene Startwerte, betroffene
   Dateien/Klassen im Projekt, Test-Idee, offene Fragen).
4. **Nach allen Notizen EINE Rückfrage** (AskUserQuestion, multiSelect): Welche
   davon bauen? Pro Mechanik eine Option mit Einzeiler. Nichts bauen ohne OK.
5. **Bauen** (nur Gewähltes, nacheinander, kleine Schritte): Code nach den
   Architektur-Regeln der CLAUDE.md, Prüfung im Rauchtest, bei Optik
   `./game/tools/screenshots.sh` und Bilder ansehen, dann
   `./game/tools/speichern.sh "…"`. Notiz-Status auf "gebaut" setzen,
   CLAUDE.md und STAND.md aktualisieren.
6. **Kurz berichten**: was gebaut wurde, wie man es im Spiel testet (Tasten,
   Ort), und was als Nächstes möglich ist.

## Stil-Studien
Bilder in `docs/stil/` beschreiben (Farben, Licht, Formen, Stimmung) und als
Richtung in `docs/stil/STIL.md` festhalten; umsetzen mit eigenen Shadern
(`ToonStyle`, Overlay) und freien CC0-Paketen (siehe CREDITS.md, falls genutzt).
Keine fremden Bilder als Texturen verwenden.

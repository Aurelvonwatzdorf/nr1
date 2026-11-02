# Stand des Projekts (Übergabe-Notiz)

Diese Datei sagt jeder neuen Claude-Sitzung (Browser oder Terminal), wo es
weitergeht. **Am Ende jeder Arbeitsrunde aktualisieren.** Alles Dauerhafte
(Design, Regeln) steht in `CLAUDE.md`.

## Zuletzt erledigt
- **Mechanik-Studie 2: Cyberpunk 2077 als Vorbild** (nur Notizen, noch nichts
  gebaut): 48 eigene Mechanik-Notizen in 10 Bereichen, Übersicht und
  Bau-Reihenfolge in `docs/mechaniken/README.md`. Grenzen eingehalten: kein
  fremder Code, keine Werte, Namen, Texte oder Assets; kein REA benutzt.
  Auffällige eigene Ideen: Körpergrenze (Technik im Körper senkt die
  Spiritualität), Erinnerungsspiegel (fremde Erinnerungen in Schichten
  Bild/Klang/Wahrheit), Steppenross, Spiegeljäger sehen durch Tarnung,
  Ringschloss-Minispiel, Stiller Radiosender mit Geisterstimmen.
  **Nutzer hat alle 16 Pakete gewählt.** Gebaut ist bisher Schritt 1:
  Luftsteuerung (Koyote-Zeit, Sprung-Puffer, kurzer/langer Sprung,
  weniger Lenken in der Luft, Doppelsprung lenkt neu), Aufschwung (Kanten
  hochziehen/überspringen), Fallschaden mit Abrollen, Gleitschritt und Ducken
  (C; Gamepad B halten; Touch „Duck.“), Implantat „Aufschlag“ (Schwarzmarkt).
  **Bau-Reihenfolge** (wegen Abhängigkeiten, je Schritt testen + speichern):
  1. Bewegung: Luftsteuerung ✅, Aufschwung ✅, Fallschaden/Abrollen ✅, Gleitschritt ✅,
     Aufschlag ✅; offen: Sprungfeder (Frage: statt Cyberbeinen?), Wandketten
  2. Tastenbelegung ✅ entschieden: Gamepad Tippen/Halten (`PadTapHold`),
     Tastatur C/T/G/Tab halten (siehe CLAUDE.md, Abschnitt 7)
  3. Leistung: Grafikstufen ✅ (F3 misst), Detailstufen teilweise; offen: viele
     Figuren günstig, Silhouetten, Stadt in Stücken bauen (Tor lädt schon im Hintergrund ✅)
  4. Schleichen: `EnemyPerception` ✅ → Erledigen → Schattenhaut
  5. Stadtleben: Stadtvolk, Fahndung in Stufen
  6. Hacking: Programme, Geräte/Kameras, Ringschloss, Konzernnetz
  7. Implantat-System: Körpergrenze (Design-Frage!), Ärztin, Musterblick,
     Zeitdehnung, Arm-Implantate, Wurfklingen
  8. Schusswaffen, Gütestufen/Aufsätze, Attribut-Schwellen
  9. Tageszeit/Wetter, vertikale Stadt, Grafik-Stimmung (Regen, Neon, Hologramme, Glitches)
  10. Ton: Klangwelt, Musik nach Lage
  11. Fahrzeuge → Verkehr, Radio
  12. Ruf, Kleidung, Gespräche unter Zeitdruck, Vermittler, Erinnerungsspiegel
  13. UI-Stil, Fotomodus (nach den Figuren-Modellen)
  Offene Fragen stehen am Ende jeder Notiz; vor jeder großen Design-Entscheidung
  fragen.
- **Web-Version** (Nutzer hat gerade nur das iPhone): GitHub Actions baut sie bei
  jedem Push und stellt sie auf https://aurelvonwatzdorf.github.io/nr1/ .
  Nutzer muss einmalig Pages → Source „GitHub Actions“ einschalten. In Chromium
  im iPhone-Format geprüft: Menü, Figurenwahl, Konzernturm mit Touch-Knöpfen.
  Offen: echte Leistung in Safari auf dem iPhone 13 Pro.
- **R2 iPhone (Nutzer-Wunsch)**: Touch-Steuerung (Stick, Knöpfe, Wischen,
  „Zurück“ in Menüs), Mobile-Einstellungen, App-Symbol, Xcode-Projekt per
  `./game/tools/iphone_bauen.sh`. Export in der Cloud geprüft. **Offen:** auf
  echtem iPhone testen (Leistung von Stadt/Kontinent, Größe der Knöpfe,
  Mobile-Renderer). Tutorial-Hinweise im Konzernturm nennen noch Tasten.
- **Fehler behoben:** Südtor führte zurück zum Marktplatz statt auf den
  Kontinent (Weltwechsel lud den alten Spielstand neu). Jetzt wird nur einmal
  pro Sitzung geladen; Test in `reality_test`.
- **R1 Erste spielbare Fassung**: Hauptmenü (Weiterspielen, Neues Spiel,
  Steuerung, Beenden), Pausenmenü „Zum Hauptmenü“, echte Mac-App mit
  `./game/tools/mac_app_bauen.sh` (ohne Testgeld/-spiritualität, eigener
  Spielstand). In der Cloud gebaut und geprüft (gepacktes Spiel startet ohne
  Fehler). Am Mac noch auszuprobieren: Start der App, Grafik, Tempo.
- **K1 Kontinent „Aurion“** (freie Hand vom Nutzer, Design in
  `docs/welt/KONTINENT.md`): neun Regionen als „Zeitinseln“ mit eigener Epoche,
  Bauweise, Pflanzen, Bewohnern, Nebelstimmung. Santo Santiago (Zukunft), Die
  Narbe (verwüstet), Kagerō-Gebirge (Schreine, Bergtempel = Ort für das Ritual
  M8.5), Ewige Steppe (Reiterclans), Grauwald-Mark (Mittelalter, Burg),
  Nebelwald (zeitlos, „Herz des Nebelwalds“, Spiritualität 5), Sonnenreich
  Kemet (Altes Ägypten, Pyramiden, Fluss), Neu-Vallis (Gegenwart), Gläserne
  Küste (ferne Zukunft). Straßenring + Speichen, Serpentine zum Bergtempel.
  Eingang: **Südtor von Santo Santiago** („Die Stadt verlassen“); zurück durch
  das Stadttor. Entdecken mit Titelkarte, Karte zeigt „???“ für Unentdecktes.
  Neuer Test `continent_test` (23 Prüfungen), Screenshots 10–19.
  Automatisierung: `/region-ausbau <Region>` baut eine Region weiter aus.
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
- Kontinent: Farben, Nebel, Berge (in der Cloud wirken sie blass), Tempo beim
  Laufen, Ruckeln? Bilder `screenshots/cloud/10_…19_*.png` zum Vergleich.
- Wie sehen der Grau-Effekt der angehaltenen Zeit, die Geister und die
  Geisterwelt aus? Passen Farben und Leuchten?

## Gerade: Warten auf den Nutzer
- Nutzer stellt auf GitHub den Spiel-Branch als Standard ein und testet M8.3
  am Mac. Erst nach seiner Rückmeldung mit M8.4 weitermachen.
- Der alte REA-Branch `claude/funny-goodall-e0rf8b` bleibt bestehen (Wunsch des
  Nutzers), wird aber nicht benutzt.

## Nächster Schritt
- **Stil festgelegt** (`docs/stil/STIL.md`, 18 Referenzbilder): dunkler Look,
  Tahirou Locken, Aurel Locs, Caspar als Kobold, Spiegeljäger-Entwürfe
  abgelehnt. **Jetzt:** Tahirou mit Higgsfield (Figurenblatt → 3D → Skelett →
  Animationen), Kosten vorher dem Nutzer nennen.
- **Entscheidung des Nutzers:** als Nächstes **Figuren & Animationen** (freie
  Modelle, z. B. Quaternius/KayKit, statt Kapseln; Laufen/Schlagen/Rollen über
  `PlayerAnimator`). **Nur auf Zuruf** – erst anfangen, wenn der Nutzer es sagt.
- Offen beim Nutzer: GitHub Pages einschalten (Settings → Pages → Source
  „GitHub Actions“), dann Web-Workflow neu starten.

## Offene Fragen an den Nutzer
- Siehe `CLAUDE.md`, Abschnitt 9 (u. a. Ritual-Gegenstände, Bergtempel,
  wie man Rafa im Kampf „manipuliert“).

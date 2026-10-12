# Spiegelrealitäten (Arbeitstitel)

Open-World-Action-RPG in Godot 4 im animierten Cel-Shading-Look (japanisch, mongolisch,
Cyberpunk). Drei Ebenen: die normale Welt, die **Geisterwelt** und die
**Spiegelrealitäten**, Illusionswelten, in die Konzerne Menschen sperren. Das komplette
Design (Story, Figuren, Mechaniken, Konventionen) steht in [`CLAUDE.md`](CLAUDE.md).

> Der Ordner `scripts/` im Hauptverzeichnis enthält Video-Skripte und gehört
> nicht zum Spiel. Das Spiel liegt komplett in `game/`.

## Projekt starten

1. **Godot 4.7 (Standard-Version, nicht .NET)** von <https://godotengine.org/download>
   herunterladen und entpacken. Godot muss nicht installiert werden, die Datei
   startet direkt.
2. Dieses Repository herunterladen (GitHub: **Code → Download ZIP**, oder
   `git clone`).
3. Godot starten. Im Projektmanager auf **Importieren** klicken und die Datei
   `game/project.godot` auswählen. Dann **Importieren & Bearbeiten** wählen.
4. Beim ersten Öffnen importiert Godot alles. Das dauert ein paar Sekunden.
5. Oben rechts auf **▶ (Projekt starten, F5)** klicken. Die Testarena startet.

## Steuerung

| Aktion | Tastatur/Maus | Gamepad |
|---|---|---|
| Bewegen | WASD | linker Stick |
| Kamera | Maus | rechter Stick |
| Sprinten | Shift halten | L3 halten |
| Ausweichen | Leertaste | B |
| Leichter Angriff | Linksklick | RB |
| Schwerer Angriff | Shift + Linksklick | RT |
| Blocken (im richtigen Moment: Parieren) | Rechtsklick | LB |
| Lock-on | Mittelklick / Tab | R3 |
| Realitätsblick *(ab M5)* | Q | Y |
| Interagieren (z. B. am Ankerspiegel rasten) | E | A |
| Heiltrank trinken | R | X |
| Inventar | I | Back/View |
| Verbündeten rufen *(ab M8)* | F | Steuerkreuz hoch |
| Pausenmenü | Esc | Start |

Alle Tasten lassen sich im Editor unter **Projekt → Projekteinstellungen →
Eingabezuordnung** ändern.

## Projektstruktur

```
game/
├── project.godot          Projekteinstellungen, Tastenbelegung, Autoloads
├── scenes/                Szenen (.tscn)
│   ├── player/            Spielfigur mit Kamera
│   ├── enemies/           Gegner, Trainingspuppe
│   ├── levels/            Level/Realitäten (zurzeit: Testarena)
│   └── ui/                HUD und Menüs
├── scripts/               GDScript-Code
│   ├── player/            Spieler, Kamera, Animator, states/ (Zustände)
│   ├── components/        Leben, Ausdauer, Fokus (wiederverwendbar)
│   ├── combat/            Hitbox, Hurtbox, Angriffsdaten
│   ├── characters/        CharacterData (Figuren als Daten)
│   ├── state_machine/     Allgemeine State Machine
│   ├── systems/           Autoloads: EventBus, GameState, SaveSystem
│   ├── enemies/ realms/ ui/
├── resources/             Daten (.tres): Figuren, Angriffe …
├── assets/                Modelle, Materialien, Audio (später)
└── tests/                 Automatischer Rauchtest
```

**Rauchtest** (prüft Angriff, Schaden, I-Frames, Figurenwahl ohne Bildschirm):
```bash
godot --headless --path game res://tests/smoke_test.tscn
```

## Roadmap

- ✅ **M1**: Spieler-Controller & Kampf-Grundlagen
- ✅ **M2**: Gegner-KI, Lock-on, Treffer-Feedback, Blocken, Tod/Respawn, Erinnerungen
- ⬜ **M3**: Stats & Level-Up, Speichern/Laden, Checkpoints, Heiltränke, Artefakte, Inventar
- ⬜ **M4**: NPCs, Missionen, Moral-Gedächtnis
- ⬜ **M5**: Charakterauswahl (Aurel/Tahirou), Fähigkeitenbäume
- ⬜ **M6**: Erste Open-World-Region (Hauptstadt), Karte, Cel-Shading-Look
- ⬜ **M7**: Spiegelrealitäten, „Konzernturm“, Adam
- ⬜ **M8**: Geisterwelt, Gebet, spiritueller Druck, Rituale
- ⬜ **M9**: Rafa & Daniel
- ⬜ **M10**: Caspar & Schulden-Assassinen
- ⬜ **M11+**: Weitere Regionen und Epochen, Gehege der Schweine, Spiegelstadt
- ⬜ **M12**: Finale „Der Coup“, Hauptmenü, Sound, Feinschliff

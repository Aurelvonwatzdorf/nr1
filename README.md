# Spiegelrealitäten (Arbeitstitel)

Third-Person-Action-RPG in Godot 4. Eine dystopische Welt, in der Konzerne
Menschen in Illusionswelten sperren, die **Spiegelrealitäten**. Das komplette
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
| Blocken *(ab M2)* | Rechtsklick | LB |
| Lock-on *(ab M2)* | Mittelklick / Tab | R3 |
| Realitätsblick *(ab M5)* | Q | Y |
| Interagieren *(ab M3)* | E | A |
| Heiltrank *(ab M3)* | R | X |
| Verbündeten rufen *(ab M8)* | F | Steuerkreuz hoch |
| Maus freigeben / Menü | Esc | Start |

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
- ⬜ **M2**: Gegner-KI, Lock-on, Treffer-Feedback, Tod/Respawn, Erinnerungen zurückholen
- ⬜ **M3**: Ankerspiegel, Speichern/Laden, Heiltränke, Inventar, Level-Up
- ⬜ **M4**: Charakterauswahl (Aurel/Tahirou), Fähigkeitenbäume, Progression
- ⬜ **M5**: Realitätsblick, Realitätsriss, Verankerung
- ⬜ **M6**: Tutorial-Level „Konzernturm“, erster Boss, Adam
- ⬜ **M7**: Tarnung/Verdacht, „Gehege der Schweine“, Boss „Mastmutter“
- ⬜ **M8**: Verbündeten-System (Rafa & Adam), Dialogsystem
- ⬜ **M9**: Spiegelstadt, Rafas Geschichte
- ⬜ **M10**: Finale „Der Coup“, Hauptmenü, Sound, Feinschliff

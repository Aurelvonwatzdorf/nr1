# CLAUDE.md – Projektgedächtnis

Diese Datei hält das komplette Design und die Arbeitsweise fest, damit jede neue
Sitzung sofort weiß, worum es geht. **Bei jeder Design- oder Strukturänderung hier
aktualisieren** (Roadmap-Status, offene Entscheidungen, neue Konventionen).

Das Repository enthält zwei Dinge:
- `game/`: das Godot-4-Spiel (Hauptprojekt, alles unten bezieht sich darauf)
- `scripts/`: Skripte für Faceless-Education-Videos (Higgsfield/Kling). Haben mit
  dem Spiel nichts zu tun und werden nicht angefasst.

---

## 0. Arbeitsweise mit dem Nutzer (WICHTIG)

- Der Nutzer ist **Anfänger**. Jeden Schritt kurz erklären: was und warum.
- Immer genau sagen, **was er im Godot-Editor klicken oder testen muss**.
- In **kleinen, testbaren Schritten** arbeiten. Nach jedem funktionierenden Schritt
  committen, damit man zurückkann.
- **Vor großen Designentscheidungen, die von diesem Dokument abweichen, fragen.**
  Vorschläge machen, aber nicht eigenmächtig festlegen (siehe „Offene Entscheidungen“).
- Antworten auf Deutsch.
- Vor „fertig“ immer Skriptfehler prüfen (siehe Abschnitt 1, „Prüfen“).
- Nach jedem Meilenstein: erklären, wie man testet, und fragen, ob es weitergeht.

---

## 1. Technik

- **Engine:** Godot 4 (aktuell 4.7.x stable), **GDScript mit statischen Typen**
  (Warnung `untyped_declaration` ist aktiv, keine untypisierten Variablen).
- **Renderer:** Forward+.
- **Projektordner:** `game/` (dort liegt `project.godot`).
- **Hauptszene:** `res://scenes/levels/test_arena.tscn` (bis es ein Hauptmenü gibt).

### Prüfen (vor jedem „fertig“)
```bash
godot --headless --path game --import          # Assets/Klassen importieren
godot --headless --path game --quit            # Projekt laden, Skriptfehler zeigen
godot --headless --path game -s res://tests/smoke_test.gd   # Logik-Rauchtest
```
In der Cloud-Umgebung ist Godot nicht vorinstalliert und Release-Downloads sind
gesperrt. Es wurde aus dem Quellcode gebaut (Tag `4.7.2-stable`, Klon unter
`/home/user/godotengine/godot`, ca. 30–60 Min.):
```bash
pip install scons
scons platform=linuxbsd target=editor x11=no wayland=no vulkan=no opengl3=no \
  alsa=no pulseaudio=no dbus=no speechd=no fontconfig=no udev=no accesskit=no sdl=no -j4
# Ergebnis: bin/godot.linuxbsd.editor.x86_64
```

### Ordnerstruktur (`game/`)
```
scenes/      player/, enemies/, levels/, ui/          (.tscn)
scripts/     player/ (+ states/), enemies/, combat/, components/, realms/,
             ui/, systems/, characters/, state_machine/
assets/      models/, materials/, audio/
resources/   characters/, attacks/ …                  (.tres-Daten)
tests/       Headless-Rauchtests
```

### Architektur-Regeln
- **Komponenten statt Riesenskripte:** `HealthComponent`, `StaminaComponent`,
  `FocusComponent` (alle erben von `StatPoolComponent`), `Hitbox`/`Hurtbox`.
- **State Machines** für Spieler und Gegner (`StateMachine` + `State`-Knoten).
  Der Besitzer ruft `state_machine.physics_update(delta)` selbst auf, danach
  `move_and_slide()`. So ist die Reihenfolge eindeutig.
- **Autoloads:** `EventBus` (globale Signale), `GameState` (gewählte Figur,
  Währung, Fortschritt), `SaveSystem` (Speichern/Laden als JSON in `user://`).
- **Daten statt Code:** Figuren-, Gegner-, Waffen-, Angriffs- und Fähigkeitswerte
  sind Resources (`.tres`). Aurel und Tahirou nutzen **denselben** Spieler-Controller
  und unterscheiden sich nur durch ihre `CharacterData`.
- **Animation:** Alle Animationswünsche laufen über `PlayerAnimator`. Solange es
  nur Platzhalter gibt, macht er einfache Tweens. Sobald ein echtes Modell
  (Mixamo/Blender) mit `AnimationTree` da ist, nutzt er dessen State Machine
  (`parameters/playback`). Die Spiellogik muss dafür nicht geändert werden.
- **Platzhalter:** Kapseln, Boxen und einfache Materialien, bis echte Modelle kommen.
- **Spieler-Eingabe** wird in den States per `Input.is_action_*` abgefragt, und nur,
  wenn `player.is_input_enabled()` (Maus gefangen, kein Menü offen).

### Physik-Ebenen
| Ebene | Wert | Name | Wer |
|---|---|---|---|
| 1 | 1 | Welt | Boden, Wände, Hindernisse |
| 2 | 2 | Spieler | Spielerkörper |
| 3 | 4 | Gegner | Gegnerkörper, Trainingspuppe |
| 4 | 8 | Hitbox | Angriffsflächen (suchen Hurtboxes) |
| 5 | 16 | Hurtbox | Trefferflächen (werden gefunden) |

### Konventionen
- Dateien und Ordner `snake_case`, Klassen `PascalCase` mit `class_name`.
- Bezeichner im Code auf Englisch, **Kommentare und Spieltexte auf Deutsch**.
- Signale in Vergangenheitsform (`died`, `hit_received`, `value_changed`).
- Keine geschützten Namen, Figuren oder Assets anderer Spiele übernehmen.
- Commits klein, Nachricht beschreibt den funktionierenden Schritt.

---

## 2. Genre & Gefühl

Third-Person-Action-RPG, inspiriert von Soulslikes (nur Inspiration):
- Ausdauerbasierter Kampf: leichter/schwerer Angriff, Ausweichrolle mit
  Unverwundbarkeitsfenstern (I-Frames), Blocken/Parieren, Lock-on,
  Treffer-Feedback (Hitstop, Kamerawackeln, Rückstoß).
- Leben, Ausdauer, Fokus (Mana) als Balken.
- **Ankerspiegel** (Rastpunkte): heilen, speichern, Heiltränke auffüllen, Gegner
  respawnen, Level-Up, Verbündete wechseln.
- Beim Tod verliert man die Währung **„Erinnerungen“**. Man kann sie an der
  Todesstelle zurückholen. Stirbt man vorher erneut, sind sie weg.
- Level-Up mit Attributen, Waffen mit Skalierung, Ausrüstung.
- Düster und rätselhaft, harte, aber faire Gegner, Bosse mit mehreren Phasen.

## 3. Welt & Story

Dystopische Welt, beherrscht von Konzernen. Sie besitzen die Technik, Menschen in
**Spiegelrealitäten** zu sperren: Illusionswelten, in denen das Opfer nicht merkt,
dass es gefangen ist. Jeder Konzern kontrolliert eigene **Helden** als Vollstrecker.

Eine Gruppe von Freunden will nach oben und gerät selbst in die Spiegelrealitäten.
In der gespielten Hauptfigur steckt der **Begleiter**, eine Helfer-Illusion, die
Hinweise gibt und lehrt, hinter die Realität zu sehen.

**Kernregel:** Eine Realität verlässt man nur, wenn man ihr Ziel erfüllt ODER die
Illusion durchschaut und bricht. Jede Realität hat eigene Regeln, Optik und
Mechaniken. Hinter jeder Realität kann eine weitere liegen.

## 4. Figuren

**Alle Figuren respektvoll und ohne Klischees darstellen. Herkunft und Glaube sind
Teil ihrer Identität und Geschichte, aber nie ein Witz.**

### Spielbare Hauptfiguren (Wahl zu Spielbeginn)
Beide starten schwach und werden extrem stark. Dieses Wachstum ist ein zentrales
Gefühl und zeigt sich in Fähigkeiten, Animationen, Dialogen und Haltung.
Eigener Kampfstil und eigener Fähigkeitenbaum je Figur. Freischaltung über
**Story-Fortschritt UND Level-Ups**.

- **Aurel**: Latino, Christ. Markenzeichen Zigarette: zündet sich eine an
  Ankerspiegeln, nach Bosssiegen und in Zwischensequenzen an. Startet als
  ehrgeiziger kleiner Konzernangestellter und wird einer der mächtigsten
  Charaktere der Welt.
- **Tahirou**: halb Latino, halb Afrikaner, Muslim. Entspannter Kiffer, den am
  Anfang wenig aus der Ruhe bringt, wenig Ehrgeiz. Entwickelt sich weiter, eignet
  sich immer mehr Fähigkeiten an und wird ebenfalls sehr, sehr stark. Seine
  Gelassenheit spielt spielerisch eine Rolle (siehe Offene Entscheidungen).

### Wichtige Verbündete
- **Rafael („Rafa“)**: Latino, Christ. Held wie ein göttlich gesandter Engel:
  starke Moral, gewaltige Kraft, strahlende Erscheinung. Später als mächtiger
  Verbündeter herbeirufbar. (Frei oder kontrolliert? Siehe Offene Entscheidungen.)
- **Adam**: Araber, Muslim, trägt eine Galabiya. Schlitzohr und Genie. Bewegt sich
  mühelos durch Spiegelrealitäten und kann selbst Realitäten erschaffen. Gibt
  Hinweise, öffnet Abkürzungen, erschafft im Finale die Illusion für den
  Konzernboss. Nie ganz durchschaubar, aber am Ende auf der Seite der Gruppe.
  Später herbeirufbar.

### Weitere Figuren
- **Der Begleiter**: Helfer-Illusion im Kopf der gewählten Figur, kurze Textzeilen.
- **Der Verräter**: rechte Hand des Konzernbosses, heimlicher Helfer der Gruppe.
  Kopiert im Finale das Gesicht des Bosses für Adams Illusion.
- **Die Konzernhelden**: kontrollierte Vollstrecker, Mini-Bosse.
- **Der Konzernboss**: Endgegner, Meister der Illusionen.

## 5. Kernmechaniken
1. **Realitätsblick** (Q): kostet Fokus und zeigt kurz die wahre Welt: versteckte
   Wege, wahre Gestalt von Gegnern, Risse. Umsetzung mit Post-Processing-Shader und
   Objekten, die nur in einer Ebene sichtbar oder begehbar sind.
2. **Realitätsriss**: Mit genug Hinweisen bricht man die Realität auf und wechselt
   in die nächste Schicht.
3. **Tarnung / Verdacht**: In manchen Realitäten als Kreatur getarnt. Die
   Verdachtsanzeige steigt durch Auffallen (rennen, kämpfen, Realitätsblick in
   Sichtweite). Ist sie voll, wird man enttarnt. Gegner haben einen versteckten
   Zustand („sie ahnen etwas“), den man nur per Realitätsblick sieht. Sie dürfen
   nicht merken, dass der Spieler es weiß.
4. **Vergessen / Verankerung**: Je länger man in einer Realität bleibt, desto
   höher die Verankerung. Ist sie zu hoch, verblasst das HUD, der Begleiter wird
   leiser und die Wahrnehmung verzerrt sich. Ankerspiegel senken den Wert.
5. **Verbündete herbeirufen**: Rafa und Adam nach Befreiung bzw. Beitritt an
   bestimmten Orten und vor Bosskämpfen, mit eigener Begleiter-KI.

## 6. Realitäten (Level)
1. **Der Konzernturm** (Tutorial): sterile Bürowelt, Kampf lernen. Am Ende ist der
   Turm selbst eine Illusion. Erste Begegnung mit Adam.
2. **Das Gehege der Schweine**: grausame Welt mit monströsen Schweinewesen, die
   Menschen fressen. Stealth/Tarnung mit Verdachtsanzeige. Boss: **„Die Mastmutter“**.
3. **Die Spiegelstadt**: Realitäten in Realitäten, Türen führen in veränderte
   Kopien desselben Ortes. Rafas Geschichte spielt eine große Rolle.
4. **Finale: Der Coup**: mehrstufiger Plan gegen den obersten Konzernboss. Der
   Verräter kopiert das Gesicht des Bosses, Adam erschafft damit eine Illusion,
   und der Boss glaubt, er habe die Verschwörer erwischt. Twist: Er steckt längst
   in einer Illusion, ermöglicht durch den Verrat seines engsten Vertrauten. Jede
   Figur hat eine Rolle. Der Bosskampf wechselt zwischen Realitätsschichten.

## 7. Steuerung (Input-Map-Aktionen)
| Aktion | Tastatur/Maus | Gamepad (Xbox-Layout) |
|---|---|---|
| `move_*` | WASD | linker Stick |
| `look_*` | Maus | rechter Stick |
| `sprint` | Shift (halten) | L3 (halten) |
| `dodge` | Leertaste | B |
| `attack_light` | Linksklick | RB |
| `attack_heavy` | Shift + Linksklick (im Code) | RT |
| `block` | Rechtsklick | LB |
| `lock_on` | Mittelklick / Tab | R3 |
| `reality_sight` | Q | Y |
| `interact` | E | A |
| `heal` | R | X |
| `call_ally` | F | Steuerkreuz hoch |
| `menu` | Esc | Start |

## 8. Roadmap
Status: ⬜ offen · 🟨 in Arbeit · ✅ fertig

- ✅ **M1**: Spieler-Controller & Kampf-Grundlagen: Projekt, Input Map, Spielfigur
  mit Third-Person-Kamera, Bewegung relativ zur Kamera, Sprint, Ausweichrolle mit
  I-Frames, leichter (und schwerer) Angriff mit Hitbox, Ausdauer mit Regeneration,
  Figur als Daten-Resource, HUD (Leben/Ausdauer/Fokus), Testarena mit Trainingspuppe.
- ⬜ **M2**: Gegner-KI mit State Machine, Lock-on, Treffer-Feedback, Tod/Respawn,
  Währung verlieren und zurückholen.
- ⬜ **M3**: Ankerspiegel, Speichern/Laden, Heiltränke, Inventar & Ausrüstung, Level-Up.
- ⬜ **M4**: Charakterauswahl (Aurel/Tahirou), Fähigkeitenbäume, Progressionssystem
  (Story + Level-Ups).
- ⬜ **M5**: Realitätsblick, Realitätsriss, Verankerung.
- ⬜ **M6**: Tutorial-Level „Konzernturm“ komplett, erster Boss, Adam.
- ⬜ **M7**: Tarnung/Verdacht, „Gehege der Schweine“, Boss „Mastmutter“.
- ⬜ **M8**: Verbündeten-System (Rafa & Adam herbeirufen), Dialogsystem.
- ⬜ **M9**: Spiegelstadt, Rafas Geschichte.
- ⬜ **M10**: Finale „Der Coup“, Hauptmenü, Sound, Feinschliff.

## 9. Offene Entscheidungen (Vorschläge, vom Nutzer NOCH NICHT bestätigt)
Nicht umsetzen, bevor der Nutzer zugestimmt hat. Bis dahin haben Aurel und Tahirou
in ihren `.tres` dieselben Grundwerte und unterscheiden sich nur in Name und Farbe.

1. **Tahirous Gelassenheit**: Ressource „Ruhe“. Hohe Ruhe = Widerstand gegen
   Verankerung, Illusionen länger durchschauen, präzisere Treffer (perfekte Konter,
   kurze Zeitlupe). Hektik (Knöpfe hämmern, unnötiges Ausweichen, viele Treffer)
   senkt sie. Anfangs passive Gleichgültigkeit, später bewusste Meisterschaft.
   Kiffen nur als Charakterzug in Dialogen und Auftreten, **nicht** als Buff
   (Altersfreigabe, Stärke soll aus ihm selbst kommen). Gleiches gilt für Aurels
   Zigarette: Ritual, kein Buff.
2. **Kampfstile/Fähigkeitenbäume**:
   - Aurel: aggressiv, schnell, Risiko/Belohnung. Ressource „Ehrgeiz“ (wächst durch
     Combos). Äste: Insider (Konzerntechnik hacken/übernehmen), Aufstieg (Combos,
     Kraft), Glut (Feuer/Funken).
   - Tahirou: ruhig, abwartend, präzise. Ressource „Ruhe“. Äste: Klarheit
     (Illusionen/Schwachstellen sehen), Konter (Paraden, Gegenangriffe),
     Fluss (Bewegung, Ausweichen).
3. **Rafa**: Empfehlung: Er ist kontrolliert und muss befreit werden (emotionaler
   Mini-Boss-Kampf, Moral wehrt sich sichtbar, Befreiung schaltet das
   Verbündeten-System frei).
4. **Spieltitel**: noch offen (Arbeitstitel „Spiegelrealitäten“).

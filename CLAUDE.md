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
- **Hauptszene:** `res://scenes/levels/santo_santiago.tscn` (Santo Santiago). Die
  Testarena (`test_arena.tscn`) bleibt für Tests und zum Ausprobieren.

### Prüfen (vor jedem „fertig“)
```bash
godot --headless --path game --import          # Assets/Klassen importieren
godot --headless --path game --quit            # Projekt laden, Skriptfehler zeigen
godot --headless --path game res://tests/smoke_test.tscn  # Logik-Rauchtest (Exit 0 = ok)
godot --headless --path game res://tests/city_test.tscn   # Stadt-Test (Exit 0 = ok)
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
scenes/      player/, enemies/, npcs/, levels/, ui/, world/  (.tscn)
scripts/     player/ (+ states/), enemies/ (+ states/), npcs/, missions/, skills/,
             combat/, components/, items/, realms/, ui/, systems/, world/,
             characters/, state_machine/
assets/      models/, materials/, audio/
resources/   characters/, attacks/, enemies/, items/, missions/, skills/, world/ (.tres)
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
- **Hitbox/Hurtbox** haben ein `team` (&"player"/&"enemy"); gleiches Team trifft
  sich nicht. `Hurtbox.receive_hit()` liefert ein `Result` (IGNORED, HIT, BLOCKED,
  PARRIED); Blocken/Parieren entscheidet `hurtbox.hit_filter` des Besitzers.
- **Anvisierbar** ist alles in der Gruppe `lock_on_targets` mit `is_targetable()`
  und `get_lock_on_point()`. Gegner sind in der Gruppe `enemies` und haben
  `reset_enemy()` (wird nach dem Tod der Spielfigur aufgerufen).
- **Interaktion (E)**: Alles, womit man etwas tun kann, erbt von `Interactable`
  (Ebene 6) und überschreibt `interact(player)`. `InteractionDetector` am Spieler
  wählt das nächste. Ankerspiegel = `AnchorMirror` (Rasten, Wiederbelebungsort).
- **Menüs** erben von `GameMenu` (CanvasLayer, läuft auch pausiert). Öffnen erhöht
  `GameState.open_menu_count`: Das pausiert das Spiel und gibt die Maus frei.
  Esc öffnet das Pausenmenü; offene Menüs schließen sich selbst mit Esc.
- **Gegenstände**: `ItemData` (.tres in `resources/items/`, Art CONSUMABLE oder
  PERMANENT) und Eintrag in `ItemDatabase.PATHS`. Besitz in `GameState.inventory`.
  Permanente Artefakte wirken, solange man sie besitzt. Fundorte (`ItemPickup`)
  brauchen eine eindeutige `pickup_id`.
- **State-Namen**: Knotenname in snake_case („UseItem“ → &"use_item").
- **Menü-Tests**: Menüs hören auf `_unhandled_input`; im Rauchtest dafür
  `_send_action()` statt `_tap()` benutzen.
- **Speichern**: Alles, was ein Neustart überleben soll, gehört in `GameState` und
  in dessen `to_dict()`/`from_dict()`/`reset()`. Geladen wird in
  `test_arena.gd::_enter_tree()`, also vor allen `_ready()`. Der Rauchtest nutzt
  einen eigenen Spielstand (`user://smoke_test_save.json`).
- **Moral**: `GameState.moral.record(id, tugend, wert, text)`; jede Tat-ID zählt
  einmal. Tugenden siehe `MoralMemory.VIRTUES`.
- **NPCs** erben von `NPC` (`scenes/npcs/npc.tscn`, Skript im Inspector tauschen)
  und überschreiben `talk(player, dialogue)` und `_npc_physics(delta)`.
  Gespräche: `var wahl := await dialogue.ask(name, text, antworten)`; das
  Fenster schließt der NPC-Basiscode am Ende selbst.
- **Missionen**: `MissionData` (.tres in `resources/missions/`) + Eintrag in
  `MissionDatabase.PATHS`. Stand in `GameState.mission_states`;
  `start_mission()`/`complete_mission()` geben Belohnung und tragen die Tat
  (falls `moral_virtue` gesetzt) ins Moral-Gedächtnis ein. HUD zeigt offene Missionen.
- **NPC-Schaden**: NPCs haben eine Hurtbox (Team &"neutral"). Nur Treffer der
  Spielfigur zählen fürs Moral-Gedächtnis (Verletzen −3 Barmherzigkeit, Töten −10
  Schwache schützen, je NPC einmal). Tote stehen in `GameState.dead_npcs`.
- **Fähigkeiten**: `SkillTreeData` (.tres in `resources/skills/`, in
  `CharacterData.skill_tree`) mit `SkillData`-Knoten (Ast, Kosten, Voraussetzungen,
  optional `story_flag`). Punkte: 1 pro Level-Up. Wirkung im Code über
  `GameState.has_skill(id)`. Story-Fortschritt: `GameState.set_story_flag(flag)`.
- **Eigene Ressource je Figur**: `CharacterData.special_resource` (&"ambition" =
  `AmbitionComponent`, &"ravens" = `RavenComponent`). Der Player erzeugt die Komponente in
  `_setup_special_resource()`; HUD zeigt einen vierten Balken.
- **Schaden je Ziel**: `hitbox.damage_modifier` (Player: Kombo, Funken,
  Schwachstellen). Gegner haben `EnemyData.faction` (z. B. &"corporate").
- **Karte**: Orte bekommen einen `MapMarker` als Kind (Art: Händler, Service,
  Konzernturm, Kaserne, Ankerspiegel, Gotteshäuser, Mission …). Grundriss liefert
  ein `MapData`-Knoten im Level (`add_rect()`). `MapView` zeichnet Minimap (HUD,
  dreht mit der Kamera) und große Karte (`WorldMapMenu`, Taste M).
- **Gezeichneter Look**: Levels rufen `ToonStyle.apply_to_tree(self)` im `_ready()`
  auf; neue Materialien im Code mit `ToonStyle.make(farbe)`.
- **Keine `static var` in Szenen-Skripten**, die mit anderen Skripten über Kreuz
  verweisen (führt in Godot zu Speicherlecks beim Beenden). Schalter für Tests
  gehören in `GameState` (z. B. `ask_character_on_new_game`).
- **Levels** erben von `Level` (`scripts/realms/level.gd`) und haben die Kinder
  `Player` und `GameUI` (`scenes/ui/game_ui.tscn` = HUD + alle Menüs).
- **Stadt**: `CityGenerator` baut aus einem `CityLayout` (.tres in
  `resources/world/`, Bezirke als `CityDistrict`) Böden, Straßen, Häuser, Ruinen,
  Wahrzeichen, Ranken und Kartenflächen. Gleicher `seed` = gleiche Stadt. Inhalte
  (NPCs, Gegner, Spiegel) stehen als normale Knoten in der Level-Szene.
- **Commits nur, wenn beide Tests grün sind.**
- **Platzierung in der Stadt**: Figuren, Spiegel und Gegenstände auf Straßen und
  Plätze stellen; der Stadt-Test prüft, dass nichts in einem Haus steckt.
- Beim Erzeugen von Knoten mit Kollision **erst Position setzen, dann
  `add_child()`**, sonst steht die Kollision kurz im Weltmittelpunkt.
- **Hitstop** über `HitStop.apply(sekunden)`, **Kamerawackeln** über
  `EventBus.camera_shake_requested`. Im Rauchtest ist `HitStop.enabled = false`.
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
| 6 | 32 | Interaktion | Interactables (Ankerspiegel, Gegenstände, NPCs) |
| 7 | 64 | NPC | Körper von NPCs |

### Konventionen
- Dateien und Ordner `snake_case`, Klassen `PascalCase` mit `class_name`.
- Bezeichner im Code auf Englisch, **Kommentare und Spieltexte auf Deutsch**.
- Signale in Vergangenheitsform (`died`, `hit_received`, `value_changed`).
- Keine geschützten Namen, Figuren oder Assets anderer Spiele übernehmen.
- **Schreibweise der Namen genau so:** **Tahirou** (nie „Tahiro“), Aurel, Rafael
  („Rafa“), Adam, Daniel, Caspar.
- Commits klein, Nachricht beschreibt den funktionierenden Schritt.
- `.uid`-Dateien, die Godot neben Skripten anlegt, **mit committen** (Godot nutzt
  sie, um Dateien auch nach Umbenennen wiederzufinden). `.godot/` nie committen.
- Neue Mechaniken bekommen nach Möglichkeit eine Prüfung im Rauchtest
  (`game/tests/smoke_test.gd`). Simulierte Tasten 2 Physik-Frames halten.

---

## 2. Genre, Stil & Gefühl

**Open-World**-Third-Person-Action-RPG: frei herumlaufen, Missionen machen, leveln.
Kampf inspiriert von Soulslikes (nur Inspiration):
- Ausdauerbasierter Kampf: leichter/schwerer Angriff, Ausweichrolle mit
  Unverwundbarkeitsfenstern (I-Frames), Blocken/Parieren, Lock-on,
  Treffer-Feedback (Hitstop, Kamerawackeln, Rückstoß).
- Leben, Ausdauer, Fokus (Mana) als Balken.
- **Leben regeneriert** nach 10 s ohne Schaden um 20 pro Sekunde (in Schritten).
  Heiltränke sind für schnelles Heilen im Kampf und zum Heilen von NPCs.
- **Springen** (Leertaste); Ausweichen liegt auf Strg.
- **Ankerspiegel** (Rastpunkte): heilen, speichern, Gegner respawnen, Level-Up.
  (Heiltränke werden dort **nicht** aufgefüllt.)
- **Blut ist sichtbar.** Die Altersfreigabe spielt keine Rolle.
- **Heiltränke** findet man in der Welt oder kauft sie mit **Geld**.
- **Zwei Währungen**: **Erinnerungen** (zum Leveln, gehen beim Tod verloren) und
  **Geld** (zum Kaufen, bleibt beim Tod erhalten). Caspar verleiht Geld.
- Beim Tod verliert man die Währung **„Erinnerungen“**. Man kann sie an der
  Todesstelle zurückholen (auf Minimap und Karte markiert). Stirbt man vorher
  erneut, sind sie weg.
- Große Karte, Inventar und alle Menüs **halten die Zeit an**.
- Level-Up mit Attributen, Waffen mit Skalierung, Ausrüstung.
- Harte, aber faire Gegner, Bosse mit mehreren Phasen.

**Stil:** Mischung aus **japanischem**, **mongolischem** und **Cyberpunk**-Stil in
einem **ernsthaften, animierten Look**: stilisiert und gezeichnet wirkend
(Cel-Shading, weiche Farbflächen, klare Silhouetten), wie moderne
Fantasy-Abenteuerspiele. **Nicht albern oder witzig-cartoonig.** Die Stimmung
darf trotzdem düster und rätselhaft sein. **Vegetation:** mystische Pflanzen,
Bäume und Ranken, die in Symbiose mit der futuristischen Welt leben.

## 3. Welt & Story

Dystopische Welt, beherrscht von Konzernen. Sie besitzen die Technik, Menschen in
**Spiegelrealitäten** zu sperren: Illusionswelten, in denen das Opfer nicht merkt,
dass es gefangen ist. Jeder Konzern kontrolliert eigene **Helden** als Vollstrecker.

Eine Gruppe von Freunden will nach oben und gerät selbst in die Spiegelrealitäten.
In der gespielten Hauptfigur steckt der **Begleiter**, eine Helfer-Illusion, die
Hinweise gibt und lehrt, hinter die Realität zu sehen.

### Drei Ebenen
1. **Die normale Welt**: die Open World mit Karte, Städten, NPCs und Missionen.
2. **Die Geisterwelt**: eine ganz eigene Welt voller Geister und anderer Wesen,
   getrennt von den Spiegelrealitäten. Hier lebt Rafa. Man kommt nur auf zwei
   Wegen hinein:
   - **Einladung**: Geister erscheinen in der normalen Welt und **lassen die Zeit
     stehen**. Nimmt man die Einladung an, holen sie einen ohne Probleme hinüber.
   - **Ritual**: in bestimmten **Bergtempeln**. Der Weg dorthin ist immer sehr
     schwer, und man braucht bestimmte Gegenstände, die man im Lauf des Spiels
     gesammelt haben muss.
3. **Die Spiegelrealitäten**: die Illusionswelten der Konzerne (siehe unten und
   Abschnitt 6).

### Karte, Regionen und Epochen
- Eine **Weltkarte** mit verschiedenen **Ländern und Regionen**, in denen
  **unterschiedliche Zeiten** herrschen, z. B. Mittelalter, Zukunft, Gegenwart,
  Altes Ägypten.
- Eine **Hauptstadt** im **Cyberpunk-Stil**: **Santo Santiago**.
  - Ein **großer Marktplatz**, dazu an vielen Orten **Services** (Händler, Heiler …).
  - **Bezirke, die sich stark unterscheiden** nach den Menschen, die dort leben:
    ein **christliches**, ein **muslimisches**, ein **jüdisches** und ein
    **atheistisches Viertel**, jeweils mit eigenem Haus (Kirche, Moschee,
    Synagoge; im atheistischen Viertel siehe Offene Entscheidungen).
    Respektvoll: Unterschiede in Architektur und Alltag, nie als Klischee.
  - **Klar getrennt in Arm und Reich**: viele Hochhäuser und Wolkenkratzer bei
    den Reichen, einfache, heruntergekommene Häuser und Ruinen bei den Armen.
  - **Überall Ranken und leuchtende Pflanzen** an den futuristischen Gebäuden.
  - **Minimap** oben links (zeigt Händler, Konzern-Wolkenkratzer, Kasernen,
    Ankerspiegel, Gotteshäuser, Services). Mit **M** groß aufklappen.
- **NPCs** laufen herum. Es gibt auch Wesen, denen man Schaden zufügen kann.

### Geister-Bindung
Geister können sich mit Figuren **verbinden**. Dann kann die Figur sie
**herbeirufen**. Beispiel: Tahirous Raben.

### Spiritueller Druck
Spirituelle Wesen strahlen **spirituellen Druck** aus. Man hält ihn nur aus, wenn
man seine **Spiritualität** hoch genug gelevelt hat. Rafa hat den stärksten Druck
von allen. Menschen mit schlechter spiritueller Kompatibilität halten ihn nicht aus.

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
  - **Kampfstil**: aggressiv, schnell, Risiko/Belohnung. Eigene Ressource
    **„Ehrgeiz“** (wächst durch Treffer und Kombos, sinkt, wenn er nicht angreift).
    Fähigkeitenbaum mit drei Ästen: **Insider** (Konzerntechnik hacken/
    übernehmen), **Aufstieg** (Kombos, Kraft), **Glut** (Feuer/Funken).
- **Tahirou** (Spitzname **„Twin“**): halb Latino, halb Afrikaner, Muslim. Entspannter Kiffer, den am
  Anfang wenig aus der Ruhe bringt, wenig Ehrgeiz. Entwickelt sich weiter, eignet
  sich immer mehr Fähigkeiten an und wird ebenfalls sehr, sehr stark.
  - **Die Raben**: Tahirou lebt in **Symbiose mit Raben aus der Geisterwelt**. In
    seinem Clan ist das seit Generationen so. Er kann sie herbeirufen. Gerät er
    in brenzlige Situationen, **sprechen die alten, weisen Raben zu ihm** und
    geben ihm Ratschläge. Die Raben sind **seine eigene Ressource** (nur Tahirou).
  - **Kampfstil**: **präzise und ruhig, aber relativ brutal** (mit Blut).
  - Gelassenheit ist **keine** eigene Ressource.
  - **Rabenbund** (Ressource 0–100): füllt sich durch präzises Spiel (perfekte
    Parade, Treffer auf wehrlose Gegner, eine Weile kämpfen ohne getroffen zu
    werden). **F** ruft ab halbem Balken einen Rabenschwarm auf den Gegner: unterbricht
    ihn und markiert eine Schwachstelle (nächster Treffer macht doppelten Schaden).
  - **Gaben der Ahnen** (gratis, nicht zu oft, keine Ratschläge mit Offensichtlichem):
    In brenzligen Lagen leihen die alten Raben ihm kurz eine Fähigkeit:
    **Federkleid** (wenig Leben: halber Schaden für 8 s, +15 Leben),
    **Rabenauge** (Gegner holt aus: Zeitlupe), **Flügelschlag** (umzingelt:
    Gegner ringsum zögern), **Zweiter Atem** (Ausdauer leer: sofort voll).
  - Fähigkeitenbaum: **Rabenbund** (Raben stärker), **Vollstrecker** (Hinrichtungen
    auf wehrlose/parierte Gegner, Furcht), **Stille** (Parieren, Zeitlupe,
    Schwachstellen).

### Wichtige Verbündete
- **Rafael („Rafa“)**: Latino, Christ. Held wie ein göttlich gesandter Engel:
  starke Moral, gewaltige Kraft, strahlende Erscheinung.
  - **Das mächtigste Wesen im ganzen Spiel**, mächtiger als jeder Konzern,
    Held oder Boss.
  - **Unabhängig**: Er hält sich aus den Konzernen und ihren Machtkämpfen heraus.
    Er lebt in der **Geisterwelt** (siehe Abschnitt 3).
  - **Herbeirufen ist extrem schwer und gefährlich**, weil Rafa seine Ruhe haben
    will, nicht gestört werden möchte und so mächtig ist.
  - **Die Prüfung**: Rafa sieht alles, was man im Spiel bisher getan hat und wie
    man sich verhalten hat. Er urteilt nach der **Moral des Christentums**,
    aber **über Taten, nicht über den Glauben**: Figuren mit anderem Glauben
    (z. B. Tahirou, Adam) werden nicht anders bewertet. Rafa predigt nicht. Dann
    stellt er **drei Fragen**, die man nur wahrheitsgemäß beantworten kann.
    Daraus ergibt sich, ob man bestanden hat.
    - Die Fragen **beziehen sich auf das, was man mit der gespielten Figur
      getan hat**, und passen sich der Figur an (Aurel und Tahirou bekommen
      andere Fragen).
    - Weil Rafa alles gesehen hat, weiß er, was stimmt. **Unwahre Antworten
      sind ausgegraut.**
  - **Nicht bestanden → Kampf gegen Rafa.** Mit körperlicher Kraft ist er
    **nicht zu besiegen**. Die **einzige** Möglichkeit: den Kampf so lange
    aushalten, bis man ihn **manipuliert** hat. Wer verliert, wird am **letzten
    Checkpoint** wiederbelebt.
  - **Nach dem Kampf** hört er sich die Bitte an und entscheidet, ob er hilft.
    Er hilft **nur, wenn die Bitte seiner Moral entspricht**. Er ist also kein
    Verbündeter, den man beliebig einsetzen kann.
  - **Wie er hilft**: Er setzt seine **Geisterkräfte** ein, allen voran seinen
    spirituellen Druck. Beispiel: In Kriegsgebieten rufen ihn manche. Er tötet
    die Angreifer sofort, bleibt danach aber eine Weile, bevor er verschwinden
    kann, und richtet großen Schaden an. Seine Hilfe hat also Folgen.
  - **Daniel** ist der Einzige, der ihn beruhigen kann.
- **Adam**: Araber, Muslim, trägt eine Galabiya. Schlitzohr und Genie. Bewegt sich
  mühelos durch Spiegelrealitäten und kann selbst Realitäten erschaffen. Gibt
  Hinweise, öffnet Abkürzungen, erschafft im Finale die Illusion für den
  Konzernboss. Nie ganz durchschaubar, aber am Ende auf der Seite der Gruppe.

- **Daniel**: Rafas Bruder. Kann **Holz bändigen** (Bäume, Wurzeln und Ranken
  wachsen lassen und formen). Eher eine **Hintergrundfigur**, aber der
  **Einzige, der Rafa beruhigen kann**.

### Weitere Figuren
- **Der Begleiter**: Helfer-Illusion im Kopf der gewählten Figur, kurze Textzeilen.
- **Der Verräter**: rechte Hand des Konzernbosses, heimlicher Helfer der Gruppe.
  Kopiert im Finale das Gesicht des Bosses für Adams Illusion.
- **Die Konzernhelden**: kontrollierte Vollstrecker, Mini-Bosse.
- **Der Konzernboss**: Endgegner, Meister der Illusionen.
- **Caspar**: Geldverleiher. Gibt Kredite, man kann sich bei ihm verschulden.
  Zahlt man nicht zurück, schickt er immer wieder **Assassinen**, und je länger
  die Schulden offen sind, desto stärker werden sie.
  - **Aussehen**: mindestens ein **Goldzahn**, eine **große Nase**.
  - **Charakter**: geschäftstüchtig, berechnend, freundlich, solange man zahlt,
    gnadenlos, wenn nicht.
  - **Religion**: keine bestimmte (nicht jüdisch, damit er kein antisemitisches
    Klischee bedient).

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
5. **Verbündete** lassen sich **nicht herbeirufen** (kein Erscheinen auf
   Knopfdruck). Sie helfen auf anderen Wegen: durch die Story, an bestimmten Orten,
   in Missionen. Rafa bittet man um Hilfe (siehe 6). Einzige Ausnahme sind
   gebundene Geister wie Tahirous Raben (Taste F).
6. **Rafa beschwören**: Ritual oder Einladung → Prüfung (Rückblick auf das eigene
   Verhalten + drei Fragen, nur wahre Antworten möglich) → bestanden: Bitte
   vortragen / nicht bestanden: Kampf, danach Bitte vortragen → Rafa entscheidet
   nach seiner Moral, ob er hilft.
7. **Moral-Gedächtnis**: Das Spiel misst von Anfang an, wie gut oder schlecht man
   als Mensch war. Gute Taten steigern den Wert, z. B. **einer Oma über die Straße
   helfen** oder **Kranken Heilung geben**. Bewertet nach christlichen Werten:
   Nächstenliebe, Barmherzigkeit, Ehrlichkeit, Vergebung, Demut, Schwache
   schützen. Gegenteil: Grausamkeit, Gier, Rache an Wehrlosen. Für den Spieler
   unsichtbar. Grundlage für Rafas Prüfung.
8. **Stats & Leveln**: verschiedene Werte, die man einzeln levelt.
   - **Körper** (vorläufig): **Stärke** (Schaden), **Schnelligkeit** (Tempo),
     **Ausdauer** (Ausdauerbalken), **Widerstand** (Leben). Levelt man, indem
     man **Erinnerungen am Ankerspiegel ausgibt**. Jede Stufe kostet mehr.
   - **Geist** (vorläufig): **Fokus** (Fokusbalken, levelt wie Körper) und
     **Spiritualität**. Spiritualität levelt man **nur** durch **Beten** in
     Tempeln, Kirchen, Moscheen und Synagogen und durch bestimmte Missionen. Nötig, um
     spirituellen Druck auszuhalten.
9. **Artefakte**: verbessern eine bestimmte Fähigkeit. Zwei Arten:
   - **Verbrauchbar**: wirken einmal und sind dann weg, wie Tränke.
   - **Dauerhaft**: wirken für immer.
10. **Missionen**: Haupt- und Nebenmissionen in der Open World, auch kleine
    Hilfe-Missionen für die Moral.
11. **Schulden bei Caspar**: Kredit aufnehmen, Schulden wachsen, Assassinen jagen
    einen, solange man nicht zurückzahlt (sie werden mit der Zeit stärker).

## 6. Spiegelrealitäten (Story-Level)
Die Spiegelrealitäten sind die dritte Ebene. Man betritt sie von der Open World
aus. (Wie genau, siehe Offene Entscheidungen.)
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
| `jump` | Leertaste | A |
| `dodge` | Strg (still stehen = Rückwärtsschritt) | B |
| `attack_light` | Linksklick | RB |
| `attack_heavy` | Shift + Linksklick (im Code) | RT |
| `block` | Rechtsklick | LB |
| `lock_on` | Mittelklick / Tab | R3 |
| `reality_sight` | Q | Y |
| `interact` | E | X |
| `heal` | R | Steuerkreuz runter |
| `call_spirit` | F (Tahirous Raben) | Steuerkreuz hoch |
| `inventory` | I | Back/View |
| `skills` | K | Steuerkreuz links |
| `map` | M (Karte groß/klein) | Steuerkreuz rechts |
| `menu` | Esc | Start |

## 8. Roadmap
Status: ⬜ offen · 🟨 in Arbeit · ✅ fertig

Open World nicht auf einmal, sondern erst eine Region komplett, dann erweitern.

- ✅ **M1**: Spieler-Controller & Kampf-Grundlagen: Projekt, Input Map, Spielfigur
  mit Third-Person-Kamera, Bewegung relativ zur Kamera, Sprint, Ausweichrolle mit
  I-Frames, leichter und schwerer Angriff mit Hitbox, Ausdauer mit Regeneration,
  Figur als Daten-Resource, HUD (Leben/Ausdauer/Fokus), Testarena mit Trainingspuppe.
- ✅ **M2**: Gegner-KI mit State Machine (Konzernwache: warten, verfolgen,
  angekündigter Angriff, taumeln, zurückkehren, tot), Lock-on, Treffer-Feedback
  (Hitstop, Kamerawackeln, Rückstoß), Blocken & Parieren, Tod & Respawn am
  Checkpoint, Erinnerungen verlieren und zurückholen.
- ✅ **M3**: Stats & Level-Up (Erinnerungen am Ankerspiegel, Rast-Menü), Speichern/
  Laden (automatisch beim Rasten, Pausenmenü, „Neues Spiel“), Ankerspiegel,
  Interaktion (E), Pausenmenü, Heiltränke (finden, R), Artefakte (verbrauchbar/
  dauerhaft), Inventar (I), Moral-Gedächtnis (Grundgerüst). Kaufen erst in M4.
- ✅ **M4**: Geld, NPCs mit Gesprächen, Händler (Tränke kaufen), Missionssystem
  mit Anzeige, erste Hilfe-Missionen (alte Frau über die Straße, kranker Mann),
  NPCs verletzen/töten zählt fürs Moral-Gedächtnis (Tote bleiben tot, Missionen
  scheitern).
- ✅ **M5**: Charakterauswahl (Aurel/Tahirou), Fähigkeitenbäume (Punkte durch
  Level-Ups, jeweils letzter Knoten erst durch Story-Fortschritt), Aurels
  „Ehrgeiz“ + 9 Fähigkeiten, Tahirous Rabenbund (Schwarm auf F, Ratschläge) +
  9 Fähigkeiten, sichtbares Blut, Ausweichen in gedrückte Richtung.
- ✅ **M6**: Santo Santiago: gezeichneter Look (Toon-Shading + Umrisse),
  Stadt-Generator aus Daten (297 Häuser, Bezirke, Arm/Reich, Ranken, leuchtende
  Pflanzen), Marktplatz mit mystischem Baum, vier Viertel mit Kirche, Moschee,
  Synagoge, Haus der Stille, Konzernviertel mit Neon-Türmen und Kaserne, Senke mit
  Ruinen, Minimap + große Karte (M), Services (2 Händler, Heilerin), Missionen,
  Wachen, 3 Ankerspiegel, Fundstücke. Santo Santiago ist die Startszene.
- ⬜ **M7**: Spiegelrealitäten: Realitätsblick, Realitätsriss, Verankerung,
  „Konzernturm“, Adam.
- ⬜ **M8**: Geisterwelt: Einladung (Zeit steht still), Tempel/Kirchen/Moscheen
  und Gebet, spiritueller Druck, Rituale in Bergtempeln.
- ⬜ **M9**: Rafa (Prüfung, Kampf, Bitte), Daniel.
- ⬜ **M10**: Caspar & Schulden-Assassinen, weitere Missionen.
- ⬜ **M11+**: weitere Regionen/Epochen, „Gehege der Schweine“ (Mastmutter),
  Spiegelstadt.
- ⬜ **M12**: Finale „Der Coup“, Hauptmenü, Sound, Feinschliff.

## 9. Offene Entscheidungen (Vorschläge, vom Nutzer NOCH NICHT bestätigt)
Nicht umsetzen, bevor der Nutzer zugestimmt hat. Bis dahin haben Aurel und Tahirou
in ihren `.tres` dieselben Grundwerte und unterscheiden sich nur in Name und Farbe.

1. ~~Tahirous Raben~~ → **entschieden** (Abschnitt 4).
2. **Einzelne Fähigkeiten** (vorläufig): Die konkreten Knoten in den Bäumen hat
   Claude vorgeschlagen; der Nutzer kann sie ändern.
3. **Rafa und die Geisterwelt**: Moralwerte, Fragen, Kampf, Einladung, Ritual und
   Hilfe sind **entschieden** (Abschnitte 3 bis 5). Noch offen:
   - **Wie „manipuliert“ man Rafa im Kampf?** Vorschlag: Während man standhält,
     kann man ihn ansprechen. Die richtigen Worte (passend zu dem, was man über
     Rafa und Daniel herausgefunden hat) bringen ihn ins Zögern. Nach genug
     Zögern bricht er den Kampf ab.
   - **Welche Gegenstände braucht das Ritual?** Und wo liegen die Bergtempel?
   - **Rafas Geschichte**: Bleibt die Spiegelstadt sein Kapitel (Abschnitt 6)?
4. **Spieltitel**: noch offen (Arbeitstitel „Spiegelrealitäten“).
5. **Wie hängen die Ebenen zusammen?** Wie betritt man von der Open World aus
   eine Spiegelrealität? Wie hängt die Epochen-Karte mit Konzernen und
   Spiegelrealitäten zusammen (z. B. sind manche Epochen-Regionen selbst
   Illusionen)?
6. **Stats**: Die Liste (Abschnitt 5, Punkt 8) ist vorläufig. Der Nutzer hat
   nicht widersprochen, kann sie aber noch ändern.
8. **Santo Santiago, Aufteilung (Vorschlag, gebaut)**: Arm/Reich räumlich
   getrennt von den Glaubensvierteln, damit kein Glaube mit Armut verknüpft wird:
   Norden Konzernviertel (reich, Wolkenkratzer, Kaserne), Mitte Marktplatz mit
   den vier Vierteln (jeweils reichere und ärmere Straßen), Süden „Die Senke“
   (arm, Ruinen). **Atheistisches Viertel**: Statt eines Gotteshauses ein
   „Haus der Stille“ (Gemeinschaftshaus/Bibliothek)? Noch offen.
7. **Beträge (vorläufig)**: Konzernwache lässt 15 Geld fallen, Heiltrank kostet
   40 Geld beim Händler. Lässt sich in den .tres-Dateien ändern.

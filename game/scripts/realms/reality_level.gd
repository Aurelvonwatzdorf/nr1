class_name RealityLevel
extends Level
## Eine Spiegelrealität: eine Illusionswelt der Konzerne.
##
## Regeln (siehe CLAUDE.md, Abschnitt 5 und 6):
## - Mit dem Realitätsblick (Q) findet man Hinweise (`RealityClue`). Sind genug
##   gefunden, öffnet sich der Realitätsriss (`RealityRift`): Durch ihn bricht man
##   die Illusion und wacht in `exit_scene` auf. (Oder man erfüllt das Ziel der
##   Realität: Das Level ruft dann selbst `break_reality()` auf.)
## - Verankerung (0–100) steigt mit der Zeit. Ab der Hälfte verblasst das HUD,
##   der Begleiter wird leiser und das Bild verzerrt sich. Bei 100 geht der
##   Realitätsblick nicht mehr. Rasten am Ankerspiegel senkt sie auf 0.

@export var reality_id: StringName = &""
@export var reality_name: String = ""
@export var clues_needed: int = 3
## Wohin man nach dem Bruch kommt (leer = nur Signal, z. B. im Test).
@export_file("*.tscn") var exit_scene: String = ""
## Verankerung pro Sekunde (0.25 = nach knapp 7 Minuten ganz verankert).
@export var anchoring_per_second: float = 0.25
## Was der Begleiter beim Betreten sagt.
@export var intro_lines: Array[String] = []
## Dasselbe für Tahirou (leer = wie oben).
@export var intro_lines_tahirou: Array[String] = []

## Meldung, wenn man nach dem Bruch in `exit_scene` aufwacht.
@export var wake_message: String = "Du wachst auf. Die Illusion ist gebrochen."

var clues_found: int = 0
var anchoring: float = 0.0
var is_broken: bool = false


func _ready() -> void:
	super._ready()
	add_to_group(&"reality")
	GameState.reality_sight_blocked = false
	EventBus.anchor_mirror_rested.connect(_on_anchor_mirror_rested)
	if reality_name != "":
		hud.show_message.call_deferred(reality_name)
	_play_intro()


## Begleiter-Zeilen beim Betreten (Timer laufen nicht, solange ein Menü offen ist,
## z. B. die Charakterauswahl).
func _play_intro() -> void:
	for i in maxi(intro_lines.size(), intro_lines_tahirou.size()):
		get_tree().create_timer(2.0 + i * 5.0, false).timeout.connect(func() -> void:
			var lines := get_lines(intro_lines, intro_lines_tahirou)
			if i < lines.size():
				companion_say(lines[i]))


## Zeilen passend zur gespielten Figur.
static func get_lines(default_lines: Array[String], tahirou_lines: Array[String]) -> Array[String]:
	var data := GameState.selected_character
	if data and data.id == &"tahirou" and not tahirou_lines.is_empty():
		return tahirou_lines
	return default_lines


func _physics_process(delta: float) -> void:
	if is_broken or player.health.is_dead:
		return
	var before := anchoring
	anchoring = minf(anchoring + anchoring_per_second * delta, 100.0)
	if before < 50.0 and anchoring >= 50.0:
		companion_say("Alles hier fühlt sich so … normal an. Vergiss nicht, wer du bist.")
	if anchoring >= 100.0 and not GameState.reality_sight_blocked:
		GameState.reality_sight_blocked = true
		companion_say("…")
		EventBus.message_requested.emit("Du hast vergessen, dass dies eine Illusion ist.")


## 0 = klar, 1 = ganz verankert (für HUD und Bild-Effekt).
func get_fade() -> float:
	return clampf((anchoring - 50.0) / 50.0, 0.0, 1.0)


## Der Begleiter spricht. Je höher die Verankerung, desto leiser (blasser).
func companion_say(text: String) -> void:
	EventBus.companion_spoke.emit(text)


func add_clue(line: String) -> void:
	if is_broken:
		return
	clues_found += 1
	EventBus.reality_clue_found.emit(clues_found, clues_needed)
	if line != "":
		companion_say(line)
	if clues_found == clues_needed:
		companion_say("Da ist er. Der Riss. Diese Welt hält nicht mehr lange.")
		EventBus.reality_rift_opened.emit()


func is_rift_open() -> bool:
	return clues_found >= clues_needed


## Die Illusion bricht: kurzer weißer Blitz, dann wacht man in `exit_scene` auf.
func break_reality() -> void:
	if is_broken:
		return
	is_broken = true
	if reality_id != &"":
		GameState.set_story_flag(StringName("reality_%s_broken" % reality_id))
	GameState.reality_sight_blocked = false
	EventBus.camera_shake_requested.emit(0.8)
	EventBus.reality_broken.emit(reality_id)
	if exit_scene != "":
		GameState.clear_checkpoint()
		GameState.pending_message = wake_message
		# Speichern, damit man nach einem Neustart draußen weiterspielt.
		GameState.current_scene = exit_scene
		SaveSystem.save_game()
		await get_tree().create_timer(1.5).timeout
		get_tree().change_scene_to_file(exit_scene)


func _on_anchor_mirror_rested(_mirror: Node3D, _player: Player) -> void:
	if anchoring > 0.0:
		anchoring = 0.0
		GameState.reality_sight_blocked = false
		EventBus.message_requested.emit("Die Verankerung lässt nach. Du erinnerst dich wieder.")

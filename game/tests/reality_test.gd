extends Node
## Rauchtest für Spiegelrealitäten (Realitätsblick, Hinweise, Riss, Verankerung):
##   godot --headless --path game res://tests/reality_test.tscn

const REALITY := preload("res://scenes/levels/test_reality.tscn")

var _failures: int = 0


func _ready() -> void:
	HitStop.enabled = false
	SaveSystem.auto_load_enabled = false
	GameState.ask_character_on_new_game = false
	GameState.test_start_money = 0
	GameState.reset()
	_run.call_deferred()


func _run() -> void:
	var reality := REALITY.instantiate() as RealityLevel
	reality.exit_scene = ""
	add_child(reality)
	await _frames(5)
	var player: Player = reality.get_node("Player")
	var hud: HUD = reality.get_node("GameUI/HUD")
	_check(get_tree().get_first_node_in_group(&"reality") == reality, "Spiegelrealität ist aktiv")
	for i in 3:
		await get_tree().process_frame
	_check(hud.reality_label.visible and hud.reality_label.text.contains("Verankerung"), "HUD zeigt Verankerung und Hinweise")

	var said: Array[String] = []
	EventBus.companion_spoke.connect(func(text: String) -> void: said.append(text))

	# Hinweise: nur mit Realitätsblick
	var clues := reality.get_node("Clues").get_children()
	var rift: RealityRift = reality.get_node("Rift")
	var first := clues[0] as RealityClue
	_check(not first.visible and not first.can_interact(player), "Ohne Realitätsblick sind die Risse unsichtbar")
	_check(not rift.visible, "Der Realitätsriss ist noch zu")
	var ramp: Node3D = reality.get_node("HiddenRamp/Body")
	_check(ramp.to_global(Vector3(0, 0, -3.5)).y > 2.4 and ramp.to_global(Vector3(0, 0, 3.5)).y < 0.5, "Versteckte Rampe führt hoch zur Plattform")
	_check(player.start_reality_sight() and first.visible and first.can_interact(player), "Mit Realitätsblick: Risse sichtbar")
	_check(not (reality.get_node("FalseWall") as RealityLayerObject).is_present(), "Falsche Wand verschwindet im Realitätsblick")
	for node in clues:
		(node as RealityClue).interact(player)
	_check(reality.clues_found == 3 and not first.visible, "Drei Hinweise gefunden")
	_check(said.size() >= 3, "Der Begleiter kommentiert die Hinweise")
	await _frames(2)
	_check(rift.visible and rift.can_interact(player), "Genug Hinweise: Der Riss öffnet sich")

	# Verankerung
	reality.anchoring = 49.0
	reality.anchoring_per_second = 60.0
	await _frames(70)
	_check(reality.anchoring >= 100.0 and GameState.reality_sight_blocked, "Ganz verankert: Realitätsblick gesperrt")
	await _frames(400)
	player.focus.refill()
	_check(not player.start_reality_sight(), "Gesperrter Blick lässt sich nicht starten")
	_check(hud.health_bar.get_parent().self_modulate.a < 0.5, "HUD verblasst bei hoher Verankerung")
	reality.anchoring_per_second = 0.0
	var mirror: AnchorMirror = reality.get_node("AnchorMirror")
	mirror.rest(player)
	await _frames(2)
	_check(is_zero_approx(reality.anchoring) and not GameState.reality_sight_blocked, "Rasten am Ankerspiegel senkt die Verankerung")
	(reality.get_node("GameUI/RestMenu") as GameMenu).close()

	# Illusion brechen
	var broken: Array[StringName] = []
	EventBus.reality_broken.connect(func(id: StringName) -> void: broken.append(id))
	rift.interact(player)
	await _frames(2)
	_check(broken == [&"test"] and GameState.has_story_flag(&"reality_test_broken"), "Durch den Riss: Die Illusion bricht")

	print("")
	print("REALITÄTSTEST: %s" % ("BESTANDEN" if _failures == 0 else "%d FEHLER" % _failures))
	get_tree().quit(0 if _failures == 0 else 1)


func _frames(count: int) -> void:
	for i in count:
		await get_tree().physics_frame


func _check(condition: bool, description: String) -> void:
	print("%s %s" % ["[OK]  " if condition else "[FEHLER]", description])
	if not condition:
		_failures += 1

extends Node
## Rauchtest für Spiegelrealitäten (Realitätsblick, Hinweise, Riss, Verankerung):
##   godot --headless --path game res://tests/reality_test.tscn

const REALITY := preload("res://scenes/levels/test_reality.tscn")
const TOWER := preload("res://scenes/levels/corporate_tower.tscn")
const MIRROR_CITY := preload("res://scenes/levels/mirror_city_reality.tscn")
const SPIRIT_WORLD := preload("res://scenes/levels/spirit_world.tscn")

var _failures: int = 0


func _ready() -> void:
	HitStop.enabled = false
	SaveSystem.auto_load_enabled = false
	GameState.ask_character_on_new_game = false
	GameState.test_start_money = 0
	SaveSystem.save_path = "user://reality_test_save.json"
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

	reality.queue_free()
	await _frames(3)
	await _test_tower()
	await _test_mirror_city()
	await _test_spirit_world()

	print("")
	print("REALITÄTSTEST: %s" % ("BESTANDEN" if _failures == 0 else "%d FEHLER" % _failures))
	get_tree().quit(0 if _failures == 0 else 1)


## Der Konzernturm (Spielstart): Aufbau, Tutorial, Hinweise, Adam, Zusammenbruch.
func _test_tower() -> void:
	GameState.reset()
	var tower := TOWER.instantiate() as CorporateTower
	tower.exit_scene = ""
	add_child(tower)
	await _frames(5)
	var player: Player = tower.get_node("Player")
	_check(get_tree().get_first_node_in_group(&"reality") == tower and ProjectSettings.get_setting("application/run/main_scene") == "res://scenes/levels/corporate_tower.tscn",
		"Das Spiel beginnt im Konzernturm")
	_check(tower.get_node("Clues").get_child_count() == 3 and tower.get_node("Enemies").get_child_count() == 3, "Turm: 3 Risse, 3 Wachen")
	var adam: Adam = tower.get_node("NPCs/Adam")
	_check(not adam.visible, "Adam ist noch nicht da")
	# Nichts steckt in einer Wand.
	var space := tower.get_world_3d().direct_space_state
	var probe := CapsuleShape3D.new()
	probe.radius = 0.35
	probe.height = 1.6
	var blocked: Array[String] = []
	var spots: Array[Node3D] = [player, tower.get_node("AnchorMirror/SpawnPoint")]
	for group_name: String in ["NPCs", "Enemies", "Clues"]:
		for node in tower.get_node(group_name).get_children():
			spots.append(node as Node3D)
	for spot in spots:
		var query := PhysicsShapeQueryParameters3D.new()
		query.shape = probe
		query.transform = Transform3D(Basis.IDENTITY, spot.global_position + Vector3(0, 1.3, 0))
		query.collision_mask = PhysicsLayers.WORLD
		if not space.intersect_shape(query, 1).is_empty():
			blocked.append(String(spot.name))
	_check(blocked.is_empty(), "Figuren, Spiegel und Risse stehen frei %s" % [blocked])
	var ramp: Node3D = tower.get_node("HiddenRamp").get_child(0)
	_check(ramp.to_global(Vector3(4, 0, 0)).y > 2.6 and ramp.to_global(Vector3(-4, 0, 0)).y < 0.4, "Versteckte Rampe führt auf die Empore")
	var messages: Array[String] = []
	EventBus.message_requested.connect(func(text: String) -> void: messages.append(text))
	player.global_position = tower.get_node("TutorialZones/ZoneCombat").global_position - Vector3(0, 0.9, 0)
	await _frames(5)
	_check(messages.any(func(text: String) -> bool: return text.begins_with("Kampf:")), "Tutorial: Kampfsteuerung wird erklärt")
	player.global_position = Vector3(0.5, 0.1, 7)
	player.focus.refill()
	player.start_reality_sight()
	for node in tower.get_node("Clues").get_children():
		(node as RealityClue).interact(player)
	await _frames(40)
	_check(adam.visible and adam.has_appeared, "Riss offen: Adam taucht auf")
	(tower.get_node("Rift") as RealityRift).interact(player)
	await _frames(2)
	_check(GameState.has_story_flag(&"reality_corporate_tower_broken"), "Der Konzernturm bricht zusammen")
	await get_tree().create_timer(1.6).timeout
	tower.queue_free()
	await _frames(2)


## Gefangen auf dem Markt: Die Spiegelrealität ist eine Kopie des Marktes.
func _test_mirror_city() -> void:
	GameState.reset()
	GameState.return_scene = "res://scenes/levels/santo_santiago.tscn"
	GameState.return_transform = Transform3D(Basis.IDENTITY, Vector3(6, 0.1, 16))
	GameState.capture_district = &"market"
	var mirror := MIRROR_CITY.instantiate() as MirrorCityReality
	mirror.change_scene_on_break = false
	add_child(mirror)
	await _frames(5)
	var player: Player = mirror.get_node("Player")
	_check(mirror.reality_name == "Der Markt ohne Ende" and mirror.city.building_count > 300, "Gefangen auf dem Markt: Kopie der Stadt, „Der Markt ohne Ende“")
	_check(player.global_position.distance_to(Vector3(6, 0.1, 16)) < 1.0, "Man wacht genau am Fangort auf")
	var space := mirror.get_world_3d().direct_space_state
	var probe := CapsuleShape3D.new()
	probe.radius = 0.35
	probe.height = 1.6
	var blocked: Array[String] = []
	var spots: Array[Node3D] = [player, mirror.get_node("AnchorMirror/SpawnPoint"), mirror.get_node("Rift")]
	for group_name: String in ["NPCs", "Clues"]:
		for node in mirror.get_node(group_name).get_children():
			spots.append(node as Node3D)
	for spot in spots:
		var query := PhysicsShapeQueryParameters3D.new()
		query.shape = probe
		query.transform = Transform3D(Basis.IDENTITY, spot.global_position + Vector3(0, 1.3, 0))
		query.collision_mask = PhysicsLayers.WORLD
		if not space.intersect_shape(query, 1).is_empty():
			blocked.append(String(spot.name))
	_check(blocked.is_empty() and spots.size() == 8, "Risse, Riss, Spiegel und Schattengestalten stehen frei auf der Straße %s" % [blocked])
	var near := true
	for node in mirror.get_node("Clues").get_children():
		near = near and (node as Node3D).global_position.distance_to(player.global_position) < 70.0
	_check(near, "Die Risse liegen in der Nähe des Fangorts")
	player.focus.refill()
	player.start_reality_sight()
	for node in mirror.get_node("Clues").get_children():
		(node as RealityClue).interact(player)
	await _frames(2)
	mirror.break_reality()
	await _frames(2)
	_check(GameState.has_pending_spawn and GameState.pending_spawn.origin.is_equal_approx(Vector3(6, 0.1, 16)) and not GameState.is_captured,
		"Ausbruch: Man wacht dort auf, wo man gefangen wurde")
	GameState.has_pending_spawn = false
	await get_tree().create_timer(1.6).timeout
	mirror.queue_free()
	await _frames(2)


## Die Geisterwelt (nach der Einladung): Lichtung, Ältester, Tor zurück.
func _test_spirit_world() -> void:
	GameState.reset()
	GameState.return_scene = "res://scenes/levels/santo_santiago.tscn"
	GameState.return_transform = Transform3D(Basis.IDENTITY, Vector3(-149, 0.1, -8))
	var world := SPIRIT_WORLD.instantiate() as SpiritWorld
	world.change_scene_on_return = false
	add_child(world)
	await _frames(10)
	var player: Player = world.get_node("Player")
	_check(player.is_on_floor() and GameState.has_story_flag(&"visited_spirit_world"), "Geisterwelt: Man steht auf der Lichtung")
	_check(not GameState.time_stopped and get_tree().get_first_node_in_group(&"reality") == null, "Die Geisterwelt ist echt, keine Spiegelrealität")
	var dialogue := world.get_node("GameUI").find_child("DialogueBox", true, false) as DialogueBox
	if dialogue == null:
		dialogue = get_tree().get_first_node_in_group(&"dialogue_box") as DialogueBox
	var elder_talk := world.get_node("Glade/Elder/TalkArea") as Interactable
	elder_talk.interact(player)
	await get_tree().process_frame
	_check(dialogue.is_open and dialogue.speaker_label.text == "Der Älteste", "Der Älteste spricht")
	dialogue.choose(0)
	await get_tree().process_frame
	_check(not dialogue.is_open, "Gespräch endet")
	(world.get_node("Glade/ReturnGate/UseArea") as Interactable).interact(player)
	_check(GameState.has_pending_spawn and GameState.pending_spawn.origin.is_equal_approx(Vector3(-149, 0.1, -8)) and GameState.return_scene == "",
		"Tor zurück: Man kommt am Schrein heraus")
	GameState.has_pending_spawn = false
	GameState.pending_message = ""
	world.queue_free()
	await _frames(2)


func _frames(count: int) -> void:
	for i in count:
		await get_tree().physics_frame


func _check(condition: bool, description: String) -> void:
	print("%s %s" % ["[OK]  " if condition else "[FEHLER]", description])
	if not condition:
		_failures += 1

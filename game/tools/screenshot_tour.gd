extends Node
## Screenshot-Tour: lädt nacheinander feste Orte, wartet kurz und speichert je
## ein Bild nach nr1/screenshots/mac/ (am Mac, echte Grafik) bzw.
## nr1/screenshots/cloud/ (Cloud, einfacher Grafikmodus). Start über
## ./game/tools/screenshots.sh.
## Neue Orte: einfach unten in SHOTS eintragen (Name, Szene, Aufbau-Funktion).

const OUT_DIR := "../screenshots"
const WAIT_FRAMES := 120

## Name, Szene, Methode zum Einrichten (bekommt das Level).
const SHOTS: Array[Array] = [
	["01_konzernturm_buero", "res://scenes/levels/corporate_tower.tscn", &"_setup_default"],
	["02_konzernturm_realitaetsblick", "res://scenes/levels/corporate_tower.tscn", &"_setup_reality_sight"],
	["03_santo_santiago_markt", "res://scenes/levels/santo_santiago.tscn", &"_setup_default"],
	["04_schrein_der_alten_geister", "res://scenes/levels/santo_santiago.tscn", &"_setup_shrine"],
	["05_geisterwelt_lichtung", "res://scenes/levels/spirit_world.tscn", &"_setup_spirit_world"],
]

var _out_path: String = ""


func _ready() -> void:
	SaveSystem.auto_load_enabled = false
	GameState.ask_character_on_new_game = false
	HitStop.enabled = false
	var device := "mac" if OS.get_name() == "macOS" else "cloud"
	_out_path = ProjectSettings.globalize_path("res://").path_join(OUT_DIR).path_join(device).simplify_path()
	DirAccess.make_dir_recursive_absolute(_out_path)
	_run.call_deferred()


func _run() -> void:
	var only := OS.get_environment("SHOT")
	var done := 0
	for shot in SHOTS:
		var shot_name: String = shot[0]
		if only != "" and not shot_name.contains(only):
			continue
		GameState.reset()
		GameState.select_character(&"aurel")
		var level := (load(shot[1]) as PackedScene).instantiate() as Level
		add_child(level)
		await get_tree().process_frame
		call(shot[2], level)
		for i in WAIT_FRAMES:
			await get_tree().process_frame
		var image := get_viewport().get_texture().get_image()
		var file := _out_path.path_join(shot_name + ".png")
		image.save_png(file)
		print("Bild gespeichert: ", file)
		done += 1
		level.queue_free()
		for i in 5:
			await get_tree().process_frame
	print("SCREENSHOTS: %d Bilder in %s" % [done, _out_path])
	get_tree().quit()


func _setup_default(_level: Level) -> void:
	pass


func _setup_reality_sight(level: Level) -> void:
	await get_tree().create_timer(0.5).timeout
	level.player.focus.refill()
	level.player.start_reality_sight()


func _setup_shrine(level: Level) -> void:
	GameState.stats.spirituality = 3
	var shrine := level.get_node("SpiritPlaces/ShrineWest") as Node3D
	var invitation := shrine.get_node("Invitation") as SpiritInvitation
	invitation.change_scene_on_accept = false
	level.player.global_position = invitation.to_global(Vector3(0, 0.1, 11.0))
	level.player.reset_physics_interpolation()
	level.player.camera_rig.look_at_point(shrine.global_position + Vector3.UP * 2.0, -8.0)


func _setup_spirit_world(level: Level) -> void:
	level.player.camera_rig.look_at_point(Vector3(0, 3, -20), -8.0)

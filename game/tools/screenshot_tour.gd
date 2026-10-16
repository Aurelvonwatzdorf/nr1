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

## Kontinent: Name, Region (für Nebel), Ziel (x, z), Kamera-Versatz (x, Höhe über Boden, z).
const CONTINENT_VIEWS: Array[Array] = [
	["10_kontinent_uebersicht", &"", Vector2(0, -50), Vector3(0, 1500, 1100)],
	["11_kontinent_suedtor", &"santo_santiago", Vector2(0, 205), Vector3(10, 22, 115)],
	["12_narbe", &"narbe", Vector2(20, -560), Vector3(-150, 70, 160)],
	["13_kagero_bergtempel", &"kagero", Vector2(660, -640), Vector3(-130, 45, 150)],
	["14_ewige_steppe", &"steppe", Vector2(-630, -430), Vector3(60, 30, 110)],
	["15_grauwald", &"grauwald", Vector2(-560, 40), Vector3(110, 45, 130)],
	["16_nebelwald", &"nebelwald", Vector2(-280, 715), Vector3(-90, 35, -140)],
	["17_kemet", &"kemet", Vector2(90, 700), Vector3(170, 40, -160)],
	["18_neu_vallis", &"neu_vallis", Vector2(605, 230), Vector3(120, 45, 100)],
	["19_glaeserne_kueste", &"glaskueste", Vector2(835, -175), Vector3(-150, 50, 120)],
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
	if only == "" or only.contains("kontinent") or CONTINENT_VIEWS.any(func(view: Array) -> bool: return String(view[0]).contains(only)):
		done += await _continent_tour(only)
	print("SCREENSHOTS: %d Bilder in %s" % [done, _out_path])
	get_tree().quit()


## Kontinent einmal laden und von mehreren Kameras aus fotografieren.
func _continent_tour(only: String) -> int:
	GameState.reset()
	GameState.select_character(&"aurel")
	var world := (load("res://scenes/levels/continent.tscn") as PackedScene).instantiate() as ContinentWorld
	add_child(world)
	await get_tree().process_frame
	var gen := world.generator
	var environment := (world.get_node("WorldEnvironment") as WorldEnvironment).environment
	world.set_physics_process(false)
	var camera := Camera3D.new()
	camera.far = 4000.0
	camera.near = 1.0
	world.add_child(camera)
	camera.make_current()
	var done := 0
	for view in CONTINENT_VIEWS:
		var view_name: String = view[0]
		if only != "" and not only.contains("kontinent") and not view_name.contains(only):
			continue
		var target: Vector2 = view[2]
		var offset: Vector3 = view[3]
		var region := gen.get_region(view[1]) if view[1] != &"" else null
		environment.fog_enabled = region != null
		if region:
			environment.fog_light_color = region.fog_color
			environment.fog_density = region.fog_density
		var eye := Vector2(target.x + offset.x, target.y + offset.z)
		camera.global_position = Vector3(eye.x, gen.get_height(eye.x, eye.y) + offset.y, eye.y) if region else Vector3(eye.x, offset.y, eye.y)
		camera.look_at(gen.ground(target, 8.0))
		for i in 45:
			await get_tree().process_frame
		var file := _out_path.path_join(view_name + ".png")
		get_viewport().get_texture().get_image().save_png(file)
		print("Bild gespeichert: ", file)
		done += 1
	world.queue_free()
	for i in 5:
		await get_tree().process_frame
	return done


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

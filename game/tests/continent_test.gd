extends Node
## Test für den Kontinent (Regionen, Gelände, Wahrzeichen, Entdecken, Tore):
##   godot --headless --path game res://tests/continent_test.tscn

const CONTINENT := preload("res://scenes/levels/continent.tscn")

var _failures: int = 0


func _ready() -> void:
	HitStop.enabled = false
	SaveSystem.auto_load_enabled = false
	GameState.ask_character_on_new_game = false
	GameState.test_start_money = 0
	GameState.test_start_spirituality = 0
	SaveSystem.save_path = "user://continent_test_save.json"
	GameState.reset()
	GameState.select_character(&"aurel")
	_run.call_deferred()


func _run() -> void:
	var started := Time.get_ticks_msec()
	var world := CONTINENT.instantiate() as ContinentWorld
	add_child(world)
	var build_ms := Time.get_ticks_msec() - started
	var gen := world.generator
	var player := world.player
	print("Aufbau: %d ms, %d Meshes, %d Wahrzeichen" % [build_ms, gen.mesh_count, gen.landmarks.size()])
	_check(gen.layout.regions.size() >= 9, "Neun Regionen (%d)" % gen.layout.regions.size())
	_check(build_ms < 30000 and gen.mesh_count < 2500, "Aufbau in vertretbarer Zeit und Menge (%d ms, %d Meshes)" % [build_ms, gen.mesh_count])
	# Jede Region liegt an Land, gehört zu sich selbst und hat ihre Wahrzeichen.
	var all_land := true
	var own := true
	var built := true
	for region in gen.layout.regions:
		all_land = all_land and gen.get_height(region.center.x, region.center.y) > 0.5
		own = own and gen.region_at(region.center) == region
		built = built and gen.region_roots.has(region.id) and gen.region_roots[region.id].get_child_count() >= 2
	_check(all_land, "Alle Regionen liegen über dem Meer")
	_check(own, "Jede Regionsmitte gehört zu ihrer Region")
	_check(built, "Jede Region hat Wahrzeichen und einen Ankerspiegel")
	var planted := 0
	for id: StringName in gen.plant_counts:
		planted += gen.plant_counts[id]
	_check(planted > 1200, "Pflanzen und Felsen verteilt (%d)" % planted)
	var peak := gen.get_temple_peak()
	_check(gen.get_height(peak.x, peak.y) > 90.0, "Bergtempel liegt hoch oben (%.0f m)" % gen.get_height(peak.x, peak.y))
	_check(gen.get_height(0, 1060) < -2.0 and gen.get_height(1080, 0) < -2.0, "Rundherum Meer")
	var river := gen.layout.rivers[0]
	_check(gen.get_height(river[2].x, river[2].y) < 0.5, "Fluss in Kemet führt Wasser")
	# Straßen sind nicht zu steil (entlang des Weges gemessen, auch zum Bergtempel).
	var steepest := 0.0
	var steepest_at := Vector2.ZERO
	for road in gen.layout.roads:
		for i in road.size() - 1:
			var dir := (road[i + 1] - road[i]).normalized()
			var length := road[i].distance_to(road[i + 1])
			for k in int(length / 4.0):
				var p := road[i] + dir * (k * 4.0 + 2.0)
				if gen.get_height(p.x, p.y) < 0.5:
					continue
				var climb := absf(gen.get_height(p.x + dir.x * 3.0, p.y + dir.y * 3.0) - gen.get_height(p.x - dir.x * 3.0, p.y - dir.y * 3.0)) / 6.0
				if climb > steepest:
					steepest = climb
					steepest_at = p
	_check(steepest < 0.8, "Alle Wege sind begehbar (steilste Stelle %.2f bei %s)" % [steepest, steepest_at])
	# Spielfigur startet vor dem Südtor, steht auf dem Boden.
	await _frames(90)
	_check(player.is_on_floor() and player.global_position.distance_to(gen.ground(Vector2(0, 252))) < 6.0,
		"Start vor dem Südtor auf festem Boden")
	_check(world.current_region != null and world.current_region.id == &"santo_santiago" and GameState.discovered_regions.has(&"santo_santiago"),
		"Region beim Start erkannt und entdeckt")
	var map_data := world.get_node("MapData") as MapData
	var unknown := 0
	for shape in map_data.shapes:
		if shape["label"] == "???":
			unknown += 1
	_check(unknown == gen.layout.regions.size() - 1, "Karte: unentdeckte Regionen als ??? (%d)" % unknown)
	# In die Steppe laufen lassen (teleportieren): Titelkarte, entdeckt, Karte aktualisiert.
	var steppe := gen.get_region(&"steppe")
	player.global_position = gen.ground(steppe.center + Vector2(30, 30), 1.0)
	await _frames(30)
	_check(GameState.discovered_regions.has(&"steppe") and world.current_region == steppe, "Steppe betreten: neu entdeckt")
	_check(world.hud.region_title.text.contains("Die Ewige Steppe"), "Titelkarte zeigt den Regionsnamen")
	var labels: Array[String] = []
	for shape in map_data.shapes:
		labels.append(String(shape["label"]))
	_check(labels.has("Die Ewige Steppe"), "Karte zeigt die entdeckte Steppe mit Namen")
	var steppe_markers_visible := true
	for node: Node in gen.region_roots[&"steppe"].find_children("*", "MapMarker", true, false):
		steppe_markers_visible = steppe_markers_visible and (node as MapMarker).is_shown()
	var kemet_hidden := true
	for node: Node in gen.region_roots[&"kemet"].find_children("*", "MapMarker", true, false):
		kemet_hidden = kemet_hidden and not (node as MapMarker).is_shown()
	_check(steppe_markers_visible and kemet_hidden, "Kartensymbole nur in entdeckten Regionen")
	# Bewohner: es gibt Leute in den Regionen, und sie stehen auf dem Boden.
	var people := 0
	var grounded := 0
	for node: Node in get_tree().get_nodes_in_group(&"npcs"):
		var npc := node as NPC
		if npc and gen.is_ancestor_of(npc):
			people += 1
			if npc.is_on_floor():
				grounded += 1
	_check(people >= 15 and grounded >= people - 2, "Bewohner in den Regionen (%d, %d auf dem Boden)" % [people, grounded])
	# Meer: Man wird zurück an Land gesetzt.
	player.global_position = Vector3(0, 2.0, 1050)
	await _frames(20)
	_check(gen.get_height(player.global_position.x, player.global_position.z) > -2.5, "Tiefes Meer: zurück an Land")
	# Speichern merkt sich die entdeckten Regionen.
	var data := GameState.to_dict()
	GameState.reset()
	GameState.from_dict(data)
	_check(GameState.discovered_regions.has(&"steppe") and GameState.discovered_regions.has(&"santo_santiago"), "Entdeckte Regionen werden gespeichert")
	# Südtor führt in die Stadt (Ankunft hinter dem Tor).
	var gate := world.find_child("CityGate", true, false) as TravelGate
	gate.change_scene = false
	gate.interact(player)
	_check(GameState.has_pending_spawn and GameState.pending_spawn.origin.distance_to(Vector3(2, 0.3, 150)) < 0.1, "Südtor: Ankunft in Santo Santiago am Tor")
	GameState.has_pending_spawn = false
	GameState.pending_message = ""
	# Bergtempel und Geisterschrein im Nebelwald.
	_check(gen.region_roots[&"kagero"].find_children("*", "MapMarker", true, false).any(
		func(node: Node) -> bool: return (node as MapMarker).kind == MapMarker.Kind.MOUNTAIN_TEMPLE), "Bergtempel auf der Karte")
	var forest_shrine := gen.find_child("ForestShrine", true, false) as SpiritualPressureSource
	_check(forest_shrine != null and forest_shrine.required_spirituality == 5, "Herz des Nebelwalds (Spiritualität 5)")
	world.queue_free()
	await _frames(3)
	print("")
	print("KONTINENTTEST: %s" % ("BESTANDEN" if _failures == 0 else "%d FEHLER" % _failures))
	get_tree().quit(0 if _failures == 0 else 1)


func _frames(count: int) -> void:
	for i in count:
		await get_tree().physics_frame


func _check(condition: bool, description: String) -> void:
	print("%s %s" % ["[OK]  " if condition else "[FEHLER]", description])
	if not condition:
		_failures += 1

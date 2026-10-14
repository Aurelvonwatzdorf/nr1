extends Node
## Rauchtest für Santo Santiago:
##   godot --headless --path game res://tests/city_test.tscn

const CITY := preload("res://scenes/levels/santo_santiago.tscn")

var _failures: int = 0


func _ready() -> void:
	HitStop.enabled = false
	SaveSystem.auto_load_enabled = false
	GameState.ask_character_on_new_game = false
	GameState.reset()
	_run.call_deferred()


func _run() -> void:
	var started := Time.get_ticks_msec()
	var city := CITY.instantiate()
	add_child(city)
	print("Stadt gebaut in %d ms" % (Time.get_ticks_msec() - started))
	var generator: CityGenerator = city.get_node("City")
	var player: Player = city.get_node("Player")
	_check(generator.building_count > 150, "Viele Häuser gebaut (%d)" % generator.building_count)
	var kinds: Array[MapMarker.Kind] = []
	for node in get_tree().get_nodes_in_group(&"map_markers"):
		kinds.append((node as MapMarker).kind)
	for kind: MapMarker.Kind in [MapMarker.Kind.MARKET, MapMarker.Kind.CHURCH, MapMarker.Kind.MOSQUE,
			MapMarker.Kind.SYNAGOGUE, MapMarker.Kind.HOUSE_OF_SILENCE, MapMarker.Kind.CORPORATE_TOWER,
			MapMarker.Kind.BARRACKS, MapMarker.Kind.ANCHOR_MIRROR]:
		_check(kinds.has(kind), "Auf der Karte: %s" % MapMarker.get_kind_name(kind))
	var map_data: MapData = city.get_node("MapData")
	_check(map_data.area_name == "Santo Santiago" and map_data.shapes.size() > 150, "Grundriss für die Karte (%d Flächen)" % map_data.shapes.size())
	# Nichts darf in einem Haus stecken: kleine Kapsel an jeder Position prüfen.
	var space: PhysicsDirectSpaceState3D = (city as Node3D).get_world_3d().direct_space_state
	var probe := CapsuleShape3D.new()
	probe.radius = 0.35
	probe.height = 1.6
	var blocked: Array[String] = []
	var checked := 0
	for group_name: String in ["NPCs", "Enemies", "Pickups", "AnchorMirrors"]:
		for node in city.get_node(group_name).get_children():
			var spot := node as Node3D
			var where := spot.global_position
			if spot is AnchorMirror:
				where = (spot as AnchorMirror).spawn_point.global_position
			var query := PhysicsShapeQueryParameters3D.new()
			query.shape = probe
			query.transform = Transform3D(Basis.IDENTITY, where + Vector3(0, 1.3, 0))
			query.collision_mask = PhysicsLayers.WORLD
			checked += 1
			var hits := space.intersect_shape(query, 1)
			if not hits.is_empty():
				var collider := hits[0]["collider"] as Node3D
				blocked.append("%s@%s(%s %s)" % [spot.name, where.round(), collider.get_parent().name, collider.global_position.round()])
	_check(blocked.is_empty(), "%d Figuren, Spiegel und Gegenstände stehen frei %s" % [checked, blocked])
	await _frames(60)
	_check(player.is_on_floor() and player.global_position.y > -0.5, "Spielfigur steht auf dem Marktplatz")
	var npcs_on_floor := true
	for node in city.get_node("NPCs").get_children():
		npcs_on_floor = npcs_on_floor and (node as NPC).is_on_floor()
	_check(npcs_on_floor, "Alle NPCs stehen auf dem Boden")

	# Alte Frau: über die Straße begleiten
	var woman: OldWoman = city.get_node("NPCs/OldWoman")
	woman.mode = OldWoman.Mode.FOLLOWING
	GameState.start_mission(woman.mission)
	player.global_position = city.get_node("StreetCrossing/WomanDestination").global_position + Vector3(0, 0.1, 0.5)
	for i in 600:
		await get_tree().physics_frame
		if woman.mode == OldWoman.Mode.ARRIVED:
			break
	_check(woman.mode == OldWoman.Mode.ARRIVED, "Alte Frau schafft es über die Straße")
	player.global_position = Vector3(0, 0.1, 12)
	# Geradeaus nach Süden laufen: Figur darf nicht durch den Boden fallen.
	Input.action_press(&"move_back")
	await _frames(180)
	Input.action_release(&"move_back")
	_check(player.global_position.y > -1.0, "Laufen durch die Stadt: kein Fall durch den Boden (y %.1f)" % player.global_position.y)
	# Stadtrand: unsichtbare Mauer.
	player.global_position = Vector3(0.0, 0.5, 118.0)
	Input.action_press(&"move_back")
	await _frames(120)
	Input.action_release(&"move_back")
	_check(player.global_position.z < 121.0, "Unsichtbare Mauer am Stadtrand hält (z %.1f)" % player.global_position.z)
	print("")
	print("STADTTEST: %s" % ("BESTANDEN" if _failures == 0 else "%d FEHLER" % _failures))
	get_tree().quit(0 if _failures == 0 else 1)


func _frames(count: int) -> void:
	for i in count:
		await get_tree().physics_frame


func _check(condition: bool, description: String) -> void:
	print("%s %s" % ["[OK]  " if condition else "[FEHLER]", description])
	if not condition:
		_failures += 1

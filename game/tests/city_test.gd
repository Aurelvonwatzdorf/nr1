extends Node
## Rauchtest für Santo Santiago:
##   godot --headless --path game res://tests/city_test.tscn

const CITY := preload("res://scenes/levels/santo_santiago.tscn")

var _failures: int = 0


func _ready() -> void:
	HitStop.enabled = false
	SaveSystem.auto_load_enabled = false
	GameState.ask_character_on_new_game = false
	GameState.test_start_money = 0
	GameState.reset()
	_run.call_deferred()


func _run() -> void:
	var started := Time.get_ticks_msec()
	var city := CITY.instantiate()
	add_child(city)
	print("Stadt gebaut in %d ms" % (Time.get_ticks_msec() - started))
	var generator: CityGenerator = city.get_node("City")
	var player: Player = city.get_node("Player")
	_check(generator.building_count > 300, "Viele Häuser gebaut (%d)" % generator.building_count)
	print("Bauformen: %s" % generator.kind_counts)
	var drawn := 0
	var parts := generator.find_children("*", "MeshInstance3D", true, false)
	for node in parts:
		if (node as MeshInstance3D).mesh != null:
			drawn += 1
	print("Bauteile: %d, gezeichnet: %d" % [parts.size(), drawn])
	_check(drawn < 500, "Stadt zusammengefasst: %d Meshes statt Tausender (%d Stücke)" % [drawn, generator.batch_count])
	_check(generator.kind_counts.size() >= 12, "Viele verschiedene Bauformen (%d)" % generator.kind_counts.size())
	# Organisch: Umriss ist kein Rechteck, Straßen laufen in alle Richtungen.
	var radii: Array[float] = []
	for point in generator.outline:
		radii.append(point.length())
	_check(radii.max() - radii.min() > 40.0, "Natürlicher Stadtumriss (Radius %.0f bis %.0f m)" % [radii.min(), radii.max()])
	var diagonal := 0
	var segments := 0
	for path in generator.road_paths:
		for i in path.size() - 1:
			var angle := fmod(absf((path[i + 1] - path[i]).angle()), PI / 2.0)
			segments += 1
			if angle > 0.15 and angle < PI / 2.0 - 0.15:
				diagonal += 1
	_check(segments > 200 and diagonal > segments * 0.4, "Kein Schachbrett: %d von %d Straßenstücken schräg" % [diagonal, segments])
	_check(generator.kind_counts.get(&"imperial_tower", 0) >= 2 and generator.kind_counts.get(&"monument_block", 0) >= 3 \
		and generator.kind_counts.has(&"citadel"), "Imperiales Konzernviertel: Zitadelle, Turmpaar, Monumentalbauten")
	var kinds: Array[MapMarker.Kind] = []
	for node in get_tree().get_nodes_in_group(&"map_markers"):
		kinds.append((node as MapMarker).kind)
	for kind: MapMarker.Kind in [MapMarker.Kind.MARKET, MapMarker.Kind.CHURCH, MapMarker.Kind.MOSQUE,
			MapMarker.Kind.SYNAGOGUE, MapMarker.Kind.HOUSE_OF_SILENCE, MapMarker.Kind.CORPORATE_TOWER,
			MapMarker.Kind.BARRACKS, MapMarker.Kind.ANCHOR_MIRROR, MapMarker.Kind.BLACK_MARKET, MapMarker.Kind.SPIRIT_SHRINE]:
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
	var shrine: SpiritualPressureSource = city.get_node("SpiritPlaces/ShrineWest")
	var shrine_at := Vector2(shrine.global_position.x, shrine.global_position.z)
	_check(generator.is_free(shrine_at, 5.0) and shrine.required_spirituality == 3, "Geisterschrein steht frei am Stadtrand (Spiritualität 3 nötig)")
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
		if woman.mode != OldWoman.Mode.FOLLOWING:
			break
	_check(GameState.get_mission_status(&"help_old_woman") == GameState.MissionStatus.COMPLETED, "Alte Frau schafft es über die Straße")
	for i in 900:
		await get_tree().physics_frame
		if woman.is_home():
			break
	_check(woman.is_home() and not woman.visible, "Danach geht sie in ihr Haus")
	# Einwohner: laufen herum, meist im eigenen Viertel; Händler bleiben in der Nähe.
	var citizens := city.get_node("Citizens").get_children()
	_check(citizens.size() >= 40, "Einwohner in allen Vierteln (%d)" % citizens.size())
	var starts: Array[Vector3] = []
	for node in citizens:
		starts.append((node as Node3D).global_position)
	var merchant: NPC = city.get_node("NPCs/MarketMerchant")
	var merchant_moved := 0.0
	var merchant_max := 0.0
	var merchant_start := merchant.global_position
	for i in 900:
		await get_tree().physics_frame
		merchant_max = maxf(merchant_max, merchant.global_position.distance_to(merchant.home_position))
		merchant_moved = maxf(merchant_moved, merchant.global_position.distance_to(merchant_start))
	var moved := 0
	var at_home := 0
	for i in citizens.size():
		var citizen := citizens[i] as Citizen
		if citizen.global_position.distance_to(starts[i]) > 4.0:
			moved += 1
		var here := generator.district_at(Vector2(citizen.global_position.x, citizen.global_position.z))
		if here and here.id == citizen.home_quarter:
			at_home += 1
	_check(moved > citizens.size() * 0.6, "Einwohner laufen herum (%d von %d)" % [moved, citizens.size()])
	_check(at_home > citizens.size() * 0.75, "Einwohner bleiben meist in ihrem Viertel (%d von %d)" % [at_home, citizens.size()])
	_check(merchant_moved > 0.5 and merchant_max <= merchant.roam_radius + 1.0, "Händler schlendert, bleibt aber an seinem Platz (max. %.1f m)" % merchant_max)
	# Beten / stille Einkehr: alle vier Häuser wirken gleich auf die Spiritualität
	var spots := get_tree().get_nodes_in_group(&"prayer_spots")
	var spot_ids: Array[StringName] = []
	for node in spots:
		spot_ids.append((node as PrayerSpot).spot_id)
	spot_ids.sort()
	_check(spot_ids.size() == 4 and spot_ids.has(&"church") and spot_ids.has(&"mosque") and spot_ids.has(&"synagogue") and spot_ids.has(&"house_of_silence"), "Beten in Kirche, Moschee, Synagoge, Einkehr im Haus der Stille")
	var silence: PrayerSpot = city.get_node("City/Prayer_house_of_silence")
	var church: PrayerSpot = city.get_node("City/Prayer_church")
	_check(silence.prompt == "Stille Einkehr" and silence.experience == church.experience, "Haus der Stille wirkt genauso wie ein Gotteshaus")
	player.focus.remove(player.focus.current)
	church.interact(player)
	_check(GameState.spirit_experience == 40 and is_equal_approx(player.focus.current, player.focus.max_value), "Gebet: +40 Spiritualität, Fokus voll")
	church.interact(player)
	_check(GameState.spirit_experience == 40, "Am selben Ort erst nach einer Weile wieder")
	silence.interact(player)
	for node in spots:
		if node != church and node != silence:
			(node as PrayerSpot).interact(player)
	_check(GameState.stats.spirituality == 2 and GameState.spirit_experience == 60, "Nach vier Gebeten: Spiritualität Stufe 2")
	var free := true
	for node in spots:
		free = free and generator.is_free(Vector2((node as Node3D).global_position.x, (node as Node3D).global_position.z))
	_check(free, "Gebetsorte liegen vor den Häusern, nicht darin")

	# Navi: Wegpunkt auf der großen Karte setzen, schnellster Weg über die Straßen
	var target := Vector2(-22, 100)
	var route := generator.find_route(Vector2(0, 12), target)
	var route_length := 0.0
	var longest_step := 0.0
	for i in route.size() - 1:
		var step := route[i].distance_to(route[i + 1])
		route_length += step
		longest_step = maxf(longest_step, step)
	_check(route.size() > 5 and longest_step < 30.0 and route_length < Vector2(0, 12).distance_to(target) * 2.0,
		"Route vom Markt zur Senke über Straßen (%d Punkte, %.0f m)" % [route.size(), route_length])
	player.global_position = Vector3(0, 0.1, 12)
	var map_menu: WorldMapMenu = city.get_node("GameUI/WorldMapMenu")
	map_menu.open()
	await _frames(3)
	var map_view := map_menu.find_child("MapView") as MapView
	map_view.size = Vector2(900, 700)
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	click.position = map_view.world_to_screen(target)
	map_view._gui_input(click)
	_check(GameState.has_map_waypoint and GameState.map_waypoint.distance_to(target) < 3.0, "Linksklick auf die Karte setzt einen Wegpunkt")
	_check(generator.current_route.size() > 5, "Der schnellste Weg wird angezeigt (%d Punkte)" % generator.current_route.size())
	map_menu.close()
	player.global_position = Vector3(target.x, 0.1, target.y + 3.0)
	await _frames(40)
	_check(not GameState.has_map_waypoint, "Am Ziel verschwindet der Wegpunkt")
	# Fahndung: Konzernwachen angreifen → Spiegeljäger → gefangen
	var wanted: WantedSystem = city.get_node("WantedSystem")
	wanted.capture_scene = ""
	var guard: Enemy = city.get_node("Enemies/GuardBoulevard")
	player.global_position = guard.global_position + Vector3(0, 0.1, 3)
	await _frames(3)
	var punch := HitData.new()
	punch.damage = 1.0
	punch.source = player
	guard.hurtbox.receive_hit(punch)
	_check(GameState.wanted_level > 0.0 and wanted.get_stars() == 1, "Wache angreifen: Fahndung steigt (1 Stern)")
	wanted.add_wanted(100.0)
	await _frames(3)
	_check(wanted.hunters.size() == 2 and wanted.hunters[0].data.captures, "Volle Fahndung: zwei Spiegeljäger erscheinen")
	var free_spawn := true
	for hunter in wanted.hunters:
		free_spawn = free_spawn and generator.is_free(Vector2(hunter.global_position.x, hunter.global_position.z))
	_check(free_spawn, "Spiegeljäger tauchen auf der Straße auf")
	var captured: Array[bool] = []
	EventBus.player_captured.connect(func(_p: Player) -> void: captured.append(true))
	player.health.revive()
	var final_blow := HitData.new()
	final_blow.damage = 1000.0
	final_blow.source = wanted.hunters[0]
	player.hurtbox.receive_hit(final_blow)
	await _frames(3)
	_check(captured.size() == 1 and not player.health.is_dead, "Besiegt von Spiegeljägern: gefangen statt tot")
	_check(GameState.wanted_level == 0.0 and wanted.hunters.is_empty() and GameState.return_scene != "", "Fahndung vorbei, Rückkehrort gemerkt")
	_check(GameState.capture_district == &"corporate" and not GameState.capture_clear_circles.is_empty(), "Fangort gemerkt: Konzernviertel")
	# Die Spiegelrealität baut genau dieselbe Stadt (gleiche Häuser).
	var mirror := (load("res://scenes/levels/mirror_city_reality.tscn") as PackedScene).instantiate() as MirrorCityReality
	mirror.change_scene_on_break = false
	add_child(mirror)
	await _frames(3)
	_check(mirror.city.building_count == generator.building_count and mirror.reality_name == "Der endlose Feierabend",
		"Spiegelrealität gleicht dem Fangort (%d = %d Häuser)" % [mirror.city.building_count, generator.building_count])
	mirror.queue_free()
	await _frames(3)
	GameState.is_captured = false
	GameState.return_scene = ""
	await _frames(3)
	player.global_position = Vector3(0, 0.1, 12)
	# Geradeaus nach Süden laufen: Figur darf nicht durch den Boden fallen.
	Input.action_press(&"move_back")
	await _frames(180)
	Input.action_release(&"move_back")
	_check(player.global_position.y > -1.0, "Laufen durch die Stadt: kein Fall durch den Boden (y %.1f)" % player.global_position.y)
	# Stadtrand: unsichtbare Mauer (Spieler läuft im Süden nach draußen).
	var south := Vector2.ZERO
	for point in generator.boundary:
		if point.y > south.y:
			south = point
	player.global_position = Vector3(south.x, 0.5, south.y) * Vector3(1, 1, 1) - Vector3(0, 0, 4)
	player.global_position.y = 0.5
	await _frames(5)
	Input.action_press(&"move_back")
	await _frames(150)
	Input.action_release(&"move_back")
	var at := Vector2(player.global_position.x, player.global_position.z)
	_check(Geometry2D.is_point_in_polygon(at, generator.boundary.duplicate()) or at.distance_to(south) < 2.0, "Unsichtbare Mauer am Stadtrand hält (z %.1f, Rand %.1f)" % [at.y, south.y])
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

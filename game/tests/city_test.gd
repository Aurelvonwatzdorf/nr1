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
	await _frames(60)
	_check(player.is_on_floor() and player.global_position.y > -0.5, "Spielfigur steht auf dem Marktplatz")
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

class_name ContinentWorld
extends Level
## Der Kontinent Aurion: offene Welt mit allen Regionen (Zeitinseln).
## Zeigt beim Betreten einer Region ihren Namen (Titelkarte), merkt sich
## entdeckte Regionen (Karte zeigt sonst „???“), passt den Nebel an die Region an
## und hält die Spielfigur vom tiefen Meer fern.

@onready var generator: ContinentGenerator = $Continent

## Region, in der die Spielfigur gerade ist.
var current_region: ContinentRegion
var _environment: Environment
var _last_safe: Vector3 = Vector3.ZERO
var _check_time: float = 0.0
var _title_cooldown: float = 0.0


func _ready() -> void:
	var arriving := GameState.has_pending_spawn
	super._ready()
	if not arriving and not (_loaded_save and GameState.has_checkpoint):
		# Neu hier (z. B. aus dem Test): vor dem Südtor der Hauptstadt.
		var spawn := generator.layout.city_gate_spawn
		player.global_position = generator.ground(Vector2(spawn.x, spawn.z), 0.5)
		player.rotation.y = PI
	var world_environment := get_node_or_null("WorldEnvironment") as WorldEnvironment
	if world_environment:
		_environment = world_environment.environment
	_last_safe = player.global_position
	_hide_undiscovered_markers()
	_refresh_map()


func _physics_process(delta: float) -> void:
	_title_cooldown = maxf(_title_cooldown - delta, 0.0)
	_check_time -= delta
	if _check_time <= 0.0:
		_check_time = 0.25
		_update_region()
		_keep_out_of_sea()
	_update_fog(delta)


func _update_region() -> void:
	var at := Vector2(player.global_position.x, player.global_position.z)
	var region := generator.region_at(at)
	if region == current_region:
		return
	current_region = region
	if region == null:
		return
	var first_time := not GameState.discovered_regions.has(region.id)
	if first_time:
		GameState.discovered_regions.append(region.id)
		_show_region_markers(region.id)
		_refresh_map()
	if first_time or _title_cooldown <= 0.0:
		hud.show_region_title(region.region_name, "Neu entdeckt · %s" % region.epoch if first_time else region.epoch)
		_title_cooldown = 20.0


## Tiefes Meer: zurück an Land (man kann nicht schwimmen).
func _keep_out_of_sea() -> void:
	var at := player.global_position
	var ground := generator.get_height(at.x, at.z)
	if ground > -2.5:
		if player.is_on_floor():
			_last_safe = at
		return
	player.global_position = _last_safe + Vector3(0, 0.5, 0)
	player.velocity = Vector3.ZERO
	hud.show_message("Das Meer ist hier zu tief.")


## Nebel und Farbe gleiten zur Stimmung der Region.
func _update_fog(delta: float) -> void:
	if _environment == null or current_region == null:
		return
	var blend := 1.0 - exp(-delta * 0.8)
	_environment.fog_light_color = _environment.fog_light_color.lerp(current_region.fog_color, blend)
	_environment.fog_density = lerpf(_environment.fog_density, current_region.fog_density, blend)


func _refresh_map() -> void:
	var map_data := get_node_or_null("MapData") as MapData
	if map_data:
		generator.register_map(map_data, GameState.discovered_regions)


## Marker unentdeckter Regionen verstecken (Ankerspiegel, Wahrzeichen …).
func _hide_undiscovered_markers() -> void:
	for id: StringName in generator.region_roots:
		if not GameState.discovered_regions.has(id):
			for node: Node in generator.region_roots[id].find_children("*", "MapMarker", true, false):
				(node as MapMarker).visible = false


func _show_region_markers(id: StringName) -> void:
	if not generator.region_roots.has(id):
		return
	for node: Node in generator.region_roots[id].find_children("*", "MapMarker", true, false):
		(node as MapMarker).visible = true

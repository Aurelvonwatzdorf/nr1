class_name WantedSystem
extends Node
## Fahndung in Santo Santiago (wie bei GTA, aber mit Spiegeljägern):
## - Konzernkräfte angreifen, töten oder in ihrer Nähe schießen lässt die
##   Fahndung steigen (0–100, im HUD als Sterne).
## - Ist sie voll, kommen zwei Spiegeljäger. Wer von ihnen besiegt wird, stirbt
##   nicht, sondern wird in eine Spiegelrealität gesperrt (`capture_scene`).
## - Hält man sich eine Weile ruhig und ist kein Jäger in der Nähe, sinkt sie.
## Stufen (Mechanik-Studie 2, `fahndung_stufen.md`):
##   1 Gesehen (bis 19): Wachen in der Nähe gehen nachsehen.
##   2 Gesucht (bis 39): Suchkreis 60 m, 2 Wachen Verstärkung suchen ihn ab.
##   3 (bis 69): Suchkreis 90 m. (Später: Streifen mit Fahrzeugen.)
##   4 (bis 99): Suchkreis 120 m, 2 weitere Wachen. (Später: Sperren, Drohnen.)
##   5 (100): Vorwarnung, dann Spiegeljäger.
## Sinken nur, wenn keine Konzernkraft einen sieht, lange genug Ruhe ist und man
## (ab Stufe 2) außerhalb des Suchkreises ist.

const ENEMY_SCENE := preload("res://scenes/enemies/enemy.tscn")
const HUNTER_DATA := preload("res://resources/enemies/mirror_hunter.tres")

@export var city: CityGenerator
## Realität, in die man gesperrt wird (leer = nur Signal, z. B. im Test).
@export_file("*.tscn") var capture_scene: String = "res://scenes/levels/mirror_city_reality.tscn"
@export var hit_gain: float = 12.0
@export var kill_gain: float = 25.0
@export var shot_gain: float = 8.0
@export var decay_per_second: float = 6.0
@export var hunter_count: int = 2
## So lange vor dem Erscheinen der Spiegeljäger flackern die Spiegel (Flucht möglich).
@export var hunter_warning_time: float = 6.0
## Je Stufe (0–5): Radius des Suchkreises und nötige Ruhezeit.
const STAGE_SEARCH_RADIUS: Array[float] = [0.0, 0.0, 60.0, 90.0, 120.0, 120.0]
const STAGE_CALM_TIME: Array[float] = [15.0, 10.0, 15.0, 15.0, 25.0, 25.0]
## Verstärkung: so viele Wachen ab Stufe 2 bzw. 4.
const REINFORCEMENTS_STAGE_2 := 2
const REINFORCEMENTS_STAGE_4 := 2
## In diesem Umkreis um eine Tat gehen Konzernwachen nachsehen.
const ALERT_RADIUS := 40.0

var hunters: Array[Enemy] = []
var reinforcements: Array[Enemy] = []
var _calm_time: float = 0.0
## Restzeit der Vorwarnung (unter 0 = keine läuft).
var _hunter_warning_left: float = -1.0
## Wie viele Verstärkungswellen in dieser Fahndung schon kamen.
var _reinforcement_waves: int = 0


func _ready() -> void:
	GameState.wanted_level = 0.0
	GameState.is_captured = false
	EventBus.enemy_hit_by_player.connect(func(enemy: Enemy) -> void:
		if enemy.data.faction == &"corporate":
			add_wanted(hit_gain))
	EventBus.enemy_killed.connect(func(enemy: Enemy) -> void:
		if enemy.data.faction == &"corporate":
			add_wanted(kill_gain))
	EventBus.shot_fired.connect(_on_shot_fired)
	EventBus.player_captured.connect(_on_player_captured)


func add_wanted(amount: float) -> void:
	_calm_time = 0.0
	var player := _player()
	if player:
		GameState.wanted_search_center = player.global_position
		# Konzernwachen in der Nähe gehen nachsehen.
		for node: Node in get_tree().get_nodes_in_group(&"enemies"):
			var enemy := node as Enemy
			if enemy and enemy.data.faction == &"corporate" and not enemy.health.is_dead:
				enemy.perception.hear(player.global_position, ALERT_RADIUS)
	_set_wanted(GameState.wanted_level + amount)


func get_stars() -> int:
	return ceili(GameState.wanted_level / 20.0)


## Fahndungsstufe 0–5 (siehe oben).
func get_stage() -> int:
	var level := GameState.wanted_level
	if level <= 0.0:
		return 0
	if level < 20.0:
		return 1
	if level < 40.0:
		return 2
	if level < 70.0:
		return 3
	if level < 100.0:
		return 4
	return 5


## Darf die Fahndung gerade sinken? (genug Ruhe, außerhalb des Suchkreises, kein Jäger nah)
func can_decay() -> bool:
	var stage := get_stage()
	if stage == 0 or _calm_time < STAGE_CALM_TIME[stage] or _hunter_near(35.0):
		return false
	var player := _player()
	if player and GameState.wanted_search_radius > 0.0:
		var offset := player.global_position - GameState.wanted_search_center
		offset.y = 0.0
		if offset.length() < GameState.wanted_search_radius:
			return false
	return true


func _physics_process(delta: float) -> void:
	hunters = hunters.filter(func(hunter: Enemy) -> bool: return is_instance_valid(hunter) and not hunter.health.is_dead)
	reinforcements = reinforcements.filter(func(guard: Enemy) -> bool: return is_instance_valid(guard))
	_calm_time += delta
	var stage := get_stage()
	GameState.wanted_search_radius = STAGE_SEARCH_RADIUS[stage]
	if stage > 0 and _seen_by_corporate():
		_calm_time = 0.0
		var player := _player()
		if player:
			GameState.wanted_search_center = player.global_position
	_update_hunter_warning(delta)
	if stage >= 2 and _reinforcement_waves == 0:
		_spawn_reinforcements(REINFORCEMENTS_STAGE_2)
	if stage >= 4 and _reinforcement_waves == 1:
		_spawn_reinforcements(REINFORCEMENTS_STAGE_4)
	if can_decay():
		# Getarnt (Schattenhaut) verliert man die Verfolger doppelt so schnell.
		var decay := decay_per_second * (2.0 if GameState.player_camouflaged else 1.0)
		_set_wanted(GameState.wanted_level - decay * delta)
		if GameState.wanted_level <= 0.0:
			_dismiss_hunters()
			_dismiss_reinforcements()


## Volle Fahndung: erst flackern die Spiegel (Zeit zur Flucht), dann kommen die Jäger.
func _update_hunter_warning(delta: float) -> void:
	if GameState.wanted_level < 100.0 or not hunters.is_empty() or GameState.is_captured:
		_hunter_warning_left = -1.0
		return
	if _hunter_warning_left < 0.0:
		_hunter_warning_left = hunter_warning_time
		EventBus.message_requested.emit("Die Spiegel flackern … die Spiegeljäger kommen.")
		EventBus.camera_shake_requested.emit(0.25)
	_hunter_warning_left -= delta
	if _hunter_warning_left <= 0.0:
		_hunter_warning_left = -1.0
		_spawn_hunters()


## Sieht gerade eine Konzernkraft die Spielfigur?
func _seen_by_corporate() -> bool:
	for node: Node in get_tree().get_nodes_in_group(&"enemies"):
		var enemy := node as Enemy
		if enemy and enemy.data.faction == &"corporate" and not enemy.health.is_dead \
				and not enemy.is_incapacitated() and enemy.perception.sees_player:
			return true
	return false


## Verstärkung: Wachen erscheinen auf der Straße am Rand des Suchkreises und suchen ihn ab.
func _spawn_reinforcements(count: int) -> void:
	_reinforcement_waves += 1
	var player := _player()
	if player == null:
		return
	var center := GameState.wanted_search_center
	for i in count:
		var at := _street_point(Vector2(center.x, center.z) + Vector2.from_angle(TAU * (i + 0.5) / count) * 30.0, 25.0)
		var guard := ENEMY_SCENE.instantiate() as Enemy
		guard.position = Vector3(at.x, 0.2, at.y)
		guard.add_to_group(&"wanted_reinforcements")
		get_parent().add_child(guard)
		guard.perception.hear(center, INF)
		reinforcements.append(guard)
	EventBus.message_requested.emit("Konzernwachen durchsuchen die Gegend.")


func _dismiss_reinforcements() -> void:
	for guard in reinforcements:
		if is_instance_valid(guard):
			guard.queue_free()
	reinforcements.clear()
	_reinforcement_waves = 0
	GameState.wanted_search_radius = 0.0


## Nächster freier Straßenpunkt bei `near`, mindestens `min_distance` von der Spielfigur.
func _street_point(near: Vector2, min_distance: float) -> Vector2:
	var player := _player()
	if city == null or city.waypoints.is_empty() or player == null:
		return near
	var origin := Vector2(player.global_position.x, player.global_position.z)
	var best := near
	var best_score := INF
	for point: Vector2 in city.waypoints:
		if point.distance_to(origin) < min_distance:
			continue
		var score := point.distance_to(near)
		if score < best_score:
			best_score = score
			best = point
	return best


func _set_wanted(value: float) -> void:
	var before := GameState.wanted_level
	GameState.wanted_level = clampf(value, 0.0, 100.0)
	if not is_equal_approx(before, GameState.wanted_level):
		EventBus.wanted_changed.emit(GameState.wanted_level)
		if before < 100.0 and GameState.wanted_level >= 100.0:
			EventBus.message_requested.emit("Höchste Fahndung: Die Spiegeljäger kommen.")


func _player() -> Player:
	return get_tree().get_first_node_in_group(&"player") as Player


func _hunter_near(radius: float) -> bool:
	var player := _player()
	if player == null:
		return false
	for hunter in hunters:
		if is_instance_valid(hunter) and hunter.global_position.distance_to(player.global_position) < radius:
			return true
	return false


func _spawn_hunters() -> void:
	var player := _player()
	if player == null:
		return
	var origin := Vector2(player.global_position.x, player.global_position.z)
	for i in hunter_count:
		var at := origin + Vector2.from_angle(TAU * i / hunter_count) * 28.0
		if city and not city.waypoints.is_empty():
			# Auf der Straße auftauchen, nicht in einem Haus.
			var best := -1
			var best_score := INF
			for index in city.waypoints.size():
				var distance := city.waypoints[index].distance_to(origin)
				var score := absf(distance - 30.0) + city.waypoints[index].distance_to(at) * 0.3
				if distance > 18.0 and score < best_score:
					best_score = score
					best = index
			if best >= 0:
				at = city.waypoints[best]
		var hunter := ENEMY_SCENE.instantiate() as Enemy
		hunter.data = HUNTER_DATA
		hunter.position = Vector3(at.x, 0.2, at.y)
		hunter.add_to_group(&"mirror_hunters")
		get_parent().add_child(hunter)
		hunters.append(hunter)
		# Jäger wissen, wen sie suchen.
		var target := hunter.get_player()
		if target:
			hunter.perception.alert(target.global_position)
	EventBus.camera_shake_requested.emit(0.3)


func _dismiss_hunters() -> void:
	for hunter in hunters:
		if is_instance_valid(hunter):
			hunter.queue_free()
	hunters.clear()
	EventBus.message_requested.emit("Die Fahndung ist eingestellt.")


func _on_shot_fired(from: Vector3) -> void:
	for node in get_tree().get_nodes_in_group(&"enemies"):
		var enemy := node as Enemy
		if enemy and enemy.data.faction == &"corporate" and not enemy.health.is_dead \
				and enemy.global_position.distance_to(from) < 25.0:
			add_wanted(shot_gain)
			return


## Erwischt: Man wacht in einer Spiegelrealität auf, die genau diesem Ort
## gleicht. Nach dem Ausbruch wacht man hier wieder auf.
func _on_player_captured(player: Player) -> void:
	GameState.return_scene = GameState.current_scene
	GameState.return_transform = player.global_transform
	if city:
		var at := Vector2(player.global_position.x, player.global_position.z)
		GameState.capture_district = city.district_at(at).id if city.is_inside_city(at) else &"slum"
		GameState.capture_clear_circles = city.get_keep_clear_circles()
	_set_wanted(0.0)
	_dismiss_hunters()
	_dismiss_reinforcements()
	EventBus.message_requested.emit("Die Spiegeljäger haben dich erwischt …")
	EventBus.camera_shake_requested.emit(0.7)
	if capture_scene == "":
		return
	await get_tree().create_timer(2.0).timeout
	GameState.clear_checkpoint()
	get_tree().change_scene_to_file(capture_scene)

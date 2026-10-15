class_name WantedSystem
extends Node
## Fahndung in Santo Santiago (wie bei GTA, aber mit Spiegeljägern):
## - Konzernkräfte angreifen, töten oder in ihrer Nähe schießen lässt die
##   Fahndung steigen (0–100, im HUD als Sterne).
## - Ist sie voll, kommen zwei Spiegeljäger. Wer von ihnen besiegt wird, stirbt
##   nicht, sondern wird in eine Spiegelrealität gesperrt (`capture_scene`).
## - Hält man sich eine Weile ruhig und ist kein Jäger in der Nähe, sinkt sie.

const ENEMY_SCENE := preload("res://scenes/enemies/enemy.tscn")
const HUNTER_DATA := preload("res://resources/enemies/mirror_hunter.tres")

@export var city: CityGenerator
## Realität, in die man gesperrt wird (leer = nur Signal, z. B. im Test).
@export_file("*.tscn") var capture_scene: String = "res://scenes/levels/mirror_city_reality.tscn"
@export var hit_gain: float = 12.0
@export var kill_gain: float = 25.0
@export var shot_gain: float = 8.0
## So lange muss man sich ruhig verhalten, bevor die Fahndung sinkt (Sekunden).
@export var calm_delay: float = 15.0
@export var decay_per_second: float = 6.0
@export var hunter_count: int = 2

var hunters: Array[Enemy] = []
var _calm_time: float = 0.0


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
	_set_wanted(GameState.wanted_level + amount)


func get_stars() -> int:
	return ceili(GameState.wanted_level / 20.0)


func _physics_process(delta: float) -> void:
	hunters = hunters.filter(func(hunter: Enemy) -> bool: return is_instance_valid(hunter) and not hunter.health.is_dead)
	if GameState.wanted_level >= 100.0 and hunters.is_empty() and not GameState.is_captured:
		_spawn_hunters()
	_calm_time += delta
	if _calm_time >= calm_delay and GameState.wanted_level > 0.0 and not _hunter_near(35.0):
		_set_wanted(GameState.wanted_level - decay_per_second * delta)
		if GameState.wanted_level <= 0.0:
			_dismiss_hunters()


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
	EventBus.message_requested.emit("Die Spiegeljäger haben dich erwischt …")
	EventBus.camera_shake_requested.emit(0.7)
	if capture_scene == "":
		return
	await get_tree().create_timer(2.0).timeout
	GameState.clear_checkpoint()
	get_tree().change_scene_to_file(capture_scene)

class_name NPC
extends CharacterBody3D
## Nicht-Spieler-Figur. Mit E ansprechen (TalkArea). Eigene NPCs erben hiervon und
## überschreiben `talk()` für ihr Gespräch und `_npc_physics()` für Bewegung.

## Eindeutige ID (für Speichern und Moral-Taten).
@export var npc_id: StringName = &""
@export var display_name: String = "Fremder"
@export var body_color: Color = Color(0.7, 0.65, 0.55)
@export var walk_speed: float = 1.5
## So schnell flieht er, wenn er angegriffen wird.
@export var flee_speed: float = 4.0
## So lange flieht er nach einem Angriff (Sekunden).
@export var flee_time: float = 4.0

## Wie sich der NPC bewegt, wenn er nichts anderes zu tun hat.
enum Roam {
	STAY, ## bleibt stehen
	NEAR_HOME, ## schlendert im Umkreis `roam_radius` um seinen Platz (z. B. Händler)
	CITY, ## läuft durch die Straßen, meist in seinem eigenen Viertel
}

@export_group("Herumlaufen")
@export var roam: Roam = Roam.STAY
@export var roam_radius: float = 5.0
## Viertel, in dem er wohnt (CityDistrict.id). Leer = Viertel am Startpunkt.
@export var home_quarter: StringName = &""
## Wie oft er in seinem Viertel bleibt (1 = nie woanders hin).
@export_range(0.0, 1.0) var home_loyalty: float = 0.85

@onready var talk_area: Interactable = $TalkArea
@onready var body_mesh: MeshInstance3D = $Model/Body
@onready var model: Node3D = $Model
@onready var name_label: Label3D = $NameLabel
@onready var health: HealthComponent = $HealthComponent
@onready var hurtbox: Hurtbox = $Hurtbox

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var _material: StandardMaterial3D
var _talking: bool = false
var _flee_time_left: float = 0.0
var _flee_from: Vector3 = Vector3.ZERO
## Kam der letzte Treffer von der Spielfigur? (Moral zählt nur eigene Taten.)
var _last_hit_by_player: bool = false
## Wo er zu Hause ist (Startpunkt).
var home_position: Vector3 = Vector3.ZERO
var _city: CityGenerator
var _roam_target: Vector3 = Vector3.ZERO
var _has_target: bool = false
var _wait_left: float = 0.0
var _node: int = -1
var _previous_node: int = -1
var _stuck_time: float = 0.0
var _last_position: Vector3 = Vector3.ZERO
## Seitlicher Abstand zur Straßenmitte (damit nicht alle in einer Reihe laufen).
var _lane: float = 0.0
var _roam_rng := RandomNumberGenerator.new()


func _ready() -> void:
	if GameState.dead_npcs.has(npc_id):
		queue_free()
		return
	add_to_group(&"npcs")
	hurtbox.hit_received.connect(_on_hit_received)
	# Läuft vor dem Schaden, darum weiß _on_died() schon, wer getroffen hat.
	hurtbox.hit_filter = func(hit: HitData) -> Hurtbox.Result:
		_last_hit_by_player = hit.source is Player
		return Hurtbox.Result.HIT
	health.died.connect(_on_died)
	_material = StandardMaterial3D.new()
	_material.albedo_color = body_color
	body_mesh.material_override = _material
	name_label.text = display_name
	talk_area.prompt = "Mit %s sprechen" % display_name
	talk_area.interacted.connect(_on_talk_requested)
	home_position = global_position
	_roam_rng.seed = hash(npc_id)
	_lane = _roam_rng.randf_range(-1.2, 1.2)
	_wait_left = _roam_rng.randf_range(0.0, 3.0)


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta
	if health.is_dead:
		velocity.x = 0.0
		velocity.z = 0.0
	elif _flee_time_left > 0.0:
		_flee_time_left -= delta
		var away := global_position - _flee_from
		walk_towards(global_position + away.normalized() * 5.0, flee_speed, delta)
	else:
		_npc_physics(delta)
	move_and_slide()


## Für Unterklassen: Bewegung pro Physik-Frame (Standard: herumlaufen wie in
## `roam` eingestellt, sonst stehen bleiben).
func _npc_physics(delta: float) -> void:
	if roam == Roam.STAY or _talking or not _can_roam():
		_brake(delta)
		return
	_roam_step(delta)


## Für Unterklassen: darf er gerade herumlaufen? (Der Kranke z. B. nicht.)
func _can_roam() -> bool:
	return true


func _brake(delta: float) -> void:
	var horizontal := Vector3(velocity.x, 0.0, velocity.z).move_toward(Vector3.ZERO, 10.0 * delta)
	velocity.x = horizontal.x
	velocity.z = horizontal.z


func _roam_step(delta: float) -> void:
	if _wait_left > 0.0:
		_wait_left -= delta
		_brake(delta)
		return
	if not _has_target:
		_pick_roam_target()
		_last_position = global_position
		_stuck_time = 0.0
		if not _has_target:
			_wait_left = 2.0
			return
	var offset := _roam_target - global_position
	offset.y = 0.0
	if offset.length() < 1.0:
		_has_target = false
		# Ab und zu stehen bleiben und sich umsehen.
		if _roam_rng.randf() < (0.6 if roam == Roam.NEAR_HOME else 0.15):
			_wait_left = _roam_rng.randf_range(2.0, 6.0)
		return
	walk_towards(_roam_target, walk_speed, delta)
	# Hängt er fest (z. B. an einem Marktstand), sucht er sich ein neues Ziel.
	_stuck_time += delta
	if _stuck_time > 2.5:
		if global_position.distance_to(_last_position) < 0.5:
			_has_target = false
			_node = _previous_node if roam == Roam.CITY else _node
		_stuck_time = 0.0
		_last_position = global_position


func _pick_roam_target() -> void:
	if _city == null:
		_city = get_tree().get_first_node_in_group(&"city_generator") as CityGenerator
	if roam == Roam.NEAR_HOME or _city == null or _city.waypoints.is_empty():
		for attempt in 8:
			var angle := _roam_rng.randf_range(0.0, TAU)
			var target := home_position + Vector3(cos(angle), 0.0, sin(angle)) * _roam_rng.randf_range(0.5, roam_radius)
			if _city == null or _city.is_free(Vector2(target.x, target.z)):
				_roam_target = target
				_has_target = true
				return
		return
	if home_quarter == &"":
		home_quarter = _city.district_at(Vector2(home_position.x, home_position.z)).id
	if _node < 0:
		_node = _city.nearest_waypoint(Vector2(global_position.x, global_position.z))
		_previous_node = -1
	else:
		var next := _choose_next_node()
		_previous_node = _node
		_node = next
	if _node < 0:
		return
	var point := _city.waypoints[_node]
	var direction := Vector2.RIGHT
	var links := _city.waypoint_links[_node]
	if not links.is_empty():
		direction = (_city.waypoints[links[0]] - point).normalized()
	var side := direction.orthogonal() * _lane
	_roam_target = Vector3(point.x + side.x, global_position.y, point.y + side.y)
	_has_target = true


## Nächster Wegpunkt: meist im eigenen Viertel, selten woanders hin. Wer sich
## verlaufen hat, läuft wieder nach Hause.
func _choose_next_node() -> int:
	var links := _city.waypoint_links[_node]
	if links.is_empty():
		return _node
	var options: Array[int] = []
	for link in links:
		if link != _previous_node or links.size() == 1:
			options.append(link)
	var at_home := _city.waypoint_districts[_node] == home_quarter
	if not at_home and _roam_rng.randf() < 0.85:
		# Nach Hause: der Nachbar, der der Viertelmitte am nächsten ist.
		var home := _city.get_district_center(home_quarter)
		var best := options[0]
		for option in options:
			if _city.waypoints[option].distance_to(home) < _city.waypoints[best].distance_to(home):
				best = option
		return best
	var home_options: Array[int] = []
	for option in options:
		if _city.waypoint_districts[option] == home_quarter:
			home_options.append(option)
	if not home_options.is_empty() and _roam_rng.randf() < home_loyalty:
		return home_options[_roam_rng.randi() % home_options.size()]
	return options[_roam_rng.randi() % options.size()]


## Für Unterklassen: das Gespräch. Immer `await dialogue.ask(...)` benutzen.
func talk(_player: Player, dialogue: DialogueBox) -> void:
	await dialogue.ask(display_name, "…")


func is_talking() -> bool:
	return _talking


func is_fleeing() -> bool:
	return _flee_time_left > 0.0


## Für Unterklassen: wird beim Tod aufgerufen (z. B. Mission scheitern lassen).
func _on_death() -> void:
	pass


func _on_hit_received(hit: HitData, result: Hurtbox.Result) -> void:
	if result == Hurtbox.Result.IGNORED or health.is_dead:
		return
	_material.albedo_color = Color.WHITE
	create_tween().tween_property(_material, "albedo_color", body_color, 0.2)
	BloodEffect.spawn(self, hit.direction, clampf(hit.damage / 15.0, 0.6, 2.0))
	_flee_time_left = flee_time
	_flee_from = hit.source.global_position if hit.source else global_position
	_shout("Hilfe!")
	if _last_hit_by_player:
		GameState.moral.record(StringName("hurt_%s" % npc_id), &"mercy", -3,
			"%s ohne Grund angegriffen" % display_name)


func _on_died() -> void:
	GameState.dead_npcs.append(npc_id)
	if _last_hit_by_player:
		GameState.moral.record(StringName("killed_%s" % npc_id), &"protection", -10,
			"%s getötet" % display_name)
	_on_death()
	talk_area.set_deferred(&"monitorable", false)
	hurtbox.set_deferred(&"monitorable", false)
	name_label.visible = false
	var tween := create_tween()
	tween.tween_property(model, "rotation:x", deg_to_rad(-90.0), 0.5)
	tween.tween_interval(2.0)
	tween.tween_callback(queue_free)


## Kurzer Ausruf über dem Kopf.
func _shout(text: String) -> void:
	var label := Label3D.new()
	label.text = text
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.font_size = 40
	label.outline_size = 8
	label.modulate = Color(1.0, 0.6, 0.5)
	add_child(label)
	label.position = Vector3(0.0, 2.5, 0.0)
	var tween := label.create_tween()
	tween.tween_property(label, "position:y", 3.0, 1.0)
	tween.tween_callback(label.queue_free)


## Läuft in Richtung eines Ziels (flach), dreht sich dabei.
func walk_towards(target: Vector3, speed: float, delta: float) -> void:
	var offset := target - global_position
	offset.y = 0.0
	var desired := offset.normalized() * speed if offset.length() > 0.1 else Vector3.ZERO
	var horizontal := Vector3(velocity.x, 0.0, velocity.z).move_toward(desired, 10.0 * delta)
	velocity.x = horizontal.x
	velocity.z = horizontal.z
	if desired != Vector3.ZERO:
		rotation.y = lerp_angle(rotation.y, atan2(-desired.x, -desired.z), 1.0 - exp(-8.0 * delta))


func _on_talk_requested(player: Player) -> void:
	if _talking or health.is_dead:
		return
	if is_fleeing():
		_shout("Bleib weg!")
		return
	var dialogue := get_tree().get_first_node_in_group(&"dialogue_box") as DialogueBox
	if dialogue == null:
		return
	_talking = true
	var to_player := player.global_position - global_position
	rotation.y = atan2(-to_player.x, -to_player.z)
	await talk(player, dialogue)
	dialogue.finish()
	_talking = false

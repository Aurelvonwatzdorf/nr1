class_name CrowdBackdrop
extends MultiMeshInstance3D
## Kulissen-Passanten (Mechanik-Studie 2, „viele Figuren günstig“): viele Leute
## als **ein** MultiMesh (ein Zeichenaufruf), ohne Physik, Gespräche oder
## Trefferflächen. Sie laufen über das Wegenetz der Stadt, meist in ihrem Viertel
## und in dessen Farben. In der Nähe der Spielfigur sind sie ausgeblendet; dort
## laufen nur echte Bürger (`Citizen`). Bei Schüssen hasten sie davon.
## Anzahl je Grafikstufe (`GraphicsSettings`).

const COUNT_BY_TIER: Array[int] = [60, 120, 200]
## Ausgeblendet näher als das (echte Bürger übernehmen) und weiter als das.
const HIDE_NEAR := 14.0
const HIDE_FAR := 160.0
## Bewegung wird nur jeden n-ten Physik-Frame neu gesetzt.
const UPDATE_EVERY := 2
const WALK_SPEED := 1.3
const FLEE_SPEED := 4.5
const FLEE_RADIUS := 25.0
const FLEE_TIME := 6.0

var city: CityGenerator
var _rng := RandomNumberGenerator.new()
## Je Person: Position, Ziel-Wegpunkt, vorheriger Wegpunkt, Seitenversatz,
## Tempo-Faktor, Viertel, Restzeit des Fliehens.
var _positions: PackedVector2Array = PackedVector2Array()
var _targets: PackedInt32Array = PackedInt32Array()
var _previous: PackedInt32Array = PackedInt32Array()
var _lanes: PackedFloat32Array = PackedFloat32Array()
var _speeds: PackedFloat32Array = PackedFloat32Array()
var _quarters: Array[StringName] = []
var _flee_left: PackedFloat32Array = PackedFloat32Array()
var _frame: int = 0


func setup(city_generator: CityGenerator, seed: int) -> void:
	city = city_generator
	_rng.seed = seed


func _ready() -> void:
	name = "CrowdBackdrop"
	if city == null or city.waypoints.is_empty():
		return
	var total: int = COUNT_BY_TIER[COUNT_BY_TIER.size() - 1]
	var mesh := CapsuleMesh.new()
	mesh.radius = 0.28
	mesh.height = 1.7
	var material := ToonStyle.make(Color.WHITE, false)
	material.vertex_color_use_as_albedo = true
	mesh.material = material
	multimesh = MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.use_colors = true
	multimesh.mesh = mesh
	multimesh.instance_count = total
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# Die Leute verteilen sich über die ganze Stadt.
	custom_aabb = AABB(Vector3(-2000.0, -10.0, -2000.0), Vector3(4000.0, 30.0, 4000.0))
	for i in total:
		var node := _rng.randi() % city.waypoints.size()
		var quarter: StringName = city.waypoint_districts[node]
		_quarters.append(quarter)
		_positions.append(city.waypoints[node] + Vector2(_rng.randf_range(-2.0, 2.0), _rng.randf_range(-2.0, 2.0)))
		_previous.append(-1)
		_targets.append(_next_node(node, -1, quarter))
		_lanes.append(_rng.randf_range(-1.5, 1.5))
		_speeds.append(_rng.randf_range(0.8, 1.25))
		_flee_left.append(0.0)
		var colors: Array = Citizen.COLORS.get(quarter, Citizen.COLORS[&"market"])
		multimesh.set_instance_color(i, colors[_rng.randi() % colors.size()])
	_apply_tier(GraphicsSettings.tier)
	GraphicsSettings.tier_changed.connect(_apply_tier)
	EventBus.shot_fired.connect(_on_shot_fired)
	_update_transforms()


func get_active_count() -> int:
	return multimesh.visible_instance_count if multimesh else 0


func _apply_tier(tier: int) -> void:
	if multimesh:
		multimesh.visible_instance_count = mini(COUNT_BY_TIER[clampi(tier, 0, COUNT_BY_TIER.size() - 1)], multimesh.instance_count)


func _physics_process(delta: float) -> void:
	if multimesh == null:
		return
	_frame += 1
	if _frame % UPDATE_EVERY != 0:
		return
	var step := delta * UPDATE_EVERY * GameState.world_time_scale
	if GameState.time_stopped:
		step = 0.0
	for i in multimesh.visible_instance_count:
		_walk(i, step)
	_update_transforms()


func _walk(i: int, step: float) -> void:
	var target_node := _targets[i]
	var target := city.waypoints[target_node] + _lane_offset(i, target_node)
	var offset := target - _positions[i]
	var fleeing := _flee_left[i] > 0.0
	if fleeing:
		_flee_left[i] -= step
	var speed := (FLEE_SPEED if fleeing else WALK_SPEED) * _speeds[i]
	if offset.length() <= speed * step + 0.3:
		_positions[i] = target
		var next := _next_node(target_node, _previous[i], _quarters[i])
		_previous[i] = target_node
		_targets[i] = next
		return
	_positions[i] += offset.normalized() * speed * step


func _lane_offset(i: int, node: int) -> Vector2:
	var links := city.waypoint_links[node]
	if links.is_empty():
		return Vector2.ZERO
	var direction := (city.waypoints[links[0]] - city.waypoints[node]).normalized()
	return direction.orthogonal() * _lanes[i]


## Nächster Wegpunkt: nicht zurück, meist im eigenen Viertel.
func _next_node(node: int, previous: int, quarter: StringName) -> int:
	var links := city.waypoint_links[node]
	if links.is_empty():
		return node
	var options: Array[int] = []
	var home: Array[int] = []
	for link in links:
		if link == previous and links.size() > 1:
			continue
		options.append(link)
		if city.waypoint_districts[link] == quarter:
			home.append(link)
	if not home.is_empty() and _rng.randf() < 0.85:
		return home[_rng.randi() % home.size()]
	return options[_rng.randi() % options.size()]


func _update_transforms() -> void:
	var player := get_tree().get_first_node_in_group(&"player") as Node3D
	var player_at := Vector2(player.global_position.x, player.global_position.z) if player else Vector2(INF, INF)
	var hidden := Transform3D(Basis().scaled(Vector3.ZERO), Vector3.ZERO)
	for i in multimesh.visible_instance_count:
		var at := _positions[i]
		var distance := at.distance_to(player_at)
		if distance < HIDE_NEAR or distance > HIDE_FAR:
			multimesh.set_instance_transform(i, hidden)
			continue
		var target := city.waypoints[_targets[i]]
		var facing := target - at
		var basis := Basis(Vector3.UP, atan2(-facing.x, -facing.y)) if facing.length_squared() > 0.01 else Basis()
		multimesh.set_instance_transform(i, Transform3D(basis, Vector3(at.x, 0.85, at.y)))


## Schüsse: Leute im Umkreis hasten davon.
func _on_shot_fired(from: Vector3) -> void:
	var at := Vector2(from.x, from.z)
	for i in multimesh.visible_instance_count:
		if _positions[i].distance_to(at) <= FLEE_RADIUS:
			_flee_left[i] = FLEE_TIME

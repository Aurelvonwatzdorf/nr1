class_name ContinentLandmarks
extends RefCounted
## Baut die Wahrzeichen der Regionen aus einfachen Formen (Platzhalter im
## gezeichneten Look, bis echte Modelle kommen). Jedes Wahrzeichen bekommt einen
## Kartenmarker und hängt unter dem Knoten seiner Region (für das Entdecken).

const ANCHOR_SCENE := preload("res://scenes/world/anchor_mirror.tscn")
const SHRINE_SCENE := preload("res://scenes/world/spirit_shrine.tscn")
const TALKER_SCENE := preload("res://scenes/npcs/talker.tscn")
const CITY_SCENE := "res://scenes/levels/santo_santiago.tscn"

var gen: ContinentGenerator
var _materials: Dictionary[Color, StandardMaterial3D] = {}
var _glows: Dictionary[Color, StandardMaterial3D] = {}
var _rng := RandomNumberGenerator.new()


func _init(generator: ContinentGenerator) -> void:
	gen = generator
	_rng.seed = generator.layout.seed + 99


func build(landmark: Dictionary) -> void:
	var region_id: StringName = landmark["region"]
	var region_root := _region_root(region_id)
	var pos: Vector2 = landmark["pos"]
	var root := Node3D.new()
	root.name = "%s_%d" % [landmark["kind"], region_root.get_child_count()]
	root.position = gen.ground(pos)
	region_root.add_child(root)
	var builder := Callable(self, "_build_%s" % landmark["kind"])
	if builder.is_valid():
		builder.call(root, landmark)
	if landmark["kind"] in [&"village", &"ger_camp", &"mountain_village", &"river_village", &"suburb", &"outpost", &"anchor_mirror"]:
		_spawn_people(region_id, root, landmark)


func _region_root(id: StringName) -> Node3D:
	if gen.region_roots.has(id):
		return gen.region_roots[id]
	var root := Node3D.new()
	root.name = "Region_%s" % id
	gen.add_child(root)
	gen.region_roots[id] = root
	return root


# --- Bausteine -----------------------------------------------------------

func _mat(color: Color) -> StandardMaterial3D:
	if not _materials.has(color):
		_materials[color] = ToonStyle.make(color)
	return _materials[color]


func _glow(color: Color, energy: float = 1.5) -> StandardMaterial3D:
	if not _glows.has(color):
		var material := ToonStyle.make(color, false)
		material.emission_enabled = true
		material.emission = color
		material.emission_energy_multiplier = energy
		_glows[color] = material
	return _glows[color]


func _add(root: Node3D, mesh: Mesh, at: Vector3, material: Material, solid: bool, rotation: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.material_override = material
	instance.position = at
	instance.rotation = rotation
	if solid:
		var body := StaticBody3D.new()
		body.collision_layer = PhysicsLayers.WORLD
		body.collision_mask = 0
		var shape := CollisionShape3D.new()
		shape.shape = mesh.create_convex_shape() if not mesh is BoxMesh else _box_shape((mesh as BoxMesh).size)
		body.add_child(shape)
		instance.add_child(body)
	root.add_child(instance)
	gen.mesh_count += 1
	return instance


func _box_shape(size: Vector3) -> BoxShape3D:
	var shape := BoxShape3D.new()
	shape.size = size
	return shape


func box(root: Node3D, size: Vector3, at: Vector3, color: Color, solid: bool = true, rotation: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	return _add(root, mesh, at, _mat(color), solid, rotation)


func cylinder(root: Node3D, top: float, bottom: float, height: float, at: Vector3, color: Color, solid: bool = true, segments: int = 12) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = top
	mesh.bottom_radius = bottom
	mesh.height = height
	mesh.radial_segments = segments
	mesh.rings = 1
	return _add(root, mesh, at, _mat(color), solid)


func sphere(root: Node3D, radius: float, at: Vector3, material: Material, hemisphere: bool = false) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius if hemisphere else radius * 2.0
	mesh.is_hemisphere = hemisphere
	mesh.radial_segments = 16
	mesh.rings = 8
	return _add(root, mesh, at, material, false)


## Dreieckiges Dach (liegendes Prisma) entlang der x-Achse.
func gable(root: Node3D, length: float, width: float, height: float, at: Vector3, color: Color, rot_y: float = 0.0) -> MeshInstance3D:
	var mesh := PrismMesh.new()
	mesh.size = Vector3(width, height, length)
	return _add(root, mesh, at, _mat(color), true, Vector3(0, rot_y + PI / 2.0, 0))


func pyramid(root: Node3D, side: float, height: float, at: Vector3, color: Color, solid: bool = true) -> MeshInstance3D:
	var instance := cylinder(root, 0.0, side / sqrt(2.0), height, at, color, solid, 4)
	instance.rotation.y = PI / 4.0
	return instance


func marker(root: Node3D, kind: MapMarker.Kind, label: String) -> void:
	var map_marker := MapMarker.new()
	map_marker.kind = kind
	map_marker.label = label
	root.add_child(map_marker)


func sign_text(root: Node3D, text: String, at: Vector3, color: Color = Color(1, 0.95, 0.85)) -> void:
	var label := Label3D.new()
	label.text = text
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.font_size = 64
	label.outline_size = 12
	label.modulate = color
	label.position = at
	root.add_child(label)


## Etwas, das man mit E betrachten kann (zeigt eine Meldung).
func inspect_point(root: Node3D, at: Vector3, prompt: String, text: String) -> void:
	var area := Interactable.new()
	area.prompt = prompt
	var shape := CollisionShape3D.new()
	var sphere_shape := SphereShape3D.new()
	sphere_shape.radius = 3.0
	shape.shape = sphere_shape
	area.add_child(shape)
	area.position = at
	area.interacted.connect(func(_player: Player) -> void: EventBus.message_requested.emit(text))
	root.add_child(area)


## Bodenhöhe relativ zum Wurzelknoten (für Teile, die nicht auf der Mitte stehen).
func local_ground(root: Node3D, local: Vector2) -> float:
	var world := root.global_transform * Vector3(local.x, 0, local.y)
	return gen.get_height(world.x, world.z) - root.position.y


func _spawn_people(region_id: StringName, root: Node3D, landmark: Dictionary) -> void:
	var region := gen.get_region(region_id)
	if region == null or region.npc_count <= 0 or region.npc_lines.is_empty():
		return
	var count := 1 if landmark["kind"] == &"anchor_mirror" else maxi(1, region.npc_count / 2)
	var radius: float = landmark["radius"]
	for n in count:
		var talker := TALKER_SCENE.instantiate() as Talker
		var index := root.get_index() * 10 + n
		talker.npc_id = StringName("wanderer_%s_%d" % [region_id, index])
		talker.display_name = region.npc_names[(index) % region.npc_names.size()] if not region.npc_names.is_empty() else "Wanderer"
		talker.body_color = region.npc_colors[index % region.npc_colors.size()] if not region.npc_colors.is_empty() else Color(0.6, 0.55, 0.5)
		var lines: Array[String] = []
		for k in region.npc_lines.size():
			lines.append(region.npc_lines[(k + index) % region.npc_lines.size()])
		talker.lines = lines
		talker.roam = NPC.Roam.NEAR_HOME
		talker.roam_radius = 5.0
		var angle := _rng.randf_range(0.0, TAU)
		var spot: Vector2 = Vector2(root.position.x, root.position.z) + Vector2.from_angle(angle) * minf(radius * 0.6, 14.0)
		talker.position = gen.ground(spot, 0.3)
		gen.region_roots[region_id].add_child(talker)


# --- Santo Santiago (von außen) --------------------------------------------

func _build_city(root: Node3D, _landmark: Dictionary) -> void:
	var wall_color := Color(0.3, 0.3, 0.36)
	var segments := 64
	for i in segments:
		var angle := TAU * (float(i) + 0.5) / segments
		var dir := Vector2.from_angle(angle)
		# Lücke für das Südtor (Süden = +z, also Winkel π/2).
		if absf(angle_difference(angle, PI / 2.0)) < 0.05:
			continue
		var at := dir * 205.0
		box(root, Vector3(21.0, 14.0, 3.0), Vector3(at.x, 7.0, at.y), wall_color, true, Vector3(0, -angle + PI / 2.0, 0))
	for i in 16:
		var at := Vector2.from_angle(TAU * i / 16.0) * 205.0
		cylinder(root, 4.0, 4.5, 20.0, Vector3(at.x, 10.0, at.y), wall_color.darkened(0.15), true, 8)
		sphere(root, 1.0, Vector3(at.x, 21.0, at.y), _glow(Color(1.0, 0.3, 0.6)))
	# Skyline: reich im Norden (hohe Türme), arm im Süden.
	var neon: Array[Color] = [Color(1.0, 0.3, 0.6), Color(0.3, 0.9, 1.0), Color(0.7, 0.4, 1.0), Color(1.0, 0.7, 0.3)]
	for i in 70:
		var angle := _rng.randf_range(0.0, TAU)
		var r := sqrt(_rng.randf()) * 175.0 + 15.0
		var at := Vector2.from_angle(angle) * r
		var north := clampf(-at.y / 180.0, -0.6, 1.0)
		var height := _rng.randf_range(18.0, 40.0) + maxf(north, 0.0) * _rng.randf_range(40.0, 110.0)
		var width := _rng.randf_range(10.0, 20.0)
		var tower := box(root, Vector3(width, height, width), Vector3(at.x, height / 2.0, at.y),
			Color(0.22, 0.22, 0.28).lerp(Color(0.35, 0.33, 0.4), _rng.randf()), false, Vector3(0, _rng.randf_range(0, PI), 0))
		var stripe := BoxMesh.new()
		stripe.size = Vector3(width + 0.3, 0.8, width + 0.3)
		for k in int(height / 14.0):
			var light := MeshInstance3D.new()
			light.mesh = stripe
			light.material_override = _glow(neon[(i + k) % neon.size()], 1.2)
			light.position = Vector3(0, -height / 2.0 + 8.0 + k * 14.0, 0)
			tower.add_child(light)
	# Die Zitadelle der Konzerne, von überall zu sehen.
	box(root, Vector3(26, 170, 26), Vector3(0, 85, -130), Color(0.18, 0.18, 0.24), false)
	cylinder(root, 0.6, 6.0, 50.0, Vector3(0, 195, -130), Color(0.25, 0.25, 0.3), false, 8)
	sphere(root, 3.0, Vector3(0, 222, -130), _glow(Color(1.0, 0.25, 0.3), 3.0))
	# Südtor: hinein in die Stadt.
	var gate := TravelGate.new()
	gate.name = "CityGate"
	gate.prompt = "Santo Santiago betreten"
	gate.target_scene = CITY_SCENE
	gate.target_position = Vector3(2, 0.3, 150)
	gate.target_yaw_degrees = 0.0
	gate.arrival_message = "Santo Santiago"
	gate.position = Vector3(0, 0, 207)
	root.add_child(gate)
	marker(gate, MapMarker.Kind.CITY_GATE, "Südtor von Santo Santiago")
	sign_text(root, "SANTO SANTIAGO", Vector3(0, 12.0, 212), Color(0.7, 0.85, 1.0))


func _build_anchor_mirror(root: Node3D, landmark: Dictionary) -> void:
	var mirror := ANCHOR_SCENE.instantiate() as Node3D
	mirror.name = "AnchorMirror"
	var region := gen.get_region(landmark["region"])
	var to_center := region.center - Vector2(root.position.x, root.position.z)
	mirror.rotation.y = atan2(to_center.x, to_center.y) + PI
	root.add_child(mirror)


# --- Die Narbe ------------------------------------------------------------

func _build_drill_rig(root: Node3D, _landmark: Dictionary) -> void:
	var steel := Color(0.38, 0.33, 0.3)
	box(root, Vector3(12, 1.0, 12), Vector3(0, 0.5, 0), Color(0.22, 0.2, 0.2))
	for corner: Vector2 in [Vector2(-3, -3), Vector2(3, -3), Vector2(-3, 3), Vector2(3, 3)]:
		box(root, Vector3(0.6, 30, 0.6), Vector3(corner.x, 15.5, corner.y), steel)
	for k in 5:
		var y := 4.0 + k * 6.0
		box(root, Vector3(6.6, 0.4, 0.4), Vector3(0, y, -3), steel, false)
		box(root, Vector3(6.6, 0.4, 0.4), Vector3(0, y, 3), steel, false)
		box(root, Vector3(0.4, 0.4, 6.6), Vector3(-3, y, 0), steel, false)
		box(root, Vector3(0.4, 0.4, 6.6), Vector3(3, y, 0), steel, false)
	cylinder(root, 0.5, 0.5, 34.0, Vector3(0, 14.0, 0), Color(0.2, 0.2, 0.22), false, 8)
	sphere(root, 0.8, Vector3(0, 31.5, 0), _glow(Color(1.0, 0.15, 0.1), 3.0))
	marker(root, MapMarker.Kind.LANDMARK, "Bohrturm")


func _build_outpost(root: Node3D, _landmark: Dictionary) -> void:
	for i in 28:
		var angle := TAU * i / 28.0
		if i == 7:
			continue
		var at := Vector2.from_angle(angle) * 20.0
		box(root, Vector3(4.4, 3.0, 0.2), Vector3(at.x, local_ground(root, at) + 1.5, at.y), Color(0.3, 0.3, 0.33), true, Vector3(0, -angle + PI / 2.0, 0))
	var container_colors: Array[Color] = [Color(0.6, 0.2, 0.18), Color(0.2, 0.35, 0.5), Color(0.55, 0.45, 0.2)]
	for i in 4:
		var at := Vector2(-8 + (i % 2) * 14, -6 + (i / 2) * 10)
		box(root, Vector3(10, 3, 3.2), Vector3(at.x, 1.5, at.y), container_colors[i % 3])
	box(root, Vector3(6, 2, 0.3), Vector3(0, 6, -12), Color(0.1, 0.1, 0.12), false)
	box(root, Vector3(5.6, 1.6, 0.35), Vector3(0, 6, -12), Color(0.1, 0.1, 0.12), false).material_override = _glow(Color(1.0, 0.2, 0.25), 2.0)
	marker(root, MapMarker.Kind.CORPORATE_TOWER, "Konzern-Außenposten")


# --- Kagerō-Gebirge -------------------------------------------------------

func _torii(root: Node3D, at: Vector3, rot_y: float, scale: float = 1.0) -> void:
	var red := Color(0.72, 0.16, 0.12)
	var gate := Node3D.new()
	gate.position = at
	gate.rotation.y = rot_y
	root.add_child(gate)
	for side: float in [-1.0, 1.0]:
		cylinder(gate, 0.3 * scale, 0.35 * scale, 5.0 * scale, Vector3(side * 2.2 * scale, 2.5 * scale, 0), red, true, 8)
	box(gate, Vector3(6.4, 0.45, 0.6) * scale, Vector3(0, 5.2 * scale, 0), Color(0.12, 0.1, 0.1), false)
	box(gate, Vector3(5.2, 0.3, 0.4) * scale, Vector3(0, 4.3 * scale, 0), red, false)


func _build_mountain_temple(root: Node3D, landmark: Dictionary) -> void:
	var wood := Color(0.55, 0.16, 0.12)
	var roof := Color(0.2, 0.2, 0.24)
	var stone := Color(0.55, 0.55, 0.52)
	box(root, Vector3(46, 1.6, 34), Vector3(0, 0.8, 0), stone)
	# Haupthalle mit roten Säulen und doppeltem Dach.
	box(root, Vector3(18, 7, 12), Vector3(0, 5.1, -4), Color(0.85, 0.8, 0.7))
	for x in [-8.0, -4.0, 0.0, 4.0, 8.0]:
		cylinder(root, 0.4, 0.4, 7.0, Vector3(x, 5.1, 2.3), wood, false, 8)
	box(root, Vector3(24, 1.0, 17), Vector3(0, 9.2, -4), roof, false)
	box(root, Vector3(16, 1.0, 11), Vector3(0, 11.4, -4), roof, false)
	box(root, Vector3(18, 0.6, 1.0), Vector3(0, 12.2, -4), roof.darkened(0.2), false)
	# Versiegeltes Tor (Ritualort, M8.5).
	var seal := sphere(root, 1.4, Vector3(0, 5.0, 2.6), _glow(Color(0.95, 0.75, 0.35), 2.0))
	seal.scale = Vector3(1, 1, 0.2)
	inspect_point(root, Vector3(0, 2.5, 5.0), "Das versiegelte Tor betrachten",
		"Ein Siegel aus Licht verschließt das Tor. Es heißt, nur ein Ritual mit den richtigen Gaben öffnet es.")
	# Pagode mit fünf Dächern.
	for k in 5:
		var size := 9.0 - k * 1.3
		var y := 1.6 + k * 5.0
		box(root, Vector3(size * 0.7, 4.0, size * 0.7), Vector3(15, y + 2.0, -8), Color(0.82, 0.78, 0.68), k == 0)
		box(root, Vector3(size + 2.5, 0.6, size + 2.5), Vector3(15, y + 4.2, -8), roof, false)
	cylinder(root, 0.1, 0.25, 4.0, Vector3(15, 28.5, -8), Color(0.8, 0.65, 0.3), false, 6)
	# Steinlaternen am Eingang.
	for x in [-6.0, 6.0]:
		box(root, Vector3(0.8, 2.0, 0.8), Vector3(x, 2.6, 12), stone)
		box(root, Vector3(1.4, 0.9, 1.4), Vector3(x, 4.0, 12), stone, false)
		sphere(root, 0.35, Vector3(x, 4.0, 12), _glow(Color(1.0, 0.75, 0.4)))
	# Torii-Weg: Torbögen entlang des Serpentinenwegs hinauf.
	var goal: Vector2 = landmark["pos"]
	for path in gen.layout.roads:
		if path[path.size() - 1].distance_to(goal) > 20.0:
			continue
		var walked := 0.0
		var next_gate := 20.0
		for i in path.size() - 1:
			var length := path[i].distance_to(path[i + 1])
			while next_gate < walked + length and next_gate < _path_length(path) - 30.0:
				var p := path[i].lerp(path[i + 1], (next_gate - walked) / length)
				var dir := (path[i + 1] - path[i]).normalized()
				_torii(root, gen.ground(p) - root.position, atan2(dir.x, dir.y), 1.0)
				next_gate += 32.0
			walked += length
	marker(root, MapMarker.Kind.MOUNTAIN_TEMPLE, "Bergtempel von Kagerō")


func _path_length(path: PackedVector2Array) -> float:
	var length := 0.0
	for i in path.size() - 1:
		length += path[i].distance_to(path[i + 1])
	return length


func _build_mountain_village(root: Node3D, _landmark: Dictionary) -> void:
	for i in 5:
		var angle := TAU * i / 5.0 + 0.3
		var at := Vector2.from_angle(angle) * 18.0
		var y := local_ground(root, at)
		box(root, Vector3(7, 3.5, 5), Vector3(at.x, y + 1.75, at.y), Color(0.55, 0.38, 0.24), true, Vector3(0, -angle, 0))
		box(root, Vector3(9, 0.6, 7), Vector3(at.x, y + 3.9, at.y), Color(0.25, 0.25, 0.28), false, Vector3(0, -angle, 0))
	_torii(root, Vector3(0, 0, 0), 0.0, 0.8)
	marker(root, MapMarker.Kind.SETTLEMENT, "Bergdorf")


func _build_shrine(root: Node3D, _landmark: Dictionary) -> void:
	box(root, Vector3(6, 0.6, 6), Vector3(0, 0.3, 0), Color(0.5, 0.5, 0.48))
	box(root, Vector3(3, 3, 3), Vector3(0, 2.1, -1), Color(0.6, 0.3, 0.2))
	gable(root, 4.0, 4.4, 1.6, Vector3(0, 4.4, -1), Color(0.22, 0.22, 0.25))
	_torii(root, Vector3(0, 0, 5), 0.0, 0.7)
	marker(root, MapMarker.Kind.LANDMARK, "Wegschrein")


# --- Die Ewige Steppe -------------------------------------------------------

func _build_ger_camp(root: Node3D, _landmark: Dictionary) -> void:
	var bands: Array[Color] = [Color(0.7, 0.2, 0.18), Color(0.2, 0.35, 0.65), Color(0.8, 0.6, 0.2)]
	for i in 5:
		var angle := TAU * i / 5.0
		var at := Vector2.from_angle(angle) * 14.0
		var y := local_ground(root, at)
		cylinder(root, 3.2, 3.2, 2.4, Vector3(at.x, y + 1.2, at.y), Color(0.9, 0.88, 0.8))
		cylinder(root, 0.6, 3.6, 1.6, Vector3(at.x, y + 3.2, at.y), Color(0.88, 0.85, 0.78), false)
		cylinder(root, 3.25, 3.25, 0.3, Vector3(at.x, y + 2.2, at.y), bands[i % bands.size()], false)
		var door := Vector2.from_angle(angle) * 3.2
		box(root, Vector3(1.2, 1.8, 0.3), Vector3(at.x + door.x * -1.0 + door.x, y + 0.9, at.y + door.y), Color(0.85, 0.45, 0.15), false, Vector3(0, -angle + PI / 2.0, 0))
	cylinder(root, 1.2, 1.4, 0.4, Vector3(0, 0.2, 0), Color(0.25, 0.22, 0.2), false)
	sphere(root, 0.5, Vector3(0, 0.6, 0), _glow(Color(1.0, 0.55, 0.2), 2.0))
	marker(root, MapMarker.Kind.SETTLEMENT, "Jurtenlager")


func _build_ovoo(root: Node3D, _landmark: Dictionary) -> void:
	cylinder(root, 0.6, 3.0, 3.0, Vector3(0, 1.5, 0), Color(0.48, 0.46, 0.44), true, 9)
	cylinder(root, 0.08, 0.1, 5.0, Vector3(0, 5.0, 0), Color(0.45, 0.35, 0.25), false, 6)
	for k in 6:
		var angle := TAU * k / 6.0
		var dir := Vector3(cos(angle), 0, sin(angle))
		box(root, Vector3(0.25, 1.6, 0.05), Vector3(0, 6.4, 0) + dir * 0.35, Color(0.25, 0.5, 0.85), false, Vector3(0, -angle, 0.25))
	inspect_point(root, Vector3(0, 1.0, 3.5), "Einen Stein dazulegen",
		"Du legst einen Stein auf den Hügel und gehst dreimal herum. Der Wind lässt die blauen Tücher flattern.")
	marker(root, MapMarker.Kind.LANDMARK, "Steinhügel")


func _build_deer_stones(root: Node3D, _landmark: Dictionary) -> void:
	for i in 5:
		var x := -8.0 + i * 4.0
		box(root, Vector3(0.9, 3.6, 0.45), Vector3(x, local_ground(root, Vector2(x, 0)) + 1.8, 0), Color(0.5, 0.5, 0.52), true, Vector3(0, 0, _rng.randf_range(-0.05, 0.05)))
	marker(root, MapMarker.Kind.LANDMARK, "Hirschsteine")


# --- Grauwald-Mark ---------------------------------------------------------

func _build_castle(root: Node3D, _landmark: Dictionary) -> void:
	var stone := Color(0.55, 0.53, 0.5)
	var roof := Color(0.2, 0.25, 0.42)
	box(root, Vector3(50, 10, 2), Vector3(0, 5, -25), stone)
	box(root, Vector3(2, 10, 50), Vector3(-25, 5, 0), stone)
	box(root, Vector3(2, 10, 50), Vector3(25, 5, 0), stone)
	box(root, Vector3(20, 10, 2), Vector3(-15, 5, 25), stone)
	box(root, Vector3(20, 10, 2), Vector3(15, 5, 25), stone)
	for corner: Vector2 in [Vector2(-25, -25), Vector2(25, -25), Vector2(-25, 25), Vector2(25, 25)]:
		cylinder(root, 4.0, 4.0, 16.0, Vector3(corner.x, 8.0, corner.y), stone.darkened(0.08), true, 10)
		cylinder(root, 0.0, 5.0, 6.0, Vector3(corner.x, 19.0, corner.y), roof, false, 10)
	box(root, Vector3(16, 24, 16), Vector3(0, 12, -6), stone.lightened(0.05))
	pyramid(root, 18.0, 8.0, Vector3(0, 28, -6), roof, false)
	for x in [-6.0, 6.0]:
		box(root, Vector3(0.15, 6, 0.15), Vector3(x, 27, -15), Color(0.3, 0.25, 0.2), false)
		box(root, Vector3(2.2, 1.4, 0.05), Vector3(x + 1.1, 29, -15), Color(0.6, 0.15, 0.15), false)
	marker(root, MapMarker.Kind.LANDMARK, "Burg Grauwald")


func _half_timber(root: Node3D, at: Vector2, rot: float, size: Vector3) -> void:
	var y := local_ground(root, at)
	var beam := Color(0.28, 0.2, 0.14)
	box(root, size, Vector3(at.x, y + size.y / 2.0, at.y), Color(0.9, 0.87, 0.78), true, Vector3(0, rot, 0))
	var house := Node3D.new()
	house.position = Vector3(at.x, y, at.y)
	house.rotation.y = rot
	root.add_child(house)
	for x in [-size.x / 2.0, 0.0, size.x / 2.0]:
		box(house, Vector3(0.3, size.y, 0.3), Vector3(x, size.y / 2.0, size.z / 2.0 + 0.05), beam, false)
	box(house, Vector3(size.x, 0.3, 0.3), Vector3(0, size.y * 0.55, size.z / 2.0 + 0.05), beam, false)
	gable(house, size.x + 1.0, size.z + 1.2, 3.2, Vector3(0, size.y + 1.6, 0), Color(0.55, 0.25, 0.18))


func _build_village(root: Node3D, _landmark: Dictionary) -> void:
	for i in 7:
		var angle := TAU * i / 7.0
		var at := Vector2.from_angle(angle) * _rng.randf_range(20.0, 30.0)
		_half_timber(root, at, -angle + PI / 2.0, Vector3(8, 4.5, 6))
	cylinder(root, 1.4, 1.5, 1.0, Vector3(0, 0.5, 0), Color(0.5, 0.5, 0.48))
	box(root, Vector3(0.2, 2.6, 0.2), Vector3(-1.2, 1.3, 0), Color(0.35, 0.25, 0.18), false)
	box(root, Vector3(0.2, 2.6, 0.2), Vector3(1.2, 1.3, 0), Color(0.35, 0.25, 0.18), false)
	gable(root, 3.0, 2.0, 0.8, Vector3(0, 2.9, 0), Color(0.45, 0.25, 0.18))
	marker(root, MapMarker.Kind.SETTLEMENT, "Dorf Grauwald")


func _build_windmill(root: Node3D, _landmark: Dictionary) -> void:
	cylinder(root, 2.4, 3.5, 12.0, Vector3(0, 6.0, 0), Color(0.85, 0.82, 0.74), true, 10)
	cylinder(root, 0.0, 3.0, 3.0, Vector3(0, 13.5, 0), Color(0.45, 0.25, 0.18), false, 10)
	var sails := Node3D.new()
	sails.position = Vector3(0, 11.5, 3.0)
	root.add_child(sails)
	for k in 4:
		var blade := box(sails, Vector3(1.4, 9.0, 0.15), Vector3(0, 4.5, 0), Color(0.75, 0.7, 0.6), false)
		var arm := Node3D.new()
		arm.rotation.z = TAU * k / 4.0
		sails.add_child(arm)
		blade.reparent(arm, false)
	var tween := sails.create_tween().set_loops()
	tween.tween_property(sails, ^"rotation:z", TAU, 8.0).from(0.0)
	marker(root, MapMarker.Kind.LANDMARK, "Windmühle")


func _build_chapel(root: Node3D, _landmark: Dictionary) -> void:
	var stone := Color(0.78, 0.76, 0.7)
	box(root, Vector3(8, 6, 14), Vector3(0, 3, 0), stone)
	gable(root, 8.6, 15.0, 3.5, Vector3(0, 7.75, 0), Color(0.3, 0.3, 0.35), PI / 2.0)
	box(root, Vector3(4, 14, 4), Vector3(0, 7, -8), stone.darkened(0.05))
	pyramid(root, 5.0, 4.0, Vector3(0, 16, -8), Color(0.3, 0.3, 0.35), false)
	box(root, Vector3(0.25, 2.0, 0.25), Vector3(0, 19.0, -8), Color(0.75, 0.65, 0.35), false)
	box(root, Vector3(1.2, 0.25, 0.25), Vector3(0, 19.4, -8), Color(0.75, 0.65, 0.35), false)
	marker(root, MapMarker.Kind.CHURCH, "Kapelle von Grauwald")


# --- Nebelwald ----------------------------------------------------------------

func _build_spirit_shrine(root: Node3D, _landmark: Dictionary) -> void:
	var shrine := SHRINE_SCENE.instantiate() as SpiritualPressureSource
	shrine.name = "ForestShrine"
	shrine.required_spirituality = 5
	shrine.radius = 32.0
	shrine.source_name = "Das Herz des Nebelwalds"
	root.add_child(shrine)
	var shrine_marker := shrine.get_node_or_null("Marker") as MapMarker
	if shrine_marker:
		shrine_marker.label = "Herz des Nebelwalds"


func _build_stone_circle(root: Node3D, _landmark: Dictionary) -> void:
	for i in 10:
		var angle := TAU * i / 10.0
		var at := Vector2.from_angle(angle) * 12.0
		box(root, Vector3(1.4, 4.5, 0.9), Vector3(at.x, local_ground(root, at) + 2.2, at.y), Color(0.4, 0.42, 0.42), true, Vector3(0, -angle, 0))
		box(root, Vector3(0.5, 0.5, 0.1), Vector3(at.x * 0.93, local_ground(root, at) + 2.8, at.y * 0.93), Color.WHITE, false, Vector3(0, -angle + PI / 2.0, 0)).material_override = _glow(Color(0.4, 0.95, 0.85))
	marker(root, MapMarker.Kind.LANDMARK, "Steinkreis")


func _build_giant_tree(root: Node3D, _landmark: Dictionary) -> void:
	cylinder(root, 2.4, 4.0, 46.0, Vector3(0, 23.0, 0), Color(0.75, 0.78, 0.82), true, 12)
	for k in 6:
		var angle := TAU * k / 6.0
		var dir := Vector3(cos(angle), 0, sin(angle))
		box(root, Vector3(1.2, 1.6, 7.0), dir * 4.5 + Vector3(0, 0.6, 0), Color(0.7, 0.72, 0.76), false, Vector3(0, -angle + PI / 2.0, 0))
	var glow := _glow(Color(0.45, 0.95, 0.88), 1.4)
	sphere(root, 13.0, Vector3(0, 50, 0), glow)
	for k in 5:
		var angle := TAU * k / 5.0
		sphere(root, 8.0, Vector3(cos(angle) * 11.0, 44.0 + (k % 2) * 4.0, sin(angle) * 11.0), glow)
	var light := OmniLight3D.new()
	light.light_color = Color(0.5, 0.95, 0.9)
	light.light_energy = 3.0
	light.omni_range = 60.0
	light.position = Vector3(0, 40, 0)
	root.add_child(light)
	marker(root, MapMarker.Kind.LANDMARK, "Der Uralte")


# --- Sonnenreich Kemet ------------------------------------------------------

func _build_pyramid_great(root: Node3D, _landmark: Dictionary) -> void:
	pyramid(root, 80.0, 55.0, Vector3(0, 27.5, 0), Color(0.86, 0.75, 0.5))
	pyramid(root, 8.0, 5.5, Vector3(0, 52.3, 0), Color(0.95, 0.78, 0.3), false)
	marker(root, MapMarker.Kind.LANDMARK, "Große Pyramide")


func _build_pyramid(root: Node3D, _landmark: Dictionary) -> void:
	pyramid(root, 46.0, 32.0, Vector3(0, 16.0, 0), Color(0.84, 0.73, 0.5))
	marker(root, MapMarker.Kind.LANDMARK, "Pyramide")


func _build_pyramid_small(root: Node3D, _landmark: Dictionary) -> void:
	pyramid(root, 34.0, 24.0, Vector3(0, 12.0, 0), Color(0.82, 0.7, 0.48))


func _build_column_temple(root: Node3D, _landmark: Dictionary) -> void:
	var sand := Color(0.88, 0.8, 0.6)
	box(root, Vector3(30, 1.2, 22), Vector3(0, 0.6, 0), sand.darkened(0.08))
	for row: float in [-6.0, 6.0]:
		for k in 6:
			var x := -12.5 + k * 5.0
			cylinder(root, 0.9, 1.0, 10.0, Vector3(x, 6.2, row), sand, true, 10)
			box(root, Vector3(2.4, 1.0, 2.4), Vector3(x, 11.7, row), sand.darkened(0.05), false)
	box(root, Vector3(30, 1.2, 15), Vector3(0, 12.8, 0), sand.darkened(0.1), false)
	# Pylon-Tor vorne und zwei Obelisken.
	for side: float in [-1.0, 1.0]:
		cylinder(root, 3.0, 4.2, 14.0, Vector3(side * 6.5, 7.0, 15.0), sand, true, 4).rotation.y = PI / 4.0
		var obelisk_at := Vector3(side * 13.0, 7.0, 22.0)
		cylinder(root, 0.6, 1.0, 14.0, obelisk_at, Color(0.8, 0.7, 0.5), true, 4).rotation.y = PI / 4.0
		pyramid(root, 1.2, 1.4, obelisk_at + Vector3(0, 7.7, 0), Color(0.95, 0.78, 0.3), false)
	marker(root, MapMarker.Kind.LANDMARK, "Sonnentempel")


func _build_guardian_lion(root: Node3D, _landmark: Dictionary) -> void:
	var sand := Color(0.85, 0.74, 0.52)
	box(root, Vector3(12, 2, 6), Vector3(0, 1, 0), sand.darkened(0.12))
	box(root, Vector3(8, 3.2, 3.8), Vector3(-1.0, 3.6, 0), sand)
	box(root, Vector3(3.0, 3.6, 3.4), Vector3(3.8, 5.6, 0), sand.lightened(0.04))
	box(root, Vector3(3.6, 3.0, 4.4), Vector3(3.3, 5.8, 0), Color(0.3, 0.45, 0.6), false)
	for z in [-1.3, 1.3]:
		box(root, Vector3(3.5, 1.0, 1.0), Vector3(4.6, 2.5, z), sand, false)
	marker(root, MapMarker.Kind.LANDMARK, "Wächterlöwe")


func _build_river_village(root: Node3D, _landmark: Dictionary) -> void:
	for i in 6:
		var angle := TAU * i / 6.0
		var at := Vector2.from_angle(angle) * _rng.randf_range(12.0, 20.0)
		var y := local_ground(root, at)
		box(root, Vector3(6, 3.4, 5), Vector3(at.x, y + 1.7, at.y), Color(0.75, 0.62, 0.45), true, Vector3(0, -angle, 0))
		box(root, Vector3(6.4, 0.3, 5.4), Vector3(at.x, y + 3.5, at.y), Color(0.6, 0.48, 0.32), false, Vector3(0, -angle, 0))
	marker(root, MapMarker.Kind.SETTLEMENT, "Flussdorf")


# --- Neu-Vallis -------------------------------------------------------------

func _build_suburb(root: Node3D, _landmark: Dictionary) -> void:
	var walls: Array[Color] = [Color(0.85, 0.82, 0.7), Color(0.7, 0.78, 0.85), Color(0.85, 0.7, 0.65), Color(0.75, 0.8, 0.68)]
	box(root, Vector3(110, 0.15, 7), Vector3(0, 0.08, 0), Color(0.2, 0.2, 0.22), false)
	box(root, Vector3(7, 0.15, 90), Vector3(0, 0.09, 0), Color(0.2, 0.2, 0.22), false)
	for gx in 4:
		for gz in 3:
			var at := Vector2(-42.0 + gx * 28.0, -30.0 + gz * 30.0)
			if absf(at.x) < 10.0:
				at.x += 14.0 * signf(at.x + 0.01)
			var y := local_ground(root, at)
			var color := walls[(gx + gz) % walls.size()]
			box(root, Vector3(10, 4.5, 8), Vector3(at.x, y + 2.25, at.y), color)
			gable(root, 11.0, 9.0, 2.6, Vector3(at.x, y + 5.8, at.y), Color(0.35, 0.33, 0.35))
			box(root, Vector3(1.4, 2.2, 0.15), Vector3(at.x, y + 1.1, at.y + 4.05), Color(0.35, 0.25, 0.2), false)
	marker(root, MapMarker.Kind.SETTLEMENT, "Vorstadt Neu-Vallis")


func _build_gas_station(root: Node3D, _landmark: Dictionary) -> void:
	box(root, Vector3(16, 0.6, 9), Vector3(0, 5.2, 0), Color(0.85, 0.85, 0.88), false)
	box(root, Vector3(16.2, 0.4, 9.2), Vector3(0, 4.85, 0), Color(0.8, 0.15, 0.15), false)
	for corner: Vector2 in [Vector2(-6, -3), Vector2(6, -3), Vector2(-6, 3), Vector2(6, 3)]:
		box(root, Vector3(0.5, 5, 0.5), Vector3(corner.x, 2.5, corner.y), Color(0.75, 0.75, 0.78))
	for x in [-3.0, 3.0]:
		box(root, Vector3(0.9, 1.8, 0.6), Vector3(x, 0.9, 0), Color(0.85, 0.2, 0.2))
	box(root, Vector3(10, 4, 7), Vector3(0, 2, -10), Color(0.88, 0.88, 0.9))
	box(root, Vector3(6, 1.0, 0.3), Vector3(0, 3.4, -6.4), Color.WHITE, false).material_override = _glow(Color(1.0, 0.25, 0.2), 2.0)
	marker(root, MapMarker.Kind.LANDMARK, "Tankstelle")


func _build_radio_mast(root: Node3D, _landmark: Dictionary) -> void:
	var steel := Color(0.75, 0.3, 0.25)
	for k in 3:
		var angle := TAU * k / 3.0
		box(root, Vector3(0.3, 70, 0.3), Vector3(cos(angle) * 1.2, 35, sin(angle) * 1.2), steel, k == 0)
	for k in 14:
		cylinder(root, 1.3, 1.3, 0.2, Vector3(0, 4.0 + k * 5.0, 0), Color(0.85, 0.85, 0.85), false, 3)
	sphere(root, 0.7, Vector3(0, 71, 0), _glow(Color(1.0, 0.15, 0.1), 3.0))
	marker(root, MapMarker.Kind.LANDMARK, "Funkmast")


func _build_stadium(root: Node3D, _landmark: Dictionary) -> void:
	box(root, Vector3(50, 0.2, 32), Vector3(0, 0.1, 0), Color(0.3, 0.6, 0.3), false)
	for k in 28:
		var angle := TAU * k / 28.0
		var at := Vector2(cos(angle) * 34.0, sin(angle) * 24.0)
		box(root, Vector3(8.5, 9.0, 4.0), Vector3(at.x, 4.5, at.y), Color(0.72, 0.72, 0.76), true, Vector3(0, -angle + PI / 2.0, 0))
	for corner: Vector2 in [Vector2(-34, -24), Vector2(34, -24), Vector2(-34, 24), Vector2(34, 24)]:
		box(root, Vector3(0.6, 22, 0.6), Vector3(corner.x * 1.1, 11, corner.y * 1.1), Color(0.6, 0.6, 0.62), false)
		box(root, Vector3(4, 2, 0.5), Vector3(corner.x * 1.1, 22, corner.y * 1.1), Color.WHITE, false).material_override = _glow(Color(1.0, 0.97, 0.85), 2.5)
	marker(root, MapMarker.Kind.LANDMARK, "Stadion")


# --- Die Gläserne Küste ------------------------------------------------------

func _build_white_towers(root: Node3D, _landmark: Dictionary) -> void:
	var white := Color(0.94, 0.95, 0.97)
	var cyan := _glow(Color(0.35, 0.85, 1.0), 2.0)
	var spots: Array[Vector3] = [Vector3(0, 0, 0), Vector3(-26, 0, 14), Vector3(24, 0, 18), Vector3(-14, 0, -28), Vector3(22, 0, -22)]
	var heights: Array[float] = [150.0, 90.0, 110.0, 70.0, 80.0]
	for i in spots.size():
		var h := heights[i]
		var r := 9.0 - i * 0.6
		var tower := cylinder(root, r * 0.7, r, h, spots[i] + Vector3(0, h / 2.0, 0), white, true, 16)
		var ring := CylinderMesh.new()
		ring.top_radius = r * 0.92
		ring.bottom_radius = r * 1.02
		ring.height = 0.8
		for k in int(h / 16.0):
			var light := MeshInstance3D.new()
			light.mesh = ring
			light.material_override = cyan
			light.position = Vector3(0, -h / 2.0 + 10.0 + k * 16.0, 0)
			tower.add_child(light)
	box(root, Vector3(26, 2, 3), Vector3(-13, 50, 7), white, false, Vector3(0, -0.5, 0))
	box(root, Vector3(24, 2, 3), Vector3(12, 60, 9), white, false, Vector3(0, 0.6, 0))
	marker(root, MapMarker.Kind.CORPORATE_TOWER, "Weiße Türme")


func _build_glass_domes(root: Node3D, _landmark: Dictionary) -> void:
	var glass := StandardMaterial3D.new()
	glass.albedo_color = Color(0.6, 0.9, 1.0, 0.28)
	glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass.roughness = 0.05
	glass.metallic = 0.4
	ToonStyle.apply(glass, false)
	for spot: Vector3 in [Vector3(0, 0, 0), Vector3(-20, 0, 10), Vector3(18, 0, 12)]:
		var r := 14.0 if spot == Vector3.ZERO else 9.0
		cylinder(root, r + 0.6, r + 0.8, 1.0, spot + Vector3(0, 0.5, 0), Color(0.85, 0.88, 0.9))
		sphere(root, r, spot + Vector3(0, 1.0, 0), glass, true)
		sphere(root, r * 0.35, spot + Vector3(0, 2.5, 0), _glow(Color(0.4, 0.95, 0.6), 1.2))
	marker(root, MapMarker.Kind.LANDMARK, "Glaskuppeln")


func _build_maglev(root: Node3D, _landmark: Dictionary) -> void:
	var white := Color(0.92, 0.93, 0.96)
	box(root, Vector3(170, 1.2, 3), Vector3(0, 10, 0), white, false)
	for k in 9:
		var x := -80.0 + k * 20.0
		box(root, Vector3(1.4, 10, 1.4), Vector3(x, local_ground(root, Vector2(x, 0)) * 0.5 + 5.0, 0), white, false)
	var pod := box(root, Vector3(14, 3, 3.6), Vector3(-75, 12.4, 0), Color(0.85, 0.9, 0.95), false)
	box(pod, Vector3(12, 0.8, 3.7), Vector3(0, 0.2, 0), Color.WHITE, false).material_override = _glow(Color(0.35, 0.85, 1.0), 1.8)
	var tween := pod.create_tween().set_loops()
	tween.tween_property(pod, ^"position:x", 75.0, 9.0).set_trans(Tween.TRANS_SINE)
	tween.tween_property(pod, ^"position:x", -75.0, 9.0).set_trans(Tween.TRANS_SINE)
	marker(root, MapMarker.Kind.LANDMARK, "Schwebebahn")

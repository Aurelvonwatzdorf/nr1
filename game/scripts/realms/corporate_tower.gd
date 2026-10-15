class_name CorporateTower
extends RealityLevel
## Der Konzernturm (Tutorial, Spielstart): ein steriles Großraumbüro, das sich
## wie ein normaler Arbeitstag anfühlt. Mit dem Realitätsblick (Q) findet man
## Risse; man lernt kämpfen; am Ende erscheint Adam, und der Turm bricht zusammen.
##
## Grundriss (Blick nach Norden = -z):
##   Büro (z 10 … -20) → Tür → Halle mit Ankerspiegel und Empore (z -20 … -45)
##   → Tür → Großraum mit Wachen und verstecktem Archiv (z -45 … -90) → Riss.

const WALL_COLOR := Color(0.9, 0.9, 0.92)
const FLOOR_COLOR := Color(0.78, 0.79, 0.82)
const DESK_COLOR := Color(0.62, 0.64, 0.68)
const ACCENT_COLOR := Color(0.3, 0.45, 0.6)
const LIGHT_COLOR := Color(0.95, 0.97, 1.0)


func _enter_tree() -> void:
	super._enter_tree()
	_build_tower()


func _ready() -> void:
	super._ready()
	_register_map()


## Fallende Bruchstücke und weißes Licht, dann der Wechsel in die Stadt.
func break_reality() -> void:
	if is_broken:
		return
	_collapse_effect()
	await super.break_reality()


func _collapse_effect() -> void:
	EventBus.message_requested.emit("Der Turm zerbricht …")
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	for node in $Geometry.get_children():
		var piece := node as Node3D
		if piece == null or piece.name.begins_with("Floor"):
			continue
		var tween := piece.create_tween()
		tween.tween_interval(rng.randf_range(0.0, 0.8))
		tween.tween_property(piece, "position:y", piece.position.y - rng.randf_range(8.0, 20.0), 1.2).set_ease(Tween.EASE_IN)
	var flash := ColorRect.new()
	flash.color = Color(1, 1, 1, 0)
	flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var layer := CanvasLayer.new()
	layer.layer = 20
	layer.add_child(flash)
	add_child(layer)
	flash.create_tween().tween_property(flash, "color:a", 1.0, 1.4)


# --- Aufbau ---

func _build_tower() -> void:
	var root := get_node_or_null("Geometry") as Node3D
	if root == null:
		root = Node3D.new()
		root.name = "Geometry"
		add_child(root)
	# Boden und Außenwände.
	_box(root, "Floor", Vector3(0, -0.5, -40), Vector3(42, 1, 102), FLOOR_COLOR)
	_box(root, "WallWest", Vector3(-21, 3, -40), Vector3(1, 6, 102), WALL_COLOR)
	_box(root, "WallEast", Vector3(21, 3, -40), Vector3(1, 6, 102), WALL_COLOR)
	_box(root, "WallSouth", Vector3(0, 3, 11), Vector3(42, 6, 1), WALL_COLOR)
	# Nordseite: Fensterfront mit Blick auf eine Stadt, die es nicht gibt.
	_box(root, "WallNorthLow", Vector3(0, 0.5, -91), Vector3(42, 1, 1), WALL_COLOR)
	_glass(root, Vector3(0, 3.5, -91), Vector3(42, 5, 0.2))
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	for i in 14:
		var height := rng.randf_range(20.0, 70.0)
		_box(root, "Skyline%d" % i, Vector3(-60 + i * 9.0, height / 2.0 - 10.0, -130 - rng.randf_range(0, 30)),
			Vector3(rng.randf_range(5, 8), height, rng.randf_range(5, 8)), Color(0.75, 0.78, 0.84), false)
	# Querwände mit Türöffnungen.
	for z: float in [-20.0, -45.0]:
		_box(root, "Cross%dLeft" % int(-z), Vector3(-11.5, 3, z), Vector3(19, 6, 0.6), WALL_COLOR)
		_box(root, "Cross%dRight" % int(-z), Vector3(11.5, 3, z), Vector3(19, 6, 0.6), WALL_COLOR)
		_box(root, "Cross%dTop" % int(-z), Vector3(0, 5, z), Vector3(4, 2, 0.6), WALL_COLOR)
	# Büro: Reihen von Schreibtischen mit Trennwänden.
	for row in 3:
		for column in 4:
			var at := Vector3(-13 + column * 8.5, 0, 4 - row * 8)
			if at.distance_to(Vector3(0, 0, 4)) < 3.0:
				continue
			_desk(root, at, "Desk%d_%d" % [row, column])
	_desk(root, Vector3(2, 0, 3), "DeskPlayer")
	# Leuchtstreifen an der Decke (es gibt keine Decke, nur das Licht).
	for i in 9:
		_glow(root, Vector3(0, 6.2, 6 - i * 11.0), Vector3(30, 0.15, 0.6), LIGHT_COLOR)
	# Halle: Empore mit Archivschränken, nur über eine versteckte Rampe erreichbar.
	_box(root, "Gallery", Vector3(16, 1.5, -35), Vector3(8, 3, 14), DESK_COLOR.darkened(0.1))
	_box(root, "Elevator", Vector3(-14, 3, -44.2), Vector3(5, 6, 0.4), ACCENT_COLOR)
	_label(root, Vector3(-14, 4.5, -43.8), "Aufzug außer Betrieb")
	# Großraum: Säulen und Konferenztisch.
	for z: float in [-55.0, -70.0]:
		for x: float in [-10.0, 10.0]:
			_box(root, "Pillar%d_%d" % [int(x), int(-z)], Vector3(x, 3, z), Vector3(1.4, 6, 1.4), WALL_COLOR)
	_box(root, "Conference", Vector3(2, 0.45, -62), Vector3(3, 0.9, 7), DESK_COLOR)
	# Archiv: kleiner Raum hinter einer falschen Wand (siehe Szene: ArchiveDoor).
	_box(root, "ArchiveNorth", Vector3(-16, 3, -81), Vector3(9, 6, 0.6), WALL_COLOR)
	_box(root, "ArchiveSouth", Vector3(-16, 3, -69), Vector3(9, 6, 0.6), WALL_COLOR)
	_box(root, "ArchiveEastA", Vector3(-11.5, 3, -71.5), Vector3(0.6, 6, 4.4), WALL_COLOR)
	_box(root, "ArchiveEastB", Vector3(-11.5, 3, -78.5), Vector3(0.6, 6, 4.4), WALL_COLOR)
	_box(root, "ArchiveTop", Vector3(-11.5, 5, -75), Vector3(0.6, 2, 3), WALL_COLOR)
	_build_layer_objects()


## Dinge, die nur in einer Ebene existieren (Knoten stehen in der Szene).
func _build_layer_objects() -> void:
	# Versteckte Rampe zur Empore (nur in der wahren Welt).
	var ramp_root := get_node_or_null("HiddenRamp") as Node3D
	if ramp_root:
		var ramp := Node3D.new()
		var angle := atan2(3.0, 7.5)
		ramp.position = Vector3(12.0 - 4.0 * cos(angle), 4.0 * sin(angle) - 0.1, -35)
		ramp.rotation.z = angle
		ramp_root.add_child(ramp)
		_box(ramp, "Ramp", Vector3.ZERO, Vector3(8, 0.3, 2.5), Color(0.45, 0.85, 1.0))
	# Falsche Wand vor dem Archiv (nur in der Illusion).
	var door_root := get_node_or_null("ArchiveDoor") as Node3D
	if door_root:
		_box(door_root, "FalseWall", Vector3(-11.5, 2, -75), Vector3(0.6, 4, 3), WALL_COLOR)


func _desk(root: Node3D, at: Vector3, desk_name: String) -> void:
	_box(root, desk_name, at + Vector3(0, 0.4, 0), Vector3(2.4, 0.8, 1.2), DESK_COLOR)
	_box(root, desk_name + "Screen", at + Vector3(0, 1.1, -0.35), Vector3(0.9, 0.55, 0.06), Color(0.15, 0.2, 0.28), false)
	_box(root, desk_name + "Divider", at + Vector3(0, 0.75, -0.7), Vector3(2.6, 1.5, 0.08), ACCENT_COLOR.lightened(0.3))


func _box(root: Node3D, box_name: String, center: Vector3, size: Vector3, color: Color, solid: bool = true) -> void:
	var mesh := BoxMesh.new()
	mesh.size = size
	var instance := MeshInstance3D.new()
	instance.name = box_name
	instance.mesh = mesh
	instance.material_override = ToonStyle.make(color)
	instance.position = center
	if solid:
		var body := StaticBody3D.new()
		body.collision_layer = PhysicsLayers.WORLD
		body.collision_mask = 0
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = size
		shape.shape = box
		body.add_child(shape)
		instance.add_child(body)
	root.add_child(instance)


func _glow(root: Node3D, center: Vector3, size: Vector3, color: Color) -> void:
	var mesh := BoxMesh.new()
	mesh.size = size
	var material := ToonStyle.make(color, false)
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = 1.2
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.material_override = material
	instance.position = center
	root.add_child(instance)


func _glass(root: Node3D, center: Vector3, size: Vector3) -> void:
	var mesh := BoxMesh.new()
	mesh.size = size
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.7, 0.85, 0.95, 0.25)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	var instance := MeshInstance3D.new()
	instance.name = "Windows"
	instance.mesh = mesh
	instance.material_override = material
	instance.position = center
	var body := StaticBody3D.new()
	body.collision_layer = PhysicsLayers.WORLD
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	body.add_child(shape)
	instance.add_child(body)
	root.add_child(instance)


func _label(root: Node3D, at: Vector3, text: String) -> void:
	var label := Label3D.new()
	label.text = text
	label.font_size = 48
	label.outline_size = 8
	label.modulate = Color(0.2, 0.25, 0.3)
	label.position = at
	root.add_child(label)


func _register_map() -> void:
	var map_data := get_node_or_null("MapData") as MapData
	if map_data == null:
		return
	map_data.bounds = Rect2(-25, -95, 50, 110)
	map_data.area_name = "Der Konzernturm"
	map_data.add_rect(Rect2(-21, -91, 42, 102), Color(0.55, 0.57, 0.62))
	map_data.add_rect(Rect2(-21, -20.3, 19, 0.6), Color(0.85, 0.85, 0.9))
	map_data.add_rect(Rect2(2, -20.3, 19, 0.6), Color(0.85, 0.85, 0.9))
	map_data.add_rect(Rect2(-21, -45.3, 19, 0.6), Color(0.85, 0.85, 0.9))
	map_data.add_rect(Rect2(2, -45.3, 19, 0.6), Color(0.85, 0.85, 0.9))
	map_data.add_rect(Rect2(12, -42, 8, 14), Color(0.45, 0.47, 0.52), "Empore")
	map_data.add_rect(Rect2(-20.5, -81, 9, 12), Color(0.45, 0.47, 0.52))

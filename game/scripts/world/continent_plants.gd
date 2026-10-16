class_name ContinentPlants
extends RefCounted
## Pflanzen und Felsen für den Kontinent: wählt je Region passende Arten und
## baut deren Meshes (aus einfachen Formen mit Eckenfarben zusammengesetzt,
## damit jede Art nur ein Mesh für viele Exemplare braucht).

const TREES: Array[StringName] = [&"maple_red", &"maple_orange", &"pine", &"oak", &"palm", &"spirit", &"dead"]

var _cache: Dictionary[StringName, Array] = {}
var _plain_material: StandardMaterial3D


func _init() -> void:
	_plain_material = ToonStyle.make(Color.WHITE)
	_plain_material.vertex_color_use_as_albedo = true


## Welche Pflanze an dieser Stelle wächst ("" = keine).
func pick(style: ContinentRegion.Style, height: float, near_river: bool, rng: RandomNumberGenerator) -> StringName:
	var roll := rng.randf()
	match style:
		ContinentRegion.Style.WASTELAND:
			return &"dead" if roll < 0.45 else (&"scrap" if roll < 0.75 else &"rock")
		ContinentRegion.Style.MOUNTAINS:
			if height > 95.0:
				return &"pine" if roll < 0.5 else &"rock"
			if roll < 0.4:
				return &"maple_red"
			if roll < 0.65:
				return &"maple_orange"
			return &"pine" if roll < 0.85 else &"rock"
		ContinentRegion.Style.STEPPE:
			return &"bush" if roll < 0.55 else (&"rock" if roll < 0.82 else &"oak")
		ContinentRegion.Style.MEDIEVAL:
			if roll < 0.55:
				return &"oak"
			return &"pine" if roll < 0.85 else (&"bush" if roll < 0.95 else &"rock")
		ContinentRegion.Style.MYSTIC_FOREST:
			return &"spirit" if roll < 0.5 else (&"oak" if roll < 0.82 else &"rock")
		ContinentRegion.Style.DESERT:
			if near_river:
				return &"palm" if roll < 0.85 else &"bush"
			return &"rock" if roll < 0.3 else &""
		ContinentRegion.Style.PRESENT:
			return &"oak" if roll < 0.6 else (&"bush" if roll < 0.9 else &"rock")
		ContinentRegion.Style.FUTURE:
			return &"crystal" if roll < 0.5 else (&"bush" if roll < 0.85 else &"rock")
	return &""


func is_tree(kind: StringName) -> bool:
	return TREES.has(kind)


func has_collision(kind: StringName) -> bool:
	return is_tree(kind) or kind == &"rock"


func collision_radius(kind: StringName) -> float:
	match kind:
		&"spirit":
			return 0.9
		&"rock":
			return 1.1
	return 0.4


func base_scale(kind: StringName) -> float:
	match kind:
		&"spirit":
			return 1.8
		&"rock":
			return 1.2
		&"bush":
			return 0.9
	return 1.0


## Teile einer Art: [{"mesh": Mesh, "material": Material}, …]
func meshes(kind: StringName) -> Array:
	if not _cache.has(kind):
		_cache[kind] = _build(kind)
	return _cache[kind]


func _build(kind: StringName) -> Array:
	var bark := Color(0.32, 0.22, 0.16)
	match kind:
		&"maple_red", &"maple_orange":
			var leaf := Color(0.78, 0.18, 0.12) if kind == &"maple_red" else Color(0.9, 0.48, 0.12)
			return [_plain([
				[_cylinder(0.18, 0.3, 4.0), Vector3(0, 2.0, 0), bark],
				[_sphere(2.0), Vector3(0, 4.8, 0), leaf],
				[_sphere(1.5), Vector3(1.2, 4.0, 0.4), leaf.darkened(0.1)],
				[_sphere(1.4), Vector3(-1.0, 4.3, -0.6), leaf.lightened(0.08)],
			])]
		&"pine":
			var needle := Color(0.14, 0.32, 0.2)
			return [_plain([
				[_cylinder(0.15, 0.28, 3.0), Vector3(0, 1.5, 0), bark],
				[_cone(2.2, 3.0), Vector3(0, 3.5, 0), needle],
				[_cone(1.7, 2.6), Vector3(0, 5.2, 0), needle.lightened(0.06)],
				[_cone(1.1, 2.2), Vector3(0, 6.7, 0), needle.lightened(0.12)],
			])]
		&"oak":
			var leaf := Color(0.26, 0.48, 0.22)
			return [_plain([
				[_cylinder(0.22, 0.35, 3.6), Vector3(0, 1.8, 0), bark],
				[_sphere(2.3), Vector3(0, 4.6, 0), leaf],
				[_sphere(1.7), Vector3(1.4, 4.0, 0.6), leaf.darkened(0.12)],
				[_sphere(1.6), Vector3(-1.3, 4.2, -0.5), leaf.lightened(0.1)],
			])]
		&"palm":
			var frond := Color(0.3, 0.55, 0.22)
			var parts: Array = [[_cylinder(0.14, 0.24, 6.0), Vector3(0, 3.0, 0), Color(0.55, 0.42, 0.28)]]
			for i in 6:
				var angle := TAU * i / 6.0
				var dir := Vector3(cos(angle), 0.0, sin(angle))
				parts.append([_box(Vector3(2.6, 0.1, 0.7)), Vector3(0, 6.0, 0) + dir * 1.2, frond, angle])
			return [_plain(parts)]
		&"spirit":
			var glow := ToonStyle.make(Color(0.5, 0.95, 0.9), false)
			glow.emission_enabled = true
			glow.emission = Color(0.35, 0.95, 0.85)
			glow.emission_energy_multiplier = 1.3
			var canopy := _combine([
				[_sphere(2.6), Vector3(0, 7.5, 0), Color.WHITE],
				[_sphere(1.8), Vector3(1.8, 6.4, 0.8), Color.WHITE],
				[_sphere(1.7), Vector3(-1.6, 6.8, -0.9), Color.WHITE],
			])
			return [
				_plain([[_cylinder(0.35, 0.6, 7.0), Vector3(0, 3.5, 0), Color(0.75, 0.78, 0.82)]]),
				{"mesh": canopy, "material": glow},
			]
		&"dead":
			var gray := Color(0.36, 0.32, 0.3)
			return [_plain([
				[_cylinder(0.12, 0.3, 4.5), Vector3(0, 2.25, 0), gray],
				[_cylinder(0.05, 0.1, 2.0), Vector3(0.6, 3.6, 0), gray, 0.0, 0.9],
				[_cylinder(0.05, 0.1, 1.6), Vector3(-0.5, 3.2, 0.2), gray, PI, 0.8],
			])]
		&"bush":
			var leaf := Color(0.4, 0.5, 0.25)
			return [_plain([
				[_sphere(0.9), Vector3(0, 0.5, 0), leaf],
				[_sphere(0.7), Vector3(0.6, 0.4, 0.3), leaf.darkened(0.1)],
			])]
		&"rock":
			return [_plain([
				[_sphere(1.2, 6, 4), Vector3(0, 0.3, 0), Color(0.45, 0.43, 0.42)],
				[_sphere(0.7, 6, 4), Vector3(0.9, 0.1, 0.4), Color(0.4, 0.38, 0.37)],
			])]
		&"scrap":
			var rust := Color(0.5, 0.28, 0.16)
			return [_plain([
				[_box(Vector3(2.2, 1.0, 1.4)), Vector3(0, 0.5, 0), rust],
				[_box(Vector3(1.0, 1.4, 1.0)), Vector3(0.9, 1.0, 0.3), rust.darkened(0.2)],
				[_cylinder(0.4, 0.4, 1.8), Vector3(-0.9, 0.4, -0.3), Color(0.35, 0.35, 0.38), 0.0, 1.57],
			])]
		&"crystal":
			var glow := ToonStyle.make(Color(0.6, 0.9, 1.0), false)
			glow.emission_enabled = true
			glow.emission = Color(0.4, 0.8, 1.0)
			glow.emission_energy_multiplier = 1.2
			var mesh := _combine([
				[_cylinder(0.0, 0.35, 2.4, 4), Vector3(0, 1.2, 0), Color.WHITE],
				[_cylinder(0.0, 0.25, 1.6, 4), Vector3(0.5, 0.8, 0.2), Color.WHITE, 0.5, 0.3],
			])
			return [{"mesh": mesh, "material": glow}]
	return []


func _plain(parts: Array) -> Dictionary:
	return {"mesh": _combine(parts), "material": _plain_material}


## Teile: [Mesh, Position, Farbe, (Drehung um Y), (Neigung um Z)].
static func _combine(parts: Array) -> ArrayMesh:
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var colors := PackedColorArray()
	var indices := PackedInt32Array()
	for part: Array in parts:
		var mesh: PrimitiveMesh = part[0]
		var basis := Basis(Vector3.UP, float(part[3]) if part.size() > 3 else 0.0)
		if part.size() > 4:
			basis = basis * Basis(Vector3.FORWARD, float(part[4]))
		var transform := Transform3D(basis, part[1])
		var color: Color = part[2]
		var arrays := mesh.get_mesh_arrays()
		var offset := vertices.size()
		var src_vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var src_normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
		for v in src_vertices.size():
			vertices.append(transform * src_vertices[v])
			normals.append((basis * src_normals[v]).normalized())
			colors.append(color)
		var src_indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
		for index in src_indices:
			indices.append(index + offset)
	var out := []
	out.resize(Mesh.ARRAY_MAX)
	out[Mesh.ARRAY_VERTEX] = vertices
	out[Mesh.ARRAY_NORMAL] = normals
	out[Mesh.ARRAY_COLOR] = colors
	out[Mesh.ARRAY_INDEX] = indices
	var result := ArrayMesh.new()
	result.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, out)
	return result


static func _cylinder(top: float, bottom: float, height: float, segments: int = 8) -> CylinderMesh:
	var mesh := CylinderMesh.new()
	mesh.top_radius = top
	mesh.bottom_radius = bottom
	mesh.height = height
	mesh.radial_segments = segments
	mesh.rings = 1
	return mesh


static func _cone(radius: float, height: float) -> CylinderMesh:
	return _cylinder(0.0, radius, height, 8)


static func _sphere(radius: float, segments: int = 10, rings: int = 6) -> SphereMesh:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = segments
	mesh.rings = rings
	return mesh


static func _box(size: Vector3) -> BoxMesh:
	var mesh := BoxMesh.new()
	mesh.size = size
	return mesh

class_name CityGenerator
extends Node3D
## Baut eine Stadt aus einem CityLayout (Bauplan). Organisch statt Schachbrett:
##
## 1. Umriss: unregelmäßige Form (Rauschen), nach Norden ausgebeult.
## 2. Bezirke: Jeder Punkt gehört zum nächsten Bezirk; die Grenzen fransen aus.
## 3. Straßen: Hauptstraßen aus dem Bauplan, davon zweigen gewundene Gassen ab
##    (im Konzernviertel schnurgerade, imperial).
## 4. Häuser: entlang der Straßen und in den Lücken dazwischen, jedes zur nächsten
##    Straße gedreht. Bauweise, Höhe und Abstände hängen vom Bezirk ab.
## 5. Wahrzeichen: Markt, Konzern-Zitadelle mit Prachtstraße, Kaserne,
##    Gotteshäuser. Draußen: wilde, leuchtende Natur bis zur unsichtbaren Mauer.
##
## Gleicher `seed` = gleiche Stadt. Häuser haben Kollision (Ebene Welt), Ranken,
## Pflanzen und Schutt nicht. Alles unter `keep_clear` (NPCs, Spiegel …) bleibt frei.

@export var layout: CityLayout
@export var seed: int = 7
## Hier wird der Grundriss für die Karte eingetragen.
@export var map_data: MapData
## Deren Kinder (NPCs, Gegner, Spiegel, Gegenstände) bekommen Platz: Dort wird
## nichts gebaut.
@export var keep_clear: Array[Node] = []

const VINE_COLORS: Array[Color] = [Color(0.2, 1.0, 0.75), Color(0.45, 1.0, 0.4), Color(0.4, 0.85, 1.0)]
const ROAD_COLOR := Color(0.11, 0.11, 0.13)
const WILD_COLOR := Color(0.13, 0.17, 0.14)
const PLAZA_COLOR := Color(0.5, 0.47, 0.42)
const IMPERIAL_RED := Color(0.85, 0.12, 0.16)
## Kleinkram (Ranken, Pflanzen, Schutt) wird ab dieser Entfernung nicht mehr gezeichnet.
const DETAIL_RANGE := 90.0
## Größe einer Zelle im Belegungsraster (Meter).
const CELL := 24.0
## Größe eines Stadtstücks beim Zusammenfassen der Meshes (Meter).
const BATCH_CHUNK := 48.0
## Radius, der um NPCs, Spiegel und Gegenstände frei bleibt.
const KEEP_CLEAR_RADIUS := 3.0
const KIT_PATH := "res://assets/models/city_kit/%s.obj"
## Gebäude aus der Blender-Vorlage: Breite, Höhe, Tiefe (Grundfläche auf 1 normiert).
const KIT_TOWERS: Dictionary[String, Vector3] = {
	"highrise_1": Vector3(1.0, 3.671, 1.0),
	"highrise_3": Vector3(1.0, 3.417, 1.0),
	"highrise_4": Vector3(1.0, 3.188, 0.712),
	"highrise_5": Vector3(1.0, 3.482, 0.521),
	"highrise_7": Vector3(0.902, 2.701, 1.0),
	"highrise_9": Vector3(1.0, 2.266, 1.0),
	"highrise_10": Vector3(1.0, 2.948, 0.812),
	"highrise_11": Vector3(1.0, 4.775, 1.0),
	"highrise_15": Vector3(1.0, 3.65, 1.0),
	"highrise_16": Vector3(1.0, 4.372, 1.0),
	"highrise_17": Vector3(0.525, 3.807, 1.0),
	"highrise_18": Vector3(1.0, 3.944, 1.0),
	"highrise_19": Vector3(1.0, 2.409, 1.0),
}
const KIT_MIDRISE: Dictionary[String, Vector3] = {
	"highrise_2": Vector3(1.0, 1.888, 0.943),
	"highrise_6": Vector3(1.0, 1.978, 1.0),
	"highrise_8": Vector3(1.0, 1.155, 1.0),
	"highrise_12": Vector3(1.0, 1.321, 0.444),
	"highrise_13": Vector3(1.0, 1.605, 0.352),
	"highrise_14": Vector3(1.0, 1.517, 0.598),
}
const KIT_BLOCKS: Dictionary[String, Vector3] = {
	"group1": Vector3(0.653, 1.769, 1.0),
	"group2": Vector3(0.553, 1.064, 1.0),
	"group3": Vector3(1.0, 1.407, 0.971),
	"group4": Vector3(0.709, 1.709, 1.0),
	"group5": Vector3(0.863, 1.287, 1.0),
	"group6": Vector3(0.814, 1.605, 1.0),
}


## Gedrehtes Rechteck auf dem Boden (Grundfläche eines Hauses). Die Vorderseite
## (lokal -z) zeigt zur Straße.
class Footprint:
	var center: Vector2
	var half: Vector2
	var angle: float

	func _init(new_center: Vector2, size: Vector2, new_angle: float) -> void:
		center = new_center
		half = size / 2.0
		angle = new_angle

	func axis_x() -> Vector2:
		return Vector2.from_angle(angle)

	func axis_z() -> Vector2:
		return Vector2.from_angle(angle + PI / 2.0)

	func corners() -> PackedVector2Array:
		var ax := axis_x() * half.x
		var az := axis_z() * half.y
		return PackedVector2Array([center - ax - az, center + ax - az, center + ax + az, center - ax + az])

	func to_local(point: Vector2) -> Vector2:
		var offset := point - center
		return Vector2(offset.dot(axis_x()), offset.dot(axis_z()))

	func bounding_radius() -> float:
		return half.length()


## Anzahl zusammengefasster Meshes (für Tests und Statistik).
var batch_count: int = 0
## Anzahl gebauter Häuser (für Tests und Statistik).
var building_count: int = 0
## Wie oft jede Bauform vorkommt (für Tests).
var kind_counts: Dictionary[StringName, int] = {}
## Alle Straßen als Punktfolgen (x, z), z. B. für herumlaufende NPCs.
var road_paths: Array[PackedVector2Array] = []
## Breite je Straße (gleiche Reihenfolge wie `road_paths`).
var road_widths: PackedFloat32Array = PackedFloat32Array()
## Stadtrand und unsichtbare Mauer (Punktfolgen x, z).
var outline: PackedVector2Array = PackedVector2Array()
var boundary: PackedVector2Array = PackedVector2Array()
## Wegenetz für NPCs: Wegpunkte auf Straßen und Plätzen, ihre Nachbarn und der
## Bezirk (id), in dem jeder Punkt liegt.
var waypoints: PackedVector2Array = PackedVector2Array()
var waypoint_links: Array[PackedInt32Array] = []
var waypoint_districts: Array[StringName] = []

var _rng := RandomNumberGenerator.new()
var _noise := FastNoiseLite.new()
## Räumliches Raster: Zelle → belegte Grundflächen bzw. Straßenstücke.
var _cells: Dictionary[Vector2i, Array] = {}
var _road_cells: Dictionary[Vector2i, Array] = {}
## Frei zu haltende Kreise: Vector3(x, z, Radius).
var _clear_circles: Array[Vector3] = []
var _building_material: ShaderMaterial
var _materials: Dictionary[Color, StandardMaterial3D] = {}
var _glow_materials: Dictionary[Color, StandardMaterial3D] = {}
var _kit_meshes: Dictionary[String, Mesh] = {}


func _enter_tree() -> void:
	add_to_group(&"city_generator")


func _ready() -> void:
	generate()


func generate() -> void:
	_rng.seed = seed
	_noise.seed = seed
	_noise.frequency = 0.012
	_cells.clear()
	_road_cells.clear()
	_clear_circles.clear()
	road_paths.clear()
	road_widths = PackedFloat32Array()
	building_count = 0
	kind_counts.clear()
	_building_material = ShaderMaterial.new()
	_building_material.shader = preload("res://assets/materials/building.gdshader")
	batch_count = 0

	_build_outline()
	_add_district_map()
	for i in layout.main_roads.size():
		var width := layout.main_road_widths[i] if i < layout.main_road_widths.size() else 8.0
		_add_road(layout.main_roads[i], width)
	for plaza in layout.plazas:
		_clear_circles.append(plaza)
	_reserve_keep_clear()
	_reserve_landmarks()
	_build_boulevard_towers()
	_generate_streets()

	_build_ground()
	_build_roads()
	_build_plazas()
	_build_landmarks()
	_place_around_plazas()
	_place_along_roads()
	_place_infill()
	_build_wilds()
	_build_boundary()
	_build_waypoints()
	_batch_geometry()
	if map_data:
		var box := Rect2(boundary[0], Vector2.ZERO)
		for point in boundary:
			box = box.expand(point)
		map_data.bounds = box
		map_data.area_name = layout.city_name


# --- Umriss und Bezirke ---

func _build_outline() -> void:
	outline = PackedVector2Array()
	boundary = PackedVector2Array()
	for i in 72:
		var angle := TAU * i / 72.0
		var r := get_outline_radius(angle)
		outline.append(Vector2.from_angle(angle) * r)
		boundary.append(Vector2.from_angle(angle) * (r + layout.wild_margin))


## Radius des Stadtrands in einer Richtung (Winkel in der x-z-Ebene).
func get_outline_radius(angle: float) -> float:
	var wobble := clampf(_noise.get_noise_2d(cos(angle) * 60.0, sin(angle) * 60.0) * 2.0, -1.0, 1.0)
	var north := maxf(0.0, -sin(angle))
	return layout.radius * (1.0 + layout.roughness * wobble) + layout.north_bulge * north * north


func is_inside_city(point: Vector2) -> bool:
	return Geometry2D.is_point_in_polygon(point, outline)


## Zu welchem Bezirk ein Punkt gehört (Grenzen leicht verwirbelt).
func district_at(point: Vector2) -> CityDistrict:
	var warped := point + Vector2(_noise.get_noise_2d(point.x, point.y),
		_noise.get_noise_2d(point.x + 500.0, point.y - 300.0)) * 40.0
	var best: CityDistrict = null
	var best_score := INF
	for district in layout.districts:
		var score := warped.distance_to(district.center) / district.reach
		if score < best_score:
			best_score = score
			best = district
	return best


## 1 = reich (Norden), 0 = arm (Süden). Jeder Bezirk hat reichere und ärmere Straßen.
func richness_at(point: Vector2) -> float:
	return clampf(0.5 - point.y / 220.0 + _noise.get_noise_2d(point.x * 2.0, point.y * 2.0) * 0.25, 0.0, 1.0)


# --- Straßen ---

func _add_road(points: PackedVector2Array, width: float) -> void:
	road_paths.append(points)
	road_widths.append(width)
	var half := width / 2.0
	for i in points.size() - 1:
		var a := points[i]
		var b := points[i + 1]
		var box := Rect2(a, Vector2.ZERO).expand(b).grow(half + 1.0)
		for cell in _cells_in(box):
			if not _road_cells.has(cell):
				_road_cells[cell] = []
			_road_cells[cell].append(Vector3(a.x, a.y, half))
			_road_cells[cell].append(Vector3(b.x, b.y, half))


## Abstand vom Punkt bis zum nächsten Straßenrand (negativ = auf der Straße).
func road_clearance(point: Vector2) -> float:
	var best := INF
	var cell := _cell_of(point)
	for dx in range(-1, 2):
		for dz in range(-1, 2):
			var entries: Array = _road_cells.get(cell + Vector2i(dx, dz), [])
			for i in range(0, entries.size(), 2):
				var a: Vector3 = entries[i]
				var b: Vector3 = entries[i + 1]
				var closest := Geometry2D.get_closest_point_to_segment(point, Vector2(a.x, a.y), Vector2(b.x, b.y))
				best = minf(best, point.distance_to(closest) - a.z)
	return best


## Richtung der nächsten Straße (für die Drehung der Häuser).
func _nearest_road_angle(point: Vector2) -> float:
	var best := INF
	var angle := 0.0
	var cell := _cell_of(point)
	for dx in range(-2, 3):
		for dz in range(-2, 3):
			var entries: Array = _road_cells.get(cell + Vector2i(dx, dz), [])
			for i in range(0, entries.size(), 2):
				var a: Vector3 = entries[i]
				var b: Vector3 = entries[i + 1]
				var closest := Geometry2D.get_closest_point_to_segment(point, Vector2(a.x, a.y), Vector2(b.x, b.y))
				var distance := point.distance_to(closest)
				if distance < best:
					best = distance
					angle = (Vector2(b.x, b.y) - Vector2(a.x, a.y)).angle()
	return angle


## Von den Hauptstraßen zweigen Gassen ab, von denen wieder Gassen abzweigen.
func _generate_streets() -> void:
	var parents: Array[PackedVector2Array] = layout.main_roads.duplicate()
	for generation in 2:
		var children: Array[PackedVector2Array] = []
		for road in parents:
			var length := _path_length(road)
			var along := _rng.randf_range(10.0, 25.0)
			while along < length - 8.0:
				var sample := _sample_path(road, along)
				var point: Vector2 = sample[0]
				var tangent: Vector2 = sample[1]
				var district := district_at(point)
				if is_inside_city(point):
					for side: float in [-1.0, 1.0]:
						if _rng.randf() < (0.8 if generation == 0 else 0.45):
							var street := _grow_street(point, tangent.orthogonal() * side, district)
							if street.size() >= 3:
								_add_road(street, district.street_width)
								children.append(street)
				along += district.branch_spacing * _rng.randf_range(0.7, 1.3)
		parents = children


func _grow_street(start: Vector2, direction: Vector2, district: CityDistrict) -> PackedVector2Array:
	var imperial := district.style == CityDistrict.Style.IMPERIAL
	var width := district.street_width
	var step := 8.0
	var max_length := _rng.randf_range(25.0, 70.0) if district.kind == CityDistrict.Kind.SLUM else _rng.randf_range(40.0, 110.0)
	var heading := direction.angle() + (0.0 if imperial else _rng.randf_range(-0.3, 0.3))
	var points := PackedVector2Array([start])
	var cursor := start
	var travelled := 0.0
	while travelled < max_length:
		if not imperial:
			heading += _rng.randf_range(-district.street_wiggle, district.street_wiggle)
		var next := cursor + Vector2.from_angle(heading) * step
		if not is_inside_city(next) or _in_clear_circle(next, width):
			break
		if district_at(next).kind == CityDistrict.Kind.CORPORATE and not imperial:
			break
		if _hits_footprint(Footprint.new(next, Vector2(width, width), heading)):
			break
		# Trifft die Gasse auf eine andere Straße, wird sie dort angeschlossen.
		if travelled > 12.0 and road_clearance(next) < 1.0:
			points.append(next)
			return points
		points.append(next)
		cursor = next
		travelled += step
	return points if travelled >= 16.0 else PackedVector2Array()


func _path_length(points: PackedVector2Array) -> float:
	var length := 0.0
	for i in points.size() - 1:
		length += points[i].distance_to(points[i + 1])
	return length


## Punkt und Richtung auf einer Punktfolge nach `distance` Metern.
func _sample_path(points: PackedVector2Array, distance: float) -> Array:
	for i in points.size() - 1:
		var a := points[i]
		var b := points[i + 1]
		var segment := a.distance_to(b)
		if distance <= segment or i == points.size() - 2:
			var t := clampf(distance / maxf(segment, 0.001), 0.0, 1.0)
			return [a.lerp(b, t), (b - a).normalized()]
		distance -= segment
	return [points[0], Vector2.RIGHT]


# --- Zusammenfassen (Leistung) ---

## Fasst alle Gebäudeteile, Ranken und Pflanzen pro Stadtstück (Chunk) zu
## wenigen großen Meshes zusammen. Tausende einzelne Objekte kosten die
## Grafikkarte viel Zeit (vor allem beim Blick auf die Skyline). Die Knoten
## bleiben (ohne Mesh) bestehen, weil ihre Kollision daran hängt.
func _batch_geometry() -> void:
	var batches: Dictionary[String, Dictionary] = {}
	var to_local := global_transform.affine_inverse()
	for node in find_children("*", "MeshInstance3D", true, false):
		var instance := node as MeshInstance3D
		if instance.mesh == null or instance.has_meta(&"no_batch"):
			continue
		var color := Color.WHITE
		var windows := Vector2.ZERO
		var spacing := Vector2(2.6, 3.2)
		var glow := 0.0
		var outline := true
		if instance.has_meta(&"paint"):
			var paint: Array = instance.get_meta(&"paint")
			color = paint[0]
			windows = paint[1]
			spacing = paint[2]
		elif instance.material_override is StandardMaterial3D:
			var material := instance.material_override as StandardMaterial3D
			if material.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED:
				continue
			color = material.albedo_color
			outline = material.next_pass != null
			if material.emission_enabled:
				glow = material.emission_energy_multiplier
				color = material.emission
		else:
			continue
		var detail := instance.visibility_range_end > 0.0
		var xform := to_local * instance.global_transform
		var chunk := Vector2i(floori(xform.origin.x / BATCH_CHUNK), floori(xform.origin.z / BATCH_CHUNK))
		var key := "%d,%d,%d,%d" % [chunk.x, chunk.y, int(outline), int(detail)]
		if not batches.has(key):
			batches[key] = {"verts": PackedVector3Array(), "normals": PackedVector3Array(),
				"colors": PackedColorArray(), "uv": PackedVector2Array(), "uv2": PackedVector2Array(),
				"indices": PackedInt32Array(), "outline": outline, "detail": detail}
		var batch: Dictionary = batches[key]
		var vertex_color := Color(color.r, color.g, color.b, 1.0 / (1.0 + glow))
		var normal_xform := Transform3D(xform.basis.inverse().transposed(), Vector3.ZERO)
		for surface in instance.mesh.get_surface_count():
			var arrays := instance.mesh.surface_get_arrays(surface)
			var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
			# Packed-Arrays sind Werte: holen, erweitern, zurückschreiben.
			var all_verts: PackedVector3Array = batch["verts"]
			var offset := all_verts.size()
			all_verts.append_array(xform * verts)
			batch["verts"] = all_verts
			var all_normals: PackedVector3Array = batch["normals"]
			all_normals.append_array(normal_xform * normals)
			batch["normals"] = all_normals
			var count := verts.size()
			var colors := PackedColorArray()
			colors.resize(count)
			colors.fill(vertex_color)
			var all_colors: PackedColorArray = batch["colors"]
			all_colors.append_array(colors)
			batch["colors"] = all_colors
			var uv := PackedVector2Array()
			uv.resize(count)
			uv.fill(windows)
			var all_uv: PackedVector2Array = batch["uv"]
			all_uv.append_array(uv)
			batch["uv"] = all_uv
			uv.fill(spacing)
			var all_uv2: PackedVector2Array = batch["uv2"]
			all_uv2.append_array(uv)
			batch["uv2"] = all_uv2
			var source_indices: Variant = arrays[Mesh.ARRAY_INDEX]
			var indices := PackedInt32Array()
			if source_indices is PackedInt32Array and not (source_indices as PackedInt32Array).is_empty():
				indices = source_indices
			else:
				indices.resize(count)
				for i in count:
					indices[i] = i
			var target: PackedInt32Array = batch["indices"]
			var start := target.size()
			target.resize(start + indices.size())
			for i in indices.size():
				target[start + i] = indices[i] + offset
			batch["indices"] = target
		instance.mesh = null
	var outline_material := ShaderMaterial.new()
	outline_material.shader = preload("res://assets/materials/outline.gdshader")
	var plain := ShaderMaterial.new()
	plain.shader = _building_material.shader
	var outlined := ShaderMaterial.new()
	outlined.shader = _building_material.shader
	outlined.next_pass = outline_material
	for key in batches:
		var batch: Dictionary = batches[key]
		var arrays := []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = batch["verts"]
		arrays[Mesh.ARRAY_NORMAL] = batch["normals"]
		arrays[Mesh.ARRAY_COLOR] = batch["colors"]
		arrays[Mesh.ARRAY_TEX_UV] = batch["uv"]
		arrays[Mesh.ARRAY_TEX_UV2] = batch["uv2"]
		arrays[Mesh.ARRAY_INDEX] = batch["indices"]
		var mesh := ArrayMesh.new()
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		var merged := MeshInstance3D.new()
		merged.mesh = mesh
		merged.material_override = outlined if batch["outline"] else plain
		if batch["detail"]:
			merged.visibility_range_end = DETAIL_RANGE * 1.5
			merged.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		merged.set_meta(&"no_batch", true)
		add_child(merged)
		batch_count += 1


# --- Wegenetz für NPCs ---

## Wegpunkte alle ~9 m auf jeder Straße; Nachbarn entlang der Straße, an
## Kreuzungen und quer über Plätze.
func _build_waypoints() -> void:
	waypoints = PackedVector2Array()
	waypoint_links.clear()
	waypoint_districts.clear()
	var road_of: PackedInt32Array = PackedInt32Array()
	for road_index in road_paths.size():
		var road := road_paths[road_index]
		var length := _path_length(road)
		var count := maxi(int(ceil(length / 9.0)), 1)
		var previous := -1
		for i in count + 1:
			var point: Vector2 = _sample_path(road, length * i / count)[0]
			var index := waypoints.size()
			waypoints.append(point)
			waypoint_links.append(PackedInt32Array())
			road_of.append(road_index)
			if previous >= 0:
				_link(previous, index)
			previous = index
	# Kreuzungen: Punkte verschiedener Straßen, die nah beieinander liegen.
	var grid: Dictionary[Vector2i, PackedInt32Array] = {}
	for i in waypoints.size():
		var cell := Vector2i(floori(waypoints[i].x / 10.0), floori(waypoints[i].y / 10.0))
		if not grid.has(cell):
			grid[cell] = PackedInt32Array()
		grid[cell].append(i)
	for i in waypoints.size():
		var cell := Vector2i(floori(waypoints[i].x / 10.0), floori(waypoints[i].y / 10.0))
		for dx in range(-1, 2):
			for dz in range(-1, 2):
				for j in grid.get(cell + Vector2i(dx, dz), PackedInt32Array()):
					if j > i and road_of[j] != road_of[i] and waypoints[i].distance_to(waypoints[j]) < 8.0:
						_link(i, j)
	# Plätze: alle Punkte am Platz untereinander verbinden.
	for plaza in layout.plazas:
		var around: Array[int] = []
		for i in waypoints.size():
			if waypoints[i].distance_to(Vector2(plaza.x, plaza.y)) < plaza.z + 6.0:
				around.append(i)
		for a in around:
			for b in around:
				if a < b and road_of[a] != road_of[b]:
					_link(a, b)
	for point in waypoints:
		waypoint_districts.append(district_at(point).id if is_inside_city(point) else &"")


func _link(a: int, b: int) -> void:
	if not waypoint_links[a].has(b):
		waypoint_links[a].append(b)
		waypoint_links[b].append(a)


## Nächster Wegpunkt zu einer Position (oder -1, wenn es keine gibt).
func nearest_waypoint(point: Vector2, district_id: StringName = &"") -> int:
	var best := -1
	var best_distance := INF
	for i in waypoints.size():
		if district_id != &"" and waypoint_districts[i] != district_id:
			continue
		var distance := point.distance_squared_to(waypoints[i])
		if distance < best_distance:
			best_distance = distance
			best = i
	return best


## Steht an diesem Punkt nichts im Weg (kein Haus, kein Wahrzeichen)?
func is_free(point: Vector2, radius: float = 0.6) -> bool:
	return Geometry2D.is_point_in_polygon(point, boundary) \
		and not _hits_footprint(Footprint.new(point, Vector2(radius, radius) * 2.0, 0.0))


## Mitte eines Bezirks (Weltkoordinaten x, z).
func get_district_center(district_id: StringName) -> Vector2:
	for district in layout.districts:
		if district.id == district_id:
			return district.center
	return Vector2.ZERO


# --- Belegung (wo schon etwas steht) ---

func _cell_of(point: Vector2) -> Vector2i:
	return Vector2i(floori(point.x / CELL), floori(point.y / CELL))


func _cells_in(box: Rect2) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	var from := _cell_of(box.position)
	var to := _cell_of(box.end)
	for x in range(from.x, to.x + 1):
		for z in range(from.y, to.y + 1):
			result.append(Vector2i(x, z))
	return result


func _occupy(footprint: Footprint) -> void:
	var r := footprint.bounding_radius()
	for cell in _cells_in(Rect2(footprint.center - Vector2(r, r), Vector2(r, r) * 2.0)):
		if not _cells.has(cell):
			_cells[cell] = []
		_cells[cell].append(footprint)


func _in_clear_circle(point: Vector2, margin: float) -> bool:
	for circle in _clear_circles:
		if point.distance_to(Vector2(circle.x, circle.y)) < circle.z + margin:
			return true
	return false


func _hits_footprint(footprint: Footprint) -> bool:
	var r := footprint.bounding_radius()
	for cell in _cells_in(Rect2(footprint.center - Vector2(r, r), Vector2(r, r) * 2.0)):
		for other: Footprint in _cells.get(cell, []):
			if _overlaps(footprint, other):
				return true
	return false


## Darf hier gebaut werden? (In der Stadt, nicht auf Straßen, Plätzen, anderen Häusern.)
func _can_place(footprint: Footprint, road_margin: float = 0.4) -> bool:
	for corner in footprint.corners():
		if not is_inside_city(corner):
			return false
	for circle in _clear_circles:
		var local := footprint.to_local(Vector2(circle.x, circle.y))
		var nearest := local.clamp(-footprint.half, footprint.half)
		if local.distance_to(nearest) < circle.z:
			return false
	if _hits_road(footprint, road_margin):
		return false
	return not _hits_footprint(footprint)


func _hits_road(footprint: Footprint, margin: float) -> bool:
	var r := footprint.bounding_radius()
	for cell in _cells_in(Rect2(footprint.center - Vector2(r, r), Vector2(r, r) * 2.0)):
		var entries: Array = _road_cells.get(cell, [])
		for i in range(0, entries.size(), 2):
			var a: Vector3 = entries[i]
			var b: Vector3 = entries[i + 1]
			var grown := footprint.half + Vector2(a.z + margin, a.z + margin)
			if _segment_hits_box(footprint.to_local(Vector2(a.x, a.y)), footprint.to_local(Vector2(b.x, b.y)), grown):
				return true
	return false


## Schneidet die Strecke a–b das Rechteck (Mitte 0, halbe Größe `half`)?
static func _segment_hits_box(a: Vector2, b: Vector2, half: Vector2) -> bool:
	var t_min := 0.0
	var t_max := 1.0
	var direction := b - a
	for axis in 2:
		var start := a[axis]
		var delta := direction[axis]
		if absf(delta) < 0.00001:
			if start < -half[axis] or start > half[axis]:
				return false
			continue
		var t1 := (-half[axis] - start) / delta
		var t2 := (half[axis] - start) / delta
		t_min = maxf(t_min, minf(t1, t2))
		t_max = minf(t_max, maxf(t1, t2))
		if t_min > t_max:
			return false
	return true


## Überlappen sich zwei gedrehte Rechtecke? (Trennachsen-Test)
static func _overlaps(a: Footprint, b: Footprint) -> bool:
	if a.center.distance_to(b.center) > a.bounding_radius() + b.bounding_radius():
		return false
	var corners_a := a.corners()
	var corners_b := b.corners()
	for axis: Vector2 in [a.axis_x(), a.axis_z(), b.axis_x(), b.axis_z()]:
		var min_a := INF
		var max_a := -INF
		var min_b := INF
		var max_b := -INF
		for corner in corners_a:
			var p := corner.dot(axis)
			min_a = minf(min_a, p)
			max_a = maxf(max_a, p)
		for corner in corners_b:
			var p := corner.dot(axis)
			min_b = minf(min_b, p)
			max_b = maxf(max_b, p)
		if max_a <= min_b or max_b <= min_a:
			return false
	return true


func _reserve_keep_clear() -> void:
	_clear_circles.append(Vector3(layout.spawn_point.x, layout.spawn_point.z, KEEP_CLEAR_RADIUS))
	for root in keep_clear:
		if root == null:
			continue
		for node in root.find_children("*", "Node3D", false, false):
			var spot := node as Node3D
			# Größere Dinge (z. B. ein Haus aus der Level-Szene) geben ihren Radius selbst an.
			var radius: float = spot.get_meta(&"clear_radius", KEEP_CLEAR_RADIUS)
			_clear_circles.append(Vector3(spot.global_position.x, spot.global_position.z, radius))


# --- Häuser verteilen ---

## Häuser rund um die Plätze, mit der Front zum Platz.
func _place_around_plazas() -> void:
	for plaza in layout.plazas:
		var center := Vector2(plaza.x, plaza.y)
		var start := _rng.randf_range(0.0, TAU)
		var angle := start
		while angle < start + TAU:
			var direction := Vector2.from_angle(angle)
			var district := district_at(center + direction * (plaza.z + 5.0))
			var spec := _pick_spec(district, center)
			var size: Vector3 = spec["size"]
			var distance := plaza.z + _rng.randf_range(district.setback.x, district.setback.y) + size.z / 2.0 + 0.5
			var footprint := Footprint.new(center + direction * distance, Vector2(size.x, size.z), angle + PI / 2.0)
			_try_build(footprint, district, spec)
			angle += (size.x + _rng.randf_range(district.gap.x, district.gap.y)) / distance


## Häuserzeilen entlang beider Straßenseiten, die Front zur Straße.
func _place_along_roads() -> void:
	for road_index in road_paths.size():
		var road := road_paths[road_index]
		var half := road_widths[road_index] / 2.0
		var length := _path_length(road)
		for side: float in [-1.0, 1.0]:
			var along := _rng.randf_range(0.0, 4.0)
			while along < length:
				var sample := _sample_path(road, along)
				var point: Vector2 = sample[0]
				var tangent: Vector2 = sample[1]
				var normal := tangent.orthogonal() * side
				var district := district_at(point + normal * (half + 6.0))
				if _rng.randf() < district.empty_chance:
					if is_inside_city(point + normal * (half + 4.0)):
						_add_plants(_v3(point + normal * (half + 4.0)), 2)
					along += _rng.randf_range(5.0, 12.0)
					continue
				var spec := _pick_spec(district, point)
				var size: Vector3 = spec["size"]
				var setback := _rng.randf_range(district.setback.x, district.setback.y)
				var footprint := Footprint.new(point + normal * (half + setback + size.z / 2.0) + tangent * size.x / 2.0,
					Vector2(size.x, size.z), tangent.angle() + (PI if side > 0.0 else 0.0) + _jitter(district))
				if not _try_build(footprint, district, spec):
					along += 2.0
					continue
				along += size.x + _rng.randf_range(district.gap.x, district.gap.y)


## Füllt Lücken zwischen den Straßen (Hinterhäuser, Hütten in der Senke).
func _place_infill() -> void:
	var box := Rect2(outline[0], Vector2.ZERO)
	for point in outline:
		box = box.expand(point)
	var tries := int(box.get_area() / 14.0)
	for i in tries:
		var point := Vector2(_rng.randf_range(box.position.x, box.end.x), _rng.randf_range(box.position.y, box.end.y))
		if not is_inside_city(point):
			continue
		var district := district_at(point)
		# Außerhalb der Senke bleiben Hinterhöfe öfter frei.
		if district.kind != CityDistrict.Kind.SLUM and _rng.randf() < 0.55:
			continue
		var spec := _pick_spec(district, point)
		var size: Vector3 = spec["size"]
		var footprint := Footprint.new(point, Vector2(size.x, size.z), _nearest_road_angle(point) + _jitter(district))
		_try_build(footprint, district, spec)


func _jitter(district: CityDistrict) -> float:
	match district.style:
		CityDistrict.Style.IMPERIAL:
			return 0.0
		CityDistrict.Style.SLUM:
			return _rng.randf_range(-0.35, 0.35)
	return _rng.randf_range(-0.06, 0.06)


func _try_build(footprint: Footprint, district: CityDistrict, spec: Dictionary) -> bool:
	if not _can_place(footprint):
		# Zweiter Versuch: etwas kleiner.
		footprint.half *= 0.7
		if footprint.half.x < 1.4 or footprint.half.y < 1.2 or not _can_place(footprint):
			return false
	_occupy(footprint)
	_build(footprint, district, spec)
	return true


## Wählt Bauform und Größe passend zum Bezirk und zur Gegend (arm/reich).
func _pick_spec(district: CityDistrict, point: Vector2) -> Dictionary:
	var rich := richness_at(point)
	var height := _rng.randf_range(lerpf(district.height_poor.x, district.height_rich.x, rich),
		lerpf(district.height_poor.y, district.height_rich.y, rich))
	var roll := _rng.randf()
	if _rng.randf() < district.ruin_chance * (1.2 - rich):
		return _spec(&"ruin", _rng.randf_range(4.0, 9.0), height, _rng.randf_range(4.0, 8.0))
	match district.style:
		CityDistrict.Style.SLUM:
			if roll < 0.5:
				return _spec(&"shack", _rng.randf_range(3.0, 6.0), _rng.randf_range(2.4, 4.0), _rng.randf_range(3.0, 5.5))
			if roll < 0.68:
				return _spec(&"container", 6.1, 2.6, 2.5)
			if roll < 0.82:
				return _spec(&"shack_tower", _rng.randf_range(4.0, 6.0), _rng.randf_range(6.5, 11.0), _rng.randf_range(4.0, 6.0))
			if roll < 0.92:
				return _spec(&"lean_to", _rng.randf_range(3.0, 5.0), _rng.randf_range(2.2, 3.0), _rng.randf_range(2.5, 3.5))
			return _spec(&"tenement", _rng.randf_range(7.0, 11.0), _rng.randf_range(8.0, 14.0), _rng.randf_range(7.0, 10.0))
		CityDistrict.Style.MARKET:
			return _spec(&"shophouse", _rng.randf_range(5.0, 8.0), height, _rng.randf_range(6.0, 9.0))
		CityDistrict.Style.IMPERIAL:
			if roll < 0.45:
				return _kit_spec(&"kit_tower", KIT_TOWERS, _rng.randf_range(14.0, 20.0), height)
			if roll < 0.9:
				return _spec(&"monument_block", _rng.randf_range(16.0, 24.0), _rng.randf_range(16.0, 26.0), _rng.randf_range(12.0, 18.0))
			return _kit_spec(&"kit_block", KIT_BLOCKS, _rng.randf_range(16.0, 24.0), height * 0.6)
	# Glaubensviertel und modernes Viertel: in reichen Straßen auch große Blöcke.
	if rich > 0.55 and roll < 0.3:
		if _rng.randf() < 0.6:
			return _kit_spec(&"kit_block", KIT_BLOCKS, _rng.randf_range(12.0, 18.0), height * 1.6)
		return _kit_spec(&"kit_midrise", KIT_MIDRISE, _rng.randf_range(10.0, 15.0), height * 1.8)
	match district.style:
		CityDistrict.Style.CHRISTIAN:
			if roll < 0.75:
				return _spec(&"gable_house", _rng.randf_range(6.0, 9.0), height, _rng.randf_range(7.0, 11.0))
			return _spec(&"tower_house", _rng.randf_range(5.0, 7.0), height * 1.4, _rng.randf_range(5.0, 7.0))
		CityDistrict.Style.MUSLIM:
			if roll < 0.4:
				return _spec(&"courtyard_house", _rng.randf_range(10.0, 14.0), height * 0.8, _rng.randf_range(10.0, 14.0))
			return _spec(&"flat_house", _rng.randf_range(6.0, 10.0), height, _rng.randf_range(6.0, 10.0))
		CityDistrict.Style.JEWISH:
			if roll < 0.7:
				return _spec(&"stone_row", _rng.randf_range(6.0, 9.0), height, _rng.randf_range(8.0, 11.0))
			return _spec(&"courtyard_house", _rng.randf_range(10.0, 13.0), height * 0.8, _rng.randf_range(10.0, 13.0))
	if roll < 0.6:
		return _spec(&"cube_stack", _rng.randf_range(7.0, 11.0), height, _rng.randf_range(7.0, 11.0))
	return _kit_spec(&"kit_midrise", KIT_MIDRISE, _rng.randf_range(8.0, 12.0), height * 1.5)


func _spec(kind: StringName, width: float, height: float, depth: float) -> Dictionary:
	return {"kind": kind, "size": Vector3(width, height, depth)}


## Bauform aus der Blender-Vorlage: Größe aus den echten Proportionen.
func _kit_spec(kind: StringName, kit: Dictionary[String, Vector3], scale: float, height: float) -> Dictionary:
	var names := kit.keys()
	var model: String = names[_rng.randi() % names.size()]
	var shape: Vector3 = kit[model]
	var natural := shape.y * scale
	var final_height := clampf(height, natural * 0.7, natural * 1.4)
	return {"kind": kind, "model": model, "size": Vector3(shape.x * scale, final_height, shape.z * scale)}


# --- Bauformen ---

func _build(footprint: Footprint, district: CityDistrict, spec: Dictionary) -> void:
	var kind: StringName = spec["kind"]
	var size: Vector3 = spec["size"]
	size.x = footprint.half.x * 2.0
	size.z = footprint.half.y * 2.0
	var root := Node3D.new()
	root.position = _v3(footprint.center)
	root.rotation.y = -footprint.angle
	add_child(root)
	var color := _wall_color(district)
	match kind:
		&"ruin":
			_build_ruin(root, size, color)
		&"shack":
			_build_shack(root, size, color)
		&"container":
			_build_container(root, size)
		&"shack_tower":
			_build_shack_tower(root, size, color)
		&"lean_to":
			_build_lean_to(root, size, color)
		&"tenement":
			_build_tenement(root, size, color)
		&"shophouse":
			_build_shophouse(root, size, color)
		&"monument_block":
			_build_monument_block(root, size, color)
		&"kit_tower", &"kit_block", &"kit_midrise":
			_build_kit(root, size, color, spec["model"], kind == &"kit_tower" and district.style == CityDistrict.Style.IMPERIAL)
		&"gable_house":
			_build_gable_house(root, size, color, district.roof_color)
		&"tower_house":
			_build_tower_house(root, size, color, district.roof_color)
		&"courtyard_house":
			if size.x >= 10.0 and size.z >= 8.0:
				_build_courtyard_house(root, size, color)
			else:
				_build_flat_house(root, size, color, district)
		&"flat_house":
			_build_flat_house(root, size, color, district)
		&"stone_row":
			_build_stone_row(root, size, color)
		_:
			_build_cube_stack(root, size, color)
	if district.neon and size.y > 20.0:
		_add_neon_bands(root, size)
	if kind != &"ruin":
		_add_vines(root, size, district.vines_per_building)
	building_count += 1
	kind_counts[kind] = kind_counts.get(kind, 0) + 1
	if map_data:
		map_data.add_polygon(footprint.corners(), color.darkened(0.3 if kind == &"ruin" else 0.2))


func _wall_color(district: CityDistrict) -> Color:
	var color := district.wall_colors[_rng.randi() % district.wall_colors.size()]
	return color.darkened(_rng.randf_range(0.0, 0.15))


func _build_ruin(root: Node3D, size: Vector3, color: Color) -> void:
	color = color.darkened(0.35)
	var height_a := _rng.randf_range(1.5, 5.0)
	var wall := _part(root, Vector3(-size.x * 0.25, height_a / 2.0, 0.0), Vector3(size.x * 0.5, height_a, size.z), color, 0.0)
	wall.rotation.z = _rng.randf_range(-0.08, 0.08)
	var height_b := _rng.randf_range(0.8, 3.0)
	_part(root, Vector3(size.x * 0.25, height_b / 2.0, -size.z * 0.15), Vector3(size.x * 0.45, height_b, size.z * 0.6), color.darkened(0.1), 0.0)
	for i in _rng.randi_range(3, 6):
		var rubble := Vector3(_rng.randf_range(0.3, 1.2), _rng.randf_range(0.2, 0.8), _rng.randf_range(0.3, 1.2))
		var at := Vector3(_rng.randf_range(-size.x, size.x) * 0.5, rubble.y / 2.0, _rng.randf_range(-size.z, size.z) * 0.5)
		var piece := _detail_box(root, at, rubble, color.darkened(0.2))
		piece.rotation.y = _rng.randf_range(0.0, TAU)
	_add_vines(root, Vector3(size.x, height_a, size.z), 4.0)
	_add_plants(root.position, 3)


## Hütte: Wellblechdach schräg, manchmal ein zweiter, versetzter Stock.
func _build_shack(root: Node3D, size: Vector3, color: Color) -> void:
	_part(root, Vector3(0, size.y / 2.0, 0), size, color, 0.25, Vector2(2.2, 2.6))
	_tilted_roof(root, Vector3(0, size.y, 0), size, _rust_color())
	if _rng.randf() < 0.35:
		var upper := Vector3(size.x * _rng.randf_range(0.5, 0.8), _rng.randf_range(2.0, 2.8), size.z * _rng.randf_range(0.5, 0.8))
		var shift := _rng.randf_range(-0.2, 0.2) * size.x
		_part(root, Vector3(shift, size.y + upper.y / 2.0, 0), upper, _patch_color(color), 0.3, Vector2(2.2, 2.6))
		_tilted_roof(root, Vector3(shift, size.y + upper.y, 0), upper, _rust_color())
	if _rng.randf() < 0.3:
		# Flicken aus anderem Blech.
		_detail_box(root, Vector3(_rng.randf_range(-0.3, 0.3) * size.x, size.y * 0.4, -size.z / 2.0 - 0.04),
			Vector3(_rng.randf_range(0.8, 1.6), _rng.randf_range(0.8, 1.4), 0.06), _rust_color())
	if _rng.randf() < 0.2:
		_detail_box(root, Vector3(size.x * 0.3, size.y + 1.2, 0), Vector3(0.06, 2.4, 0.06), Color(0.2, 0.2, 0.22))


## Gestapelte Container, als Wohnung genutzt.
func _build_container(root: Node3D, size: Vector3) -> void:
	var levels := _rng.randi_range(1, 3)
	var colors: Array[Color] = [Color(0.55, 0.22, 0.16), Color(0.2, 0.35, 0.45), Color(0.6, 0.5, 0.2), Color(0.3, 0.42, 0.3)]
	for level in levels:
		var shift := _rng.randf_range(-0.6, 0.6) if level > 0 else 0.0
		var color := colors[_rng.randi() % colors.size()].darkened(_rng.randf_range(0.0, 0.3))
		var box := _part(root, Vector3(shift, size.y * (level + 0.5), 0), size, color, 0.15, Vector2(3.0, 2.6))
		if level > 0:
			box.rotation.y = _rng.randf_range(-0.15, 0.15)


## Turm aus übereinandergestapelten Hütten, mit Leiter.
func _build_shack_tower(root: Node3D, size: Vector3, color: Color) -> void:
	var y := 0.0
	var floor_size := Vector2(size.x, size.z)
	while y < size.y - 1.5:
		var height := _rng.randf_range(2.2, 3.0)
		var offset := Vector3(_rng.randf_range(-0.4, 0.4), y + height / 2.0, _rng.randf_range(-0.4, 0.4)) if y > 0.0 else Vector3(0, height / 2.0, 0)
		_part(root, offset, Vector3(floor_size.x, height, floor_size.y), _patch_color(color), 0.3, Vector2(2.2, 2.6))
		y += height
		floor_size *= _rng.randf_range(0.8, 1.0)
	_tilted_roof(root, Vector3(0, y, 0), Vector3(floor_size.x, 0, floor_size.y), _rust_color())
	_detail_box(root, Vector3(size.x / 2.0 + 0.1, y / 2.0, 0), Vector3(0.1, y, 0.6), Color(0.25, 0.22, 0.2))


## Verschlag: drei Wände und ein Planendach.
func _build_lean_to(root: Node3D, size: Vector3, color: Color) -> void:
	_part(root, Vector3(0, size.y / 2.0, size.z / 2.0 - 0.1), Vector3(size.x, size.y, 0.2), color, 0.0)
	_part(root, Vector3(-size.x / 2.0 + 0.1, size.y / 2.0, 0), Vector3(0.2, size.y, size.z), color, 0.0)
	_part(root, Vector3(size.x / 2.0 - 0.1, size.y / 2.0, 0), Vector3(0.2, size.y, size.z), color, 0.0)
	var tarp_colors: Array[Color] = [Color(0.2, 0.35, 0.55), Color(0.55, 0.25, 0.2), Color(0.35, 0.45, 0.25)]
	_tilted_roof(root, Vector3(0, size.y, 0), size, tarp_colors[_rng.randi() % tarp_colors.size()])


## Altes Mietshaus mit Anbauten und Balkonen aus Blech.
func _build_tenement(root: Node3D, size: Vector3, color: Color) -> void:
	_part(root, Vector3(0, size.y / 2.0, 0), size, color.darkened(0.1), 0.7)
	for i in _rng.randi_range(2, 4):
		var y := _rng.randf_range(3.0, size.y - 1.0)
		var side := 1.0 if _rng.randf() < 0.5 else -1.0
		_detail_box(root, Vector3(_rng.randf_range(-0.3, 0.3) * size.x, y, side * (size.z / 2.0 + 0.6)),
			Vector3(_rng.randf_range(2.0, 3.5), 0.15, 1.2), _rust_color())
	if _rng.randf() < 0.6:
		var shed := Vector3(3.0, 2.4, 3.0)
		_part(root, Vector3(size.x * 0.2, size.y + shed.y / 2.0, 0), shed, _patch_color(color), 0.3)
		_tilted_roof(root, Vector3(size.x * 0.2, size.y + shed.y, 0), shed, _rust_color())


## Händlerhaus am Markt: Laden unten mit Markise, Leuchtschild.
func _build_shophouse(root: Node3D, size: Vector3, color: Color) -> void:
	_part(root, Vector3(0, size.y / 2.0, 0), size, color, 0.6)
	var awning_colors: Array[Color] = [Color(0.85, 0.3, 0.3), Color(0.95, 0.7, 0.2), Color(0.3, 0.55, 0.9), Color(0.4, 0.8, 0.45), Color(0.75, 0.35, 0.8)]
	var awning := _detail_box(root, Vector3(0, 2.8, -size.z / 2.0 - 0.8), Vector3(size.x * 0.9, 0.12, 1.8), awning_colors[_rng.randi() % awning_colors.size()])
	awning.rotation.x = 0.25
	if _rng.randf() < 0.6:
		var neon_colors: Array[Color] = [Color(1.0, 0.25, 0.6), Color(0.2, 0.85, 1.0), Color(1.0, 0.7, 0.2)]
		_glow_box(root, Vector3(0, 4.2, -size.z / 2.0 - 0.1), Vector3(size.x * 0.5, 0.7, 0.1), neon_colors[_rng.randi() % neon_colors.size()], 1.4)


## Imperialer Konzernbau: Sockel, Säulenfront, Gesims, Banner.
func _build_monument_block(root: Node3D, size: Vector3, color: Color) -> void:
	var stone := color.lightened(0.15)
	_part(root, Vector3(0, 0.6, 0), Vector3(size.x, 1.2, size.z), stone.darkened(0.2), 0.0)
	var body := Vector3(size.x * 0.82, size.y, size.z * 0.7)
	_part(root, Vector3(0, 1.2 + body.y / 2.0, size.z * 0.12), body, stone, 0.5, Vector2(3.5, 4.5))
	var columns := maxi(int(body.x / 3.5), 4)
	var front := size.z * 0.12 - body.z / 2.0 - 1.6
	for i in columns:
		var x := lerpf(-body.x / 2.0 + 1.0, body.x / 2.0 - 1.0, float(i) / (columns - 1))
		_column(root, Vector3(x, 1.2, front), body.y * 0.7, 0.55, stone.lightened(0.1))
	_part(root, Vector3(0, 1.2 + body.y * 0.7 + 0.6, front + 0.8), Vector3(body.x, 1.2, 3.0), stone.darkened(0.05), 0.0)
	_part(root, Vector3(0, 1.2 + body.y + 0.5, size.z * 0.12), Vector3(body.x + 1.0, 1.0, body.z + 1.0), stone.darkened(0.25), 0.0)
	_banner(root, Vector3(0, 1.2 + body.y * 0.45, front - 0.6), body.y * 0.5)


## Hochhaus oder Block aus der Blender-Vorlage. Konzerntürme stehen auf einem
## gestuften Sockel und tragen Banner.
func _build_kit(root: Node3D, size: Vector3, color: Color, model: String, plinth: bool) -> void:
	var base_y := 0.0
	if plinth:
		var steps := 3
		for i in steps:
			var grow := 1.0 + (steps - i) * 0.12
			var step_size := Vector3(size.x * grow, 1.2, size.z * grow)
			_part(root, Vector3(0, base_y + 0.6, 0), step_size, color.lightened(0.25).darkened(i * 0.08), 0.0)
			base_y += 1.2
	var shape: Vector3 = KIT_TOWERS.get(model, KIT_BLOCKS.get(model, KIT_MIDRISE.get(model, Vector3.ONE)))
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.mesh = _kit_mesh(model)
	mesh_instance.material_override = _building_material
	mesh_instance.position = Vector3(0, base_y, 0)
	mesh_instance.scale = Vector3(size.x / shape.x, size.y / shape.y, size.z / shape.z)
	root.add_child(mesh_instance)
	_paint(mesh_instance, color, 0.7, 0.4)
	_add_collision(root, Vector3(0, base_y + size.y / 2.0, 0), size * Vector3(0.95, 1.0, 0.95))
	if plinth:
		_banner(root, Vector3(0, base_y + size.y * 0.3, -size.z / 2.0 - 0.3), size.y * 0.3)


func _build_gable_house(root: Node3D, size: Vector3, color: Color, roof: Color) -> void:
	_part(root, Vector3(0, size.y / 2.0, 0), size, color, 0.55)
	_gable_roof(root, Vector3(0, size.y, 0), size, roof.darkened(_rng.randf_range(0.0, 0.2)))
	if _rng.randf() < 0.4:
		_part(root, Vector3(size.x * 0.25, size.y + minf(size.x, size.z) * 0.25, size.z * 0.15), Vector3(0.8, minf(size.x, size.z) * 0.5, 0.8), color.darkened(0.2), 0.0)
	if _rng.randf() < 0.3:
		# Erker zur Straße.
		var bay := Vector3(size.x * 0.35, size.y * 0.35, 1.0)
		_part(root, Vector3(0, size.y * 0.55, -size.z / 2.0 - 0.5), bay, color.lightened(0.05), 0.8)


func _build_tower_house(root: Node3D, size: Vector3, color: Color, roof: Color) -> void:
	_part(root, Vector3(0, size.y / 2.0, 0), size, color, 0.5)
	_add_prism_to(root, Vector3(0, size.y + size.x * 0.5, 0), Vector3(size.x + 0.4, size.x, size.z + 0.4), roof)


## Hofhaus: Gebäude rund um einen Innenhof, Eingang mit Bogen zur Straße.
func _build_courtyard_house(root: Node3D, size: Vector3, color: Color) -> void:
	var wall := 3.0
	_part(root, Vector3(0, size.y / 2.0, size.z / 2.0 - wall / 2.0), Vector3(size.x, size.y, wall), color, 0.5)
	_part(root, Vector3(-size.x / 2.0 + wall / 2.0, size.y / 2.0, -wall / 2.0), Vector3(wall, size.y, size.z - wall), color, 0.5)
	_part(root, Vector3(size.x / 2.0 - wall / 2.0, size.y / 2.0, -wall / 2.0), Vector3(wall, size.y, size.z - wall), color, 0.5)
	var front_h := size.y * 0.55
	var front_w := (size.x - 2.0 * wall) / 2.0 - 1.0
	_part(root, Vector3(-front_w / 2.0 - 1.0, front_h / 2.0, -size.z / 2.0 + 0.4), Vector3(front_w, front_h, 0.8), color.darkened(0.05), 0.0)
	_part(root, Vector3(front_w / 2.0 + 1.0, front_h / 2.0, -size.z / 2.0 + 0.4), Vector3(front_w, front_h, 0.8), color.darkened(0.05), 0.0)
	_part(root, Vector3(0, front_h - 0.4, -size.z / 2.0 + 0.4), Vector3(2.0, 0.8, 0.8), color.darkened(0.1), 0.0)
	# Brunnen oder leuchtender Baum im Hof.
	if _rng.randf() < 0.5:
		_glow_sphere(root, Vector3(0, 1.8, 0), 1.2, VINE_COLORS[_rng.randi() % VINE_COLORS.size()], 0.8)
		_detail_cylinder(root, Vector3(0, 0.9, 0), 0.15, 0.2, 1.8, Color(0.3, 0.22, 0.18))
	else:
		_detail_cylinder(root, Vector3(0, 0.35, 0), 1.0, 1.1, 0.7, color.darkened(0.2))


## Flachdachhaus mit Brüstung; manchmal eine kleine Kuppel oder ein Dachgarten.
func _build_flat_house(root: Node3D, size: Vector3, color: Color, district: CityDistrict) -> void:
	_part(root, Vector3(0, size.y / 2.0, 0), size, color, 0.5)
	_parapet(root, size, color.darkened(0.1))
	var roll := _rng.randf()
	if roll < 0.15:
		_dome(root, Vector3(0, size.y, 0), minf(size.x, size.z) * 0.3, district.roof_color.lightened(0.2))
	elif roll < 0.4:
		_add_plants(root.position + Vector3(0, size.y, 0), 2)


## Steinhaus in der Zeile, mit Balkonen und Simsen.
func _build_stone_row(root: Node3D, size: Vector3, color: Color) -> void:
	_part(root, Vector3(0, size.y / 2.0, 0), size, color, 0.6, Vector2(2.4, 3.4))
	var floors := int(size.y / 3.4)
	for i in range(1, floors):
		_detail_box(root, Vector3(0, i * 3.4, -size.z / 2.0 - 0.15), Vector3(size.x + 0.1, 0.25, 0.3), color.darkened(0.2))
		if _rng.randf() < 0.4:
			_detail_box(root, Vector3(_rng.randf_range(-0.2, 0.2) * size.x, i * 3.4 + 0.05, -size.z / 2.0 - 0.7), Vector3(2.4, 0.15, 1.2), color.darkened(0.3))
	_parapet(root, size, color.darkened(0.15))
	if _rng.randf() < 0.25:
		_add_plants(root.position + Vector3(0, size.y, 0), 2)


## Modernes Haus: versetzt gestapelte Würfel mit Glasbändern.
func _build_cube_stack(root: Node3D, size: Vector3, color: Color) -> void:
	var levels := _rng.randi_range(2, 3)
	var level_height := size.y / levels
	for level in levels:
		var scale := _rng.randf_range(0.7, 1.0) if level > 0 else 1.0
		var shift := Vector3(_rng.randf_range(-0.15, 0.15) * size.x, 0, _rng.randf_range(-0.15, 0.15) * size.z) if level > 0 else Vector3.ZERO
		shift.y = level_height * (level + 0.5)
		var box := Vector3(size.x * scale, level_height, size.z * scale)
		_part(root, shift, box, color if level % 2 == 0 else color.lightened(0.1), 0.8, Vector2(1.6, level_height))
		_glow_box(root, shift + Vector3(0, level_height * 0.45, 0), Vector3(box.x + 0.05, 0.12, box.z + 0.05), Color(0.5, 0.8, 1.0), 0.6)


# --- Wahrzeichen ---

## Wahrzeichen reservieren, bevor Gassen entstehen (damit keine hindurchführt).
func _reserve_landmarks() -> void:
	for district in layout.districts:
		if district.worship != CityDistrict.Worship.NONE:
			_clear_circles.append(Vector3(district.landmark_position.x, district.landmark_position.y, 16.0))
		if district.kind == CityDistrict.Kind.CORPORATE:
			_occupy(Footprint.new(_citadel_center() + Vector2(0, 1), Vector2(64, 50), 0.0))
			var area := _barracks_area()
			_occupy(Footprint.new(area.get_center(), area.size + Vector2(6, 6), 0.0))


func _citadel_center() -> Vector2:
	for district in layout.districts:
		if district.kind == CityDistrict.Kind.CORPORATE:
			return district.landmark_position
	return Vector2(0, -160)


func _barracks_area() -> Rect2:
	var center := _citadel_center() + Vector2(85, 22)
	return Rect2(center - Vector2(22, 17), Vector2(44, 34))


func _build_landmarks() -> void:
	for district in layout.districts:
		var at := _v3(district.landmark_position)
		match district.worship:
			CityDistrict.Worship.CHURCH:
				_build_church(at)
			CityDistrict.Worship.MOSQUE:
				_build_mosque(at)
			CityDistrict.Worship.SYNAGOGUE:
				_build_synagogue(at)
			CityDistrict.Worship.HOUSE_OF_SILENCE:
				_build_house_of_silence(at)
		if district.worship != CityDistrict.Worship.NONE:
			_add_disc(at + Vector3(0, 0.03, 0), 16.0, district.ground_color.lightened(0.18))
			if map_data:
				map_data.add_polygon(_circle_points(district.landmark_position, 16.0), district.ground_color.lightened(0.35))
		match district.kind:
			CityDistrict.Kind.MARKET:
				_build_market(district)
			CityDistrict.Kind.CORPORATE:
				_build_citadel()
				_build_boulevard()
				_build_barracks()


func _build_market(district: CityDistrict) -> void:
	var center := _v3(district.landmark_position)
	# Mystischer Baum in der Mitte.
	_cylinder(self, center + Vector3(0, 4, 0), 0.9, 1.3, 8.0, Color(0.35, 0.25, 0.2), true)
	for i in 6:
		var crown := center + Vector3(_rng.randf_range(-3, 3), _rng.randf_range(8.5, 11.0), _rng.randf_range(-3, 3))
		_glow_sphere(self, crown, _rng.randf_range(2.0, 3.0), Color(0.3, 0.95, 0.75), 0.8)
	# Marktstände im Kreis (lassen Platz für Händler und Spiegel).
	var stall_colors: Array[Color] = [Color(0.85, 0.3, 0.3), Color(0.95, 0.7, 0.2), Color(0.3, 0.55, 0.9), Color(0.4, 0.8, 0.45), Color(0.75, 0.35, 0.8)]
	for i in 14:
		var angle := TAU * i / 14.0 + 0.1
		var at := center + Vector3(cos(angle), 0, sin(angle)) * 19.0
		if _near_keep_clear(Vector2(at.x, at.z), 3.5):
			continue
		var stall := _box(self, at + Vector3(0, 0.6, 0), Vector3(3.0, 1.2, 1.6), Color(0.45, 0.32, 0.22), true)
		stall.rotation.y = -angle + PI / 2.0
		var canopy := _add_prism_to(self, at + Vector3(0, 2.6, 0), Vector3(3.4, 0.8, 2.2), stall_colors[i % stall_colors.size()])
		canopy.rotation.y = -angle + PI / 2.0
	_add_marker(center, MapMarker.Kind.MARKET, "Großer Markt")


## Die Konzern-Zitadelle: gestufter Sockel, gewaltiger Turm, vier Ecktürme.
func _build_citadel() -> void:
	var c := _citadel_center()
	var stone := Color(0.32, 0.3, 0.34)
	var y := 0.0
	var tiers: Array[Vector2] = [Vector2(62, 42), Vector2(50, 34), Vector2(38, 26)]
	for i in tiers.size():
		var tier := tiers[i]
		var body := _box(self, Vector3(c.x, y + 2.5, c.y), Vector3(tier.x, 5.0, tier.y), stone, true)
		_paint(body, stone.lightened(0.08 * i), 0.3, 0.2)
		y += 5.0
	# Breite Freitreppe nach Süden zur Prachtstraße.
	for i in 5:
		var step_h := 1.0 + i * 1.0
		_box(self, Vector3(c.x, step_h / 2.0, c.y + 21.0 + 2.5 - i * 0.6), Vector3(18.0, step_h, 1.2), stone.lightened(0.2), true)
	var tower := Node3D.new()
	tower.position = Vector3(c.x, y, c.y)
	add_child(tower)
	_build_kit(tower, Vector3(26.0, 125.0, 26.0), Color(0.2, 0.21, 0.26), "highrise_11", false)
	_glow_box(tower, Vector3(0, 127.0, 0), Vector3(12, 3, 12), IMPERIAL_RED, 2.0)
	_emblem(Vector3(c.x, y + 50.0, c.y + 14.0))
	_banner(tower, Vector3(-8.0, 25.0, 13.4), 30.0)
	_banner(tower, Vector3(8.0, 25.0, 13.4), 30.0)
	for corner: Vector2 in [Vector2(-25, -15), Vector2(25, -15), Vector2(-25, 15), Vector2(25, 15)]:
		var corner_tower := _box(self, Vector3(c.x + corner.x, 15.0, c.y + corner.y), Vector3(6.0, 30.0, 6.0), stone, true)
		_paint(corner_tower, stone.darkened(0.1), 0.5, 0.5)
		_glow_box(self, Vector3(c.x + corner.x, 30.6, c.y + corner.y), Vector3(6.4, 1.2, 6.4), IMPERIAL_RED, 1.5)
	_add_marker(Vector3(c.x, 0, c.y), MapMarker.Kind.CORPORATE_TOWER, "Konzern-Zitadelle")
	building_count += 1
	kind_counts[&"citadel"] = 1
	if map_data:
		map_data.add_rect(Rect2(c - Vector2(31, 21), Vector2(62, 42)), Color(0.6, 0.2, 0.25), "Zitadelle")


## Prachtstraße vom Markt zur Zitadelle: Säulengänge, Obelisken, Turmpaare.
func _build_boulevard() -> void:
	if layout.main_roads.is_empty():
		return
	var road := layout.main_roads[0]
	var half := layout.main_road_widths[0] / 2.0
	var length := _path_length(road)
	var stone := Color(0.55, 0.52, 0.5)
	var along := 12.0
	var step := 0
	while along < length - 4.0:
		var sample := _sample_path(road, along)
		var point: Vector2 = sample[0]
		var normal := (sample[1] as Vector2).orthogonal()
		for side: float in [-1.0, 1.0]:
			var at := point + normal * side * (half + 1.2)
			var spot := Footprint.new(at, Vector2(1.6, 1.6), 0.0)
			if road_clearance(at) > 0.2 and not _near_keep_clear(at, 1.5) and not _hits_footprint(spot):
				_occupy(spot)
				_column(self, _v3(at), 11.0, 0.6, stone)
		if step % 6 == 3 and not _near_keep_clear(point, 4.0):
			_obelisk(_v3(point))
		along += 6.0
		step += 1


## Turmpaare an der Prachtstraße, spiegelgleich links und rechts. Werden vor
## den Gassen gebaut, damit die Achse frei bleibt.
func _build_boulevard_towers() -> void:
	if layout.main_roads.is_empty() or layout.main_road_widths.is_empty():
		return
	var road := layout.main_roads[0]
	var half := layout.main_road_widths[0] / 2.0
	var length := _path_length(road)
	var tower_along := 14.0
	var names := KIT_TOWERS.keys()
	while tower_along < length - 6.0:
		var sample := _sample_path(road, tower_along)
		var point: Vector2 = sample[0]
		var tangent: Vector2 = sample[1]
		var model: String = names[_rng.randi() % names.size()]
		var shape: Vector3 = KIT_TOWERS[model]
		var scale := _rng.randf_range(13.0, 17.0)
		var size := Vector3(shape.x * scale, minf(shape.y * scale, 100.0), shape.z * scale)
		# Nur paarweise bauen (beide Seiten frei), sonst ein Stück weiter versuchen.
		var pair: Array[Footprint] = []
		for side: float in [-1.0, 1.0]:
			var normal := tangent.orthogonal() * side
			var angle := tangent.angle() + (PI if side > 0.0 else 0.0)
			var footprint := Footprint.new(point + normal * (half + 4.0 + size.z * 0.68), Vector2(size.x, size.z) * 1.36, angle)
			if _can_place(footprint, 1.0):
				pair.append(footprint)
		if pair.size() < 2:
			tower_along += 3.0
			continue
		for footprint in pair:
			_occupy(footprint)
			var root := Node3D.new()
			root.position = _v3(footprint.center)
			root.rotation.y = -footprint.angle
			add_child(root)
			_build_kit(root, size, Color(0.22, 0.23, 0.29), model, true)
			_add_neon_bands(root, size)
			building_count += 1
			kind_counts[&"imperial_tower"] = kind_counts.get(&"imperial_tower", 0) + 1
			if map_data:
				map_data.add_polygon(footprint.corners(), Color(0.55, 0.22, 0.27))
		tower_along += size.x * 1.36 + 4.0


func _build_barracks() -> void:
	var area := _barracks_area()
	var wall_color := Color(0.3, 0.3, 0.33)
	var c := area.get_center()
	# Festungsmauer mit Tor im Süden und Wachtürmen an den Ecken.
	_box(self, Vector3(c.x, 2.5, area.position.y), Vector3(area.size.x, 5, 1.2), wall_color, true)
	_box(self, Vector3(area.position.x, 2.5, c.y), Vector3(1.2, 5, area.size.y), wall_color, true)
	_box(self, Vector3(area.end.x, 2.5, c.y), Vector3(1.2, 5, area.size.y), wall_color, true)
	_box(self, Vector3(area.position.x + area.size.x * 0.2, 2.5, area.end.y), Vector3(area.size.x * 0.4, 5, 1.2), wall_color, true)
	_box(self, Vector3(area.end.x - area.size.x * 0.2, 2.5, area.end.y), Vector3(area.size.x * 0.4, 5, 1.2), wall_color, true)
	for corner: Vector2 in [area.position, Vector2(area.end.x, area.position.y), Vector2(area.position.x, area.end.y), area.end]:
		_box(self, Vector3(corner.x, 4.0, corner.y), Vector3(3.0, 8.0, 3.0), wall_color.darkened(0.1), true)
		_glow_box(self, Vector3(corner.x, 8.3, corner.y), Vector3(3.2, 0.5, 3.2), IMPERIAL_RED, 1.4)
	var hall := _box(self, Vector3(c.x - 8, 3.5, c.y - 6), Vector3(14, 7, 9), wall_color, true)
	_paint(hall, Color(0.35, 0.36, 0.4), 0.6, 0.6)
	var armory := _box(self, Vector3(c.x + 10, 2.5, c.y - 8), Vector3(10, 5, 7), wall_color, true)
	_paint(armory, Color(0.35, 0.36, 0.4), 0.4, 0.5)
	_banner(self, Vector3(c.x - 6, 3.0, area.end.y + 0.7), 5.0)
	_banner(self, Vector3(c.x + 6, 3.0, area.end.y + 0.7), 5.0)
	_add_marker(Vector3(c.x, 0, c.y), MapMarker.Kind.BARRACKS, "Kaserne")
	if map_data:
		map_data.add_rect(area, Color(0.45, 0.2, 0.22), "Kaserne")


func _build_church(center: Vector3) -> void:
	var wall := Color(0.82, 0.78, 0.7)
	var nave := _box(self, center + Vector3(0, 5, 2), Vector3(12, 10, 22), wall, true)
	_paint(nave, wall, 0.3, 0.6)
	_gable_roof(self, center + Vector3(0, 10, 2), Vector3(12, 10, 22), Color(0.6, 0.3, 0.22))
	_box(self, center + Vector3(0, 10, -11), Vector3(5, 20, 5), wall, true)
	_add_prism_to(self, center + Vector3(0, 23, -11), Vector3(5, 6, 5), Color(0.35, 0.4, 0.45))
	_glow_box(self, center + Vector3(0, 7, -13.6), Vector3(2.0, 3.0, 0.2), Color(1.0, 0.8, 0.5))
	_add_vines(nave, Vector3(12, 10, 22), 4.0, -5.0)
	_add_sign(center + Vector3(0, 3.5, -14.0), "Kirche")
	_add_marker(center, MapMarker.Kind.CHURCH, "Kirche")


func _build_mosque(center: Vector3) -> void:
	var wall := Color(0.92, 0.88, 0.8)
	var hall := _box(self, center + Vector3(0, 4, 0), Vector3(18, 8, 18), wall, true)
	_paint(hall, wall, 0.3, 0.6)
	_dome(self, center + Vector3(0, 8, 0), 7.0, Color(0.25, 0.6, 0.6))
	_cylinder(self, center + Vector3(10, 13, -10), 1.1, 1.3, 26.0, wall, true)
	_dome(self, center + Vector3(10, 26, -10), 1.6, Color(0.25, 0.6, 0.6))
	_glow_box(self, center + Vector3(0, 3.5, -9.1), Vector3(3.0, 5.0, 0.2), Color(0.5, 1.0, 0.85))
	_add_vines(hall, Vector3(18, 8, 18), 4.0, -4.0)
	_add_sign(center + Vector3(0, 7.0, -9.4), "Moschee")
	_add_marker(center, MapMarker.Kind.MOSQUE, "Moschee")


func _build_synagogue(center: Vector3) -> void:
	var wall := Color(0.85, 0.72, 0.55)
	var hall := _box(self, center + Vector3(0, 6, 0), Vector3(14, 12, 18), wall, true)
	_paint(hall, wall, 0.3, 0.6)
	_box(self, center + Vector3(0, 12.5, 0), Vector3(10, 1.0, 14), wall.darkened(0.15), true)
	_cylinder(self, center + Vector3(-4.5, 6, -9.3), 0.6, 0.6, 12.0, wall.lightened(0.1), true)
	_cylinder(self, center + Vector3(4.5, 6, -9.3), 0.6, 0.6, 12.0, wall.lightened(0.1), true)
	var disc := _glow_cylinder(self, center + Vector3(0, 8.5, -9.15), 2.0, 0.15, Color(0.6, 0.75, 1.0))
	disc.rotation.x = PI / 2.0
	_add_vines(hall, Vector3(14, 12, 18), 4.0, -6.0)
	_add_sign(center + Vector3(0, 3.5, -9.5), "Synagoge")
	_add_marker(center, MapMarker.Kind.SYNAGOGUE, "Synagoge")


func _build_house_of_silence(center: Vector3) -> void:
	var hall := _box(self, center + Vector3(0, 3, 0), Vector3(20, 6, 14), Color(0.75, 0.76, 0.78), true)
	var glass := _box(self, center + Vector3(0, 3, -7.05), Vector3(16, 4.5, 0.1), Color(0.5, 0.75, 0.95, 0.6), false, false)
	(glass.material_override as StandardMaterial3D).transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	for i in 4:
		_add_plants(center + Vector3(-9 + i * 6, 0, -10), 3)
	_add_vines(hall, Vector3(20, 6, 14), 5.0, -3.0)
	_add_sign(center + Vector3(0, 6.6, -7.2), "Haus der Stille")
	_add_marker(center, MapMarker.Kind.HOUSE_OF_SILENCE, "Haus der Stille")


# --- Boden, Straßen, Plätze, Natur, Rand ---

## Ein großer Boden mit weichen Farbübergängen zwischen den Bezirken.
func _build_ground() -> void:
	var box := Rect2(boundary[0], Vector2.ZERO)
	for point in boundary:
		box = box.expand(point)
	box = box.grow(80.0)
	var step := 6.0
	var columns := int(box.size.x / step) + 1
	var rows := int(box.size.y / step) + 1
	var colors := PackedColorArray()
	colors.resize((columns + 1) * (rows + 1))
	for row in rows + 1:
		for column in columns + 1:
			colors[row * (columns + 1) + column] = _ground_color_at(box.position + Vector2(column, row) * step)
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	tool.set_normal(Vector3.UP)
	for row in rows:
		for column in columns:
			var p := box.position + Vector2(column, row) * step
			var quad: Array[Vector2] = [p, p + Vector2(step, 0), p + Vector2(step, step), p + Vector2(0, step)]
			var ids: Array[int] = [row * (columns + 1) + column, row * (columns + 1) + column + 1,
				(row + 1) * (columns + 1) + column + 1, (row + 1) * (columns + 1) + column]
			for index: int in [0, 1, 2, 0, 2, 3]:
				tool.set_color(colors[ids[index]])
				tool.add_vertex(Vector3(quad[index].x, 0.0, quad[index].y))
	var material := ToonStyle.make(Color.WHITE, false)
	material.vertex_color_use_as_albedo = true
	var ground := MeshInstance3D.new()
	ground.mesh = tool.commit()
	ground.material_override = material
	ground.set_meta(&"no_batch", true)
	add_child(ground)
	_add_collision(self, Vector3(box.get_center().x, -0.5, box.get_center().y), Vector3(box.size.x, 1.0, box.size.y))


## Bezirke als unterste Flächen auf der Karte.
func _add_district_map() -> void:
	if map_data:
		map_data.add_polygon(boundary, WILD_COLOR.lightened(0.1))
		for district in layout.districts:
			map_data.add_polygon(_district_shape(district), district.ground_color.lightened(0.15), district.display_name, district.center)


func _ground_color_at(point: Vector2) -> Color:
	var color := district_at(point).ground_color if is_inside_city(point) else WILD_COLOR
	return color.darkened(_noise.get_noise_2d(point.x * 3.0, point.y * 3.0) * 0.12 + 0.02)


## Umriss eines Bezirks für die Karte (von der Mitte aus abgetastet).
func _district_shape(district: CityDistrict) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in 48:
		var direction := Vector2.from_angle(TAU * i / 48.0)
		var distance := 6.0
		while distance < 300.0:
			var point := district.center + direction * (distance + 6.0)
			if not is_inside_city(point) or district_at(point) != district:
				break
			distance += 6.0
		points.append(district.center + direction * distance)
	return points


func _build_roads() -> void:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	tool.set_normal(Vector3.UP)
	tool.set_color(ROAD_COLOR)
	for index in road_paths.size():
		var points := road_paths[index]
		var half := road_widths[index] / 2.0
		var y := 0.02 + index * 0.00002
		for i in points.size() - 1:
			var a := points[i]
			var b := points[i + 1]
			var forward := (b - a).normalized()
			var side := forward.orthogonal() * half
			# Etwas überlappen, damit an Knicken keine Lücken entstehen.
			var extra := forward * minf(half, 2.0)
			var quad: Array[Vector2] = [a - side - extra, b - side + extra, b + side + extra, a + side - extra]
			for k: int in [0, 1, 2, 0, 2, 3]:
				tool.add_vertex(Vector3(quad[k].x, y, quad[k].y))
		if map_data:
			map_data.add_line(points, road_widths[index], Color(0.08, 0.08, 0.1))
	var material := ToonStyle.make(ROAD_COLOR, false)
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	var roads := MeshInstance3D.new()
	roads.mesh = tool.commit()
	roads.material_override = material
	roads.set_meta(&"no_batch", true)
	add_child(roads)


func _build_plazas() -> void:
	for i in layout.plazas.size():
		var plaza := layout.plazas[i]
		_add_disc(Vector3(plaza.x, 0.035, plaza.y), plaza.z, PLAZA_COLOR)
		if map_data:
			var label := layout.plaza_names[i] if i < layout.plaza_names.size() else ""
			map_data.add_polygon(_circle_points(Vector2(plaza.x, plaza.y), plaza.z), PLAZA_COLOR, label)


## Außerhalb der Stadt: wilde Natur mit leuchtenden Bäumen, Felsen und Hügeln.
func _build_wilds() -> void:
	for i in 240:
		var angle := _rng.randf_range(0.0, TAU)
		var at := Vector2.from_angle(angle) * (get_outline_radius(angle) + _rng.randf_range(3.0, layout.wild_margin - 3.0))
		if road_clearance(at) < 2.0:
			continue
		var roll := _rng.randf()
		if roll < 0.35:
			_mystic_tree(_v3(at))
		elif roll < 0.55:
			var rock := _box(self, _v3(at) + Vector3(0, 0.6, 0), Vector3(_rng.randf_range(1.5, 4.0), _rng.randf_range(1.0, 3.0), _rng.randf_range(1.5, 4.0)), Color(0.25, 0.25, 0.27), true)
			rock.rotation = Vector3(_rng.randf_range(-0.2, 0.2), _rng.randf_range(0.0, TAU), _rng.randf_range(-0.2, 0.2))
		else:
			_add_plants(_v3(at), 2)
	# Hügel hinter der Mauer, damit der Rand natürlich aussieht.
	for i in 40:
		var angle := TAU * i / 40.0 + _rng.randf_range(-0.05, 0.05)
		var r := get_outline_radius(angle) + layout.wild_margin + _rng.randf_range(25.0, 60.0)
		var hill := SphereMesh.new()
		var radius := _rng.randf_range(30.0, 55.0)
		hill.radius = radius
		hill.height = radius * _rng.randf_range(0.5, 0.9)
		hill.is_hemisphere = true
		_mesh(self, hill, _v3(Vector2.from_angle(angle) * r) - Vector3(0, 2.0, 0), _material(WILD_COLOR.darkened(_rng.randf_range(0.0, 0.3)), false))


func _mystic_tree(at: Vector3) -> void:
	var height := _rng.randf_range(5.0, 11.0)
	_cylinder(self, at + Vector3(0, height / 2.0, 0), 0.3, 0.6, height, Color(0.25, 0.2, 0.18), true)
	var color := VINE_COLORS[_rng.randi() % VINE_COLORS.size()]
	for i in _rng.randi_range(2, 4):
		_glow_sphere(self, at + Vector3(_rng.randf_range(-1.5, 1.5), height + _rng.randf_range(-1.0, 1.0), _rng.randf_range(-1.5, 1.5)),
			_rng.randf_range(1.2, 2.2), color, 0.6)


## Unsichtbare Mauer entlang des äußeren Rands, damit niemand von der Welt fällt.
func _build_boundary() -> void:
	for i in boundary.size():
		var a := boundary[i]
		var b := boundary[(i + 1) % boundary.size()]
		var body := StaticBody3D.new()
		body.collision_layer = PhysicsLayers.WORLD
		body.position = _v3((a + b) / 2.0) + Vector3(0, 15.0, 0)
		body.rotation.y = -(b - a).angle()
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = Vector3(a.distance_to(b) + 1.0, 30.0, 1.0)
		shape.shape = box
		body.add_child(shape)
		add_child(body)


# --- Ranken, Pflanzen, Leuchtstreifen ---

## Leuchtende Ranken an den Wänden eines Gebäudes (`root` = Mitte am Boden).
func _add_vines(root: Node3D, size: Vector3, per_building: float, base_offset: float = 0.0) -> void:
	var count := _rng.randi_range(int(per_building * 0.5), int(per_building * 1.5))
	for i in count:
		var color := VINE_COLORS[_rng.randi() % VINE_COLORS.size()]
		var height := _rng.randf_range(size.y * 0.3, size.y * 0.95)
		var width := _rng.randf_range(0.25, 0.7)
		var along := _rng.randf_range(-0.45, 0.45)
		var at := Vector3.ZERO
		var vine_size := Vector3.ZERO
		match _rng.randi() % 4:
			0:
				at = Vector3(along * size.x, 0, -size.z / 2.0 - 0.08)
				vine_size = Vector3(width, height, 0.12)
			1:
				at = Vector3(along * size.x, 0, size.z / 2.0 + 0.08)
				vine_size = Vector3(width, height, 0.12)
			2:
				at = Vector3(-size.x / 2.0 - 0.08, 0, along * size.z)
				vine_size = Vector3(0.12, height, width)
			_:
				at = Vector3(size.x / 2.0 + 0.08, 0, along * size.z)
				vine_size = Vector3(0.12, height, width)
		var vine := _glow_box(root, at + Vector3(0, base_offset + height / 2.0, 0), vine_size, color, 0.6)
		vine.visibility_range_end = DETAIL_RANGE * 1.5
		# Leuchtende Blüte am Ende der Ranke.
		var bloom := _glow_sphere(root, at + Vector3(0, base_offset + height, 0), _rng.randf_range(0.3, 0.6), color, 1.5)
		bloom.visibility_range_end = DETAIL_RANGE


func _add_plants(center: Vector3, count: int) -> void:
	for i in count:
		var at := center + Vector3(_rng.randf_range(-3, 3), 0, _rng.randf_range(-3, 3))
		var height := _rng.randf_range(0.6, 2.0)
		var color := VINE_COLORS[_rng.randi() % VINE_COLORS.size()]
		var stem := _cylinder(self, at + Vector3(0, height / 2.0, 0), 0.05, 0.08, height, Color(0.15, 0.35, 0.2), false)
		stem.visibility_range_end = DETAIL_RANGE
		var bloom := _glow_sphere(self, at + Vector3(0, height, 0), _rng.randf_range(0.2, 0.45), color, 1.8)
		bloom.visibility_range_end = DETAIL_RANGE


func _add_neon_bands(root: Node3D, size: Vector3) -> void:
	var colors: Array[Color] = [Color(1.0, 0.2, 0.6), Color(0.2, 0.8, 1.0), Color(0.7, 0.3, 1.0)]
	var color := colors[_rng.randi() % colors.size()]
	var y := 6.0
	while y < size.y - 2.0:
		_glow_box(root, Vector3(0, y, 0), Vector3(size.x * 0.9 + 0.15, 0.25, size.z * 0.9 + 0.15), color, 1.2)
		y += _rng.randf_range(8.0, 14.0)


# --- Bauteile ---

## Wandteil eines Gebäudes mit Fenstern und Kollision.
func _part(root: Node3D, center: Vector3, size: Vector3, color: Color, windows: float, spacing: Vector2 = Vector2(2.6, 3.2)) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var instance := _mesh(root, mesh, center, _building_material)
	_paint(instance, color, windows, 0.35, spacing)
	_add_collision(instance, Vector3.ZERO, size)
	return instance


## Farbe und Fenster eines Gebäudeteils festlegen. Wird beim Zusammenfassen
## (`_batch_geometry`) in die Ecken des Meshes geschrieben.
func _paint(instance: GeometryInstance3D, color: Color, windows: float, lit: float, spacing: Vector2 = Vector2(2.6, 3.2)) -> void:
	instance.material_override = _building_material
	instance.set_meta(&"paint", [color, Vector2(windows, lit), spacing])


func _tilted_roof(root: Node3D, top: Vector3, size: Vector3, color: Color) -> void:
	var roof := _box(root, top + Vector3(0, 0.25, 0), Vector3(size.x + 0.6, 0.12, size.z + 0.6), color, false)
	roof.rotation.x = _rng.randf_range(-0.2, 0.2)
	roof.rotation.z = _rng.randf_range(-0.12, 0.12)


## Satteldach; der First läuft entlang der Tiefe (lokal z).
func _gable_roof(root: Node3D, top: Vector3, size: Vector3, color: Color) -> void:
	var roof_height := minf(size.x, size.z) * 0.4
	_add_prism_to(root, top + Vector3(0, roof_height / 2.0, 0), Vector3(size.x + 0.5, roof_height, size.z + 0.5), color)


func _parapet(root: Node3D, size: Vector3, color: Color) -> void:
	for side: Vector4 in [Vector4(0, -1, size.x, 0.3), Vector4(0, 1, size.x, 0.3), Vector4(-1, 0, 0.3, size.z), Vector4(1, 0, 0.3, size.z)]:
		_box(root, Vector3(side.x * size.x / 2.0, size.y + 0.4, side.y * size.z / 2.0), Vector3(side.z, 0.8, side.w), color, false)


func _column(root: Node3D, base: Vector3, height: float, radius: float, color: Color) -> void:
	_cylinder(root, base + Vector3(0, height / 2.0, 0), radius * 0.85, radius, height, color, true)
	_box(root, base + Vector3(0, height + 0.3, 0), Vector3(radius * 2.6, 0.6, radius * 2.6), color.darkened(0.1), false)


func _obelisk(at: Vector3) -> void:
	_box(self, at + Vector3(0, 0.5, 0), Vector3(3.0, 1.0, 3.0), Color(0.3, 0.28, 0.3), true)
	_box(self, at + Vector3(0, 7.0, 0), Vector3(1.6, 12.0, 1.6), Color(0.18, 0.17, 0.2), true)
	_add_prism_to(self, at + Vector3(0, 13.6, 0), Vector3(1.6, 1.2, 1.6), Color(0.18, 0.17, 0.2))
	_glow_box(self, at + Vector3(0, 9.0, 0), Vector3(1.65, 0.3, 1.65), IMPERIAL_RED, 1.6)


## Senkrechtes Banner des Konzerns (rot, mit hellem Zeichen) an der Vorderseite.
func _banner(root: Node3D, center: Vector3, height: float) -> void:
	var side := -1.0 if center.z <= 0.0 else 1.0
	_box(root, center, Vector3(height * 0.22, height, 0.15), IMPERIAL_RED.darkened(0.15), false)
	_glow_box(root, center + Vector3(0, height * 0.2, side * 0.1), Vector3(height * 0.12, height * 0.12, 0.05), Color(1.0, 0.85, 0.6), 1.2)


## Das Zeichen des Konzerns an der Zitadelle: Ring mit Dreieck.
func _emblem(at: Vector3) -> void:
	var ring := TorusMesh.new()
	ring.inner_radius = 5.0
	ring.outer_radius = 6.0
	var ring_instance := _mesh(self, ring, at, _glow_material(IMPERIAL_RED, 2.0))
	ring_instance.rotation.x = PI / 2.0
	var triangle := PrismMesh.new()
	triangle.size = Vector3(6.0, 6.0, 0.5)
	_mesh(self, triangle, at, _glow_material(Color(1.0, 0.85, 0.6), 1.5))


func _box(root: Node3D, center: Vector3, size: Vector3, color: Color, solid: bool, outline: bool = true) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var instance := _mesh(root, mesh, center, _material(color, outline) if color.a >= 1.0 else ToonStyle.make(color, false))
	if solid:
		_add_collision(instance, Vector3.ZERO, size)
	return instance


## Kleines Teil ohne Kollision (Markisen, Flicken, Schutt).
func _detail_box(root: Node3D, center: Vector3, size: Vector3, color: Color) -> MeshInstance3D:
	var instance := _box(root, center, size, color, false)
	instance.visibility_range_end = DETAIL_RANGE * 1.5
	return instance


func _add_prism_to(root: Node3D, center: Vector3, size: Vector3, color: Color) -> MeshInstance3D:
	var mesh := PrismMesh.new()
	mesh.size = size
	return _mesh(root, mesh, center, _material(color, true))


func _cylinder(root: Node3D, center: Vector3, top: float, bottom: float, height: float, color: Color, solid: bool) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = top
	mesh.bottom_radius = bottom
	mesh.height = height
	mesh.radial_segments = 12
	var instance := _mesh(root, mesh, center, _material(color, solid))
	if solid:
		_add_collision(instance, Vector3.ZERO, Vector3(bottom * 2.0, height, bottom * 2.0))
	return instance


func _detail_cylinder(root: Node3D, center: Vector3, top: float, bottom: float, height: float, color: Color) -> void:
	var instance := _cylinder(root, center, top, bottom, height, color, false)
	instance.visibility_range_end = DETAIL_RANGE


func _dome(root: Node3D, center: Vector3, radius: float, color: Color) -> void:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.is_hemisphere = true
	_mesh(root, mesh, center, _material(color, true))


func _add_disc(center: Vector3, radius: float, color: Color) -> void:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = 0.04
	mesh.radial_segments = 32
	_mesh(self, mesh, center, _material(color, false))


func _glow_box(root: Node3D, center: Vector3, size: Vector3, color: Color, energy: float = 1.5) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	return _mesh(root, mesh, center, _glow_material(color, energy))


func _glow_sphere(root: Node3D, center: Vector3, radius: float, color: Color, energy: float) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = 12
	mesh.rings = 6
	return _mesh(root, mesh, center, _glow_material(color, energy))


func _glow_cylinder(root: Node3D, center: Vector3, radius: float, height: float, color: Color) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	return _mesh(root, mesh, center, _glow_material(color, 1.5))


## Gemeinsame Materialien je Farbe (spart Speicher und Zeichenaufrufe).
func _material(color: Color, outline: bool) -> StandardMaterial3D:
	var key := Color(color.r, color.g, color.b, 1.0 if outline else 0.5)
	if not _materials.has(key):
		_materials[key] = ToonStyle.make(color, outline)
	return _materials[key]


func _glow_material(color: Color, energy: float) -> StandardMaterial3D:
	var key := Color(color.r, color.g, color.b, energy)
	if not _glow_materials.has(key):
		var material := ToonStyle.make(color, false)
		material.emission_enabled = true
		material.emission = color
		material.emission_energy_multiplier = energy
		_glow_materials[key] = material
	return _glow_materials[key]


func _kit_mesh(model: String) -> Mesh:
	if not _kit_meshes.has(model):
		_kit_meshes[model] = load(KIT_PATH % model) as Mesh
	return _kit_meshes[model]


func _mesh(root: Node3D, mesh: Mesh, center: Vector3, material: Material) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.material_override = material
	# Position vor dem Einfügen setzen, damit die Kollision sofort am richtigen Ort ist.
	instance.position = center
	root.add_child(instance)
	return instance


func _add_collision(parent: Node3D, center: Vector3, size: Vector3) -> void:
	var body := StaticBody3D.new()
	body.collision_layer = PhysicsLayers.WORLD
	body.collision_mask = 0
	body.position = center
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	body.add_child(shape)
	parent.add_child(body)


func _add_sign(at: Vector3, text: String) -> void:
	var label := Label3D.new()
	label.text = text
	label.font_size = 64
	label.outline_size = 12
	label.modulate = Color(1.0, 0.95, 0.85)
	label.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	label.position = at
	add_child(label)


func _add_marker(at: Vector3, kind: MapMarker.Kind, label: String) -> void:
	var marker := MapMarker.new()
	marker.kind = kind
	marker.label = label
	marker.position = at
	add_child(marker)


## Liegt der Punkt nahe an einer Figur, einem Spiegel oder Gegenstand?
func _near_keep_clear(point: Vector2, margin: float) -> bool:
	for circle in _clear_circles:
		if circle.z <= KEEP_CLEAR_RADIUS and point.distance_to(Vector2(circle.x, circle.y)) < circle.z + margin:
			return true
	return false


func _circle_points(center: Vector2, radius: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in 24:
		points.append(center + Vector2.from_angle(TAU * i / 24.0) * radius)
	return points


func _rust_color() -> Color:
	var colors: Array[Color] = [Color(0.45, 0.25, 0.18), Color(0.38, 0.36, 0.34), Color(0.5, 0.42, 0.3), Color(0.3, 0.33, 0.36)]
	return colors[_rng.randi() % colors.size()].darkened(_rng.randf_range(0.0, 0.25))


func _patch_color(color: Color) -> Color:
	return color.lerp(_rust_color(), _rng.randf_range(0.2, 0.6))


static func _v3(point: Vector2) -> Vector3:
	return Vector3(point.x, 0.0, point.y)

class_name ContinentGenerator
extends Node3D
## Baut den Kontinent aus einem ContinentLayout: Gelände mit Küste, Bergen,
## Flüssen und Straßen, Wasser, Pflanzen je Region und die Wahrzeichen
## (über ContinentLandmarks). Gleicher Seed = gleicher Kontinent.
##
## Ablauf: Wahrzeichen planen (brauchen ebene Flächen) → Höhen berechnen →
## Straßen glätten und Bauplätze einebnen → Gelände-Meshes und Kollision →
## Wasser → Pflanzen → Wahrzeichen bauen.

@export var layout: ContinentLayout
## Bäume, Bewohner und Wahrzeichen weglassen (schneller, z. B. für Tests).
@export var build_details: bool = true

const SEA_DEPTH := -14.0
const ROAD_WIDTH := 3.5
const ROAD_FALLOFF := 10.0
## Höchste Steigung eines Weges (0.45 ≈ 24°).
const MAX_ROAD_GRADE := 0.45
const RIVER_WIDTH := 10.0
const RIVER_BANK := 45.0
const CHUNK_CELLS := 25
const SNOW_HEIGHT := 110.0
const ROCK_COLOR := Color(0.42, 0.4, 0.4)
const SNOW_COLOR := Color(0.92, 0.93, 0.97)
const SAND_COLOR := Color(0.86, 0.79, 0.58)
const BANK_COLOR := Color(0.28, 0.52, 0.22)
const WATER_COLOR := Color(0.18, 0.42, 0.55, 0.82)

## Höhen auf dem Gitter (Zeilen = z, Spalten = x).
var heights: PackedFloat32Array = PackedFloat32Array()
var grid_size: int = 0
## Geplante Wahrzeichen: {"kind", "region", "pos" (Vector2), "radius", "angle"}.
var landmarks: Array[Dictionary] = []
## Gebaute Wahrzeichen-Knoten je Region (für Karte und Entdecken).
var region_roots: Dictionary[StringName, Node3D] = {}
## Wie viele Pflanzen pro Region gesetzt wurden.
var plant_counts: Dictionary[StringName, int] = {}
var mesh_count: int = 0

var _noise := FastNoiseLite.new()
var _detail := FastNoiseLite.new()
var _road: PackedFloat32Array = PackedFloat32Array()
var _river: PackedFloat32Array = PackedFloat32Array()
var _colors: PackedColorArray = PackedColorArray()
var _rng := RandomNumberGenerator.new()
var _terrain_material: StandardMaterial3D
var _temple_peak: Vector2 = Vector2.ZERO
var _castle_hill: Vector2 = Vector2.ZERO
var _crater: Vector2 = Vector2.ZERO


func _ready() -> void:
	add_to_group(&"continent_generator")
	if layout == null:
		return
	generate()


func generate() -> void:
	_rng.seed = layout.seed
	_noise.seed = layout.seed
	_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_noise.frequency = 1.0
	_noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	_noise.fractal_octaves = 4
	_detail.seed = layout.seed + 7
	_detail.frequency = 0.05
	grid_size = int(round(layout.half_size * 2.0 / layout.cell_size)) + 1
	var mountains := _first_region(ContinentRegion.Style.MOUNTAINS)
	var medieval := _first_region(ContinentRegion.Style.MEDIEVAL)
	var wasteland := _first_region(ContinentRegion.Style.WASTELAND)
	_temple_peak = mountains.center + Vector2(100, -120) if mountains else Vector2(1e6, 1e6)
	_castle_hill = medieval.center + Vector2(80, -120) if medieval else Vector2(1e6, 1e6)
	_crater = wasteland.center + Vector2(40, -30) if wasteland else Vector2(1e6, 1e6)
	_plan_landmarks()
	_rasterize_paths()
	_compute_heights()
	_flatten_sites()
	_level_roads()
	_compute_colors()
	_build_terrain()
	_build_water()
	if build_details:
		_build_plants()
		var builder := ContinentLandmarks.new(self)
		for landmark in landmarks:
			builder.build(landmark)


# --- Abfragen ------------------------------------------------------------

## Geländehöhe an einer Stelle (bilinear zwischen den Gitterpunkten).
func get_height(x: float, z: float) -> float:
	var gx := clampf((x + layout.half_size) / layout.cell_size, 0.0, grid_size - 1.001)
	var gz := clampf((z + layout.half_size) / layout.cell_size, 0.0, grid_size - 1.001)
	var ix := int(gx)
	var iz := int(gz)
	var fx := gx - ix
	var fz := gz - iz
	var h00 := heights[iz * grid_size + ix]
	var h10 := heights[iz * grid_size + ix + 1]
	var h01 := heights[(iz + 1) * grid_size + ix]
	var h11 := heights[(iz + 1) * grid_size + ix + 1]
	return lerpf(lerpf(h00, h10, fx), lerpf(h01, h11, fx), fz)


## Punkt auf dem Boden (x, Höhe, z).
func ground(point: Vector2, lift: float = 0.0) -> Vector3:
	return Vector3(point.x, get_height(point.x, point.y) + lift, point.y)


## Die Region, zu der ein Punkt gehört (stärkster Einfluss).
func region_at(point: Vector2) -> ContinentRegion:
	var best: ContinentRegion = null
	var best_weight := -1.0
	for region in layout.regions:
		var weight := _region_weight(region, point)
		if weight > best_weight:
			best_weight = weight
			best = region
	return best


func get_region(id: StringName) -> ContinentRegion:
	for region in layout.regions:
		if region.id == id:
			return region
	return null


## Wie stark eine Straße an dieser Stelle ist (0–1).
func road_influence(point: Vector2) -> float:
	return _sample(_road, point)


func river_influence(point: Vector2) -> float:
	return _sample(_river, point)


## Ist hier Platz (kein Wahrzeichen in der Nähe)?
func is_clear_of_landmarks(point: Vector2, margin: float) -> bool:
	for landmark in landmarks:
		if point.distance_to(landmark["pos"]) < float(landmark["radius"]) + margin:
			return false
	return true


## Steigung des Geländes (0 = flach, 1 = 45°).
func get_slope(point: Vector2) -> float:
	var d := layout.cell_size
	var dx := get_height(point.x + d, point.y) - get_height(point.x - d, point.y)
	var dz := get_height(point.x, point.y + d) - get_height(point.x, point.y - d)
	return Vector2(dx, dz).length() / (2.0 * d)


## Küstenlinie (für die Karte): von der Mitte aus nach außen bis zum Wasser.
func get_coast_points(count: int = 96) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in count:
		var dir := Vector2.from_angle(TAU * float(i) / count)
		var r := 0.0
		while r < layout.half_size - 10.0 and get_height(dir.x * (r + 10.0), dir.y * (r + 10.0)) > 0.0:
			r += 10.0
		points.append(dir * r)
	return points


func get_temple_peak() -> Vector2:
	return _temple_peak


func get_castle_hill() -> Vector2:
	return _castle_hill


func get_crater() -> Vector2:
	return _crater


# --- Planung der Wahrzeichen ---------------------------------------------

func _plan_landmarks() -> void:
	landmarks.clear()
	for region in layout.regions:
		var c := region.center
		_add_site(region, &"anchor_mirror", c + Vector2(24, 24), 6.0)
		match region.style:
			ContinentRegion.Style.CITY:
				_add_site(region, &"city", c, 215.0)
			ContinentRegion.Style.WASTELAND:
				for offset: Vector2 in [Vector2(-95, 45), Vector2(115, -25), Vector2(-45, -125)]:
					_add_site(region, &"drill_rig", c + offset, 14.0)
				_add_site(region, &"outpost", c + Vector2(90, 95), 26.0)
			ContinentRegion.Style.MOUNTAINS:
				_add_site(region, &"mountain_temple", get_temple_peak(), 34.0)
				_add_site(region, &"mountain_village", c + Vector2(-95, 70), 42.0)
				_add_site(region, &"shrine", c + Vector2(-20, -90), 14.0)
			ContinentRegion.Style.STEPPE:
				_add_site(region, &"ger_camp", c + Vector2(-70, 50), 32.0)
				_add_site(region, &"ger_camp", c + Vector2(150, -120), 28.0)
				_add_site(region, &"ger_camp", c + Vector2(-190, -160), 28.0)
				_add_site(region, &"ovoo", c + Vector2(55, -55), 8.0)
				_add_site(region, &"ovoo", c + Vector2(-250, 90), 8.0)
				_add_site(region, &"deer_stones", c + Vector2(-90, -260), 14.0)
			ContinentRegion.Style.MEDIEVAL:
				_add_site(region, &"castle", get_castle_hill(), 46.0)
				_add_site(region, &"village", c + Vector2(-50, 80), 52.0)
				_add_site(region, &"windmill", c + Vector2(-150, 0), 10.0)
				_add_site(region, &"chapel", c + Vector2(45, 115), 14.0)
			ContinentRegion.Style.MYSTIC_FOREST:
				_add_site(region, &"spirit_shrine", c + Vector2(35, -50), 14.0)
				_add_site(region, &"stone_circle", c + Vector2(-85, 70), 16.0)
				_add_site(region, &"giant_tree", c + Vector2(100, 95), 16.0)
			ContinentRegion.Style.DESERT:
				_add_site(region, &"pyramid_great", c + Vector2(-130, 40), 62.0)
				_add_site(region, &"pyramid", c + Vector2(-35, 125), 34.0)
				_add_site(region, &"pyramid_small", c + Vector2(-215, 145), 28.0)
				_add_site(region, &"column_temple", c + Vector2(130, -40), 32.0)
				_add_site(region, &"guardian_lion", c + Vector2(40, -60), 12.0)
				_add_site(region, &"river_village", c + Vector2(120, 110), 28.0)
			ContinentRegion.Style.PRESENT:
				_add_site(region, &"suburb", c + Vector2(-45, 70), 70.0)
				_add_site(region, &"gas_station", c + Vector2(55, -45), 18.0)
				_add_site(region, &"radio_mast", c + Vector2(135, 90), 10.0)
				_add_site(region, &"stadium", c + Vector2(-110, -95), 44.0)
			ContinentRegion.Style.FUTURE:
				_add_site(region, &"white_towers", c + Vector2(35, 5), 58.0)
				_add_site(region, &"glass_domes", c + Vector2(-70, 60), 34.0)
				_add_site(region, &"maglev", c + Vector2(-60, -60), 20.0)


func _add_site(region: ContinentRegion, kind: StringName, pos: Vector2, radius: float) -> void:
	landmarks.append({"kind": kind, "region": region.id, "pos": pos, "radius": radius,
		"angle": _rng.randf_range(0.0, TAU)})


func _first_region(style: ContinentRegion.Style) -> ContinentRegion:
	for region in layout.regions:
		if region.style == style:
			return region
	return null


# --- Höhen ---------------------------------------------------------------

func _region_weight(region: ContinentRegion, point: Vector2) -> float:
	var d := point.distance_to(region.center) / region.radius
	if d > 2.2:
		return 0.0
	return exp(-d * d * 2.2)


func _region_height(region: ContinentRegion, p: Vector2) -> float:
	var f := region.relief_frequency
	var n := _noise.get_noise_2d(p.x * f, p.y * f)
	match region.style:
		ContinentRegion.Style.CITY:
			return region.base_height
		ContinentRegion.Style.MOUNTAINS:
			# Tal in der Mitte (Dorf, Kreuzung), Grate und Gipfel ringsum.
			var ridge := 1.0 - absf(n)
			var valley := smoothstep(0.12, 0.6, p.distance_to(region.center) / region.radius)
			var peak := 105.0 * exp(-pow(p.distance_to(get_temple_peak()) / 170.0, 2.0))
			return region.base_height + region.relief * ridge * ridge * valley + peak
		ContinentRegion.Style.WASTELAND:
			var crater := (region.base_height - 1.5) * exp(-pow(p.distance_to(get_crater()) / 85.0, 2.0))
			return region.base_height + region.relief * n - crater
		ContinentRegion.Style.DESERT:
			return region.base_height + region.relief * absf(n)
		ContinentRegion.Style.MEDIEVAL:
			var hill := 24.0 * exp(-pow(p.distance_to(get_castle_hill()) / 75.0, 2.0))
			return region.base_height + region.relief * (n * 0.5 + 0.5) + hill
		ContinentRegion.Style.STEPPE, ContinentRegion.Style.MYSTIC_FOREST:
			return region.base_height + region.relief * (n * 0.5 + 0.5)
		_:
			return region.base_height + region.relief * n


## Höhe ohne Straßen und Bauplätze.
func _raw_height(p: Vector2) -> float:
	var total := 0.0
	var h := 0.0
	for region in layout.regions:
		var weight := _region_weight(region, p)
		if weight <= 0.0001:
			continue
		h += weight * _region_height(region, p)
		total += weight
	var plains := 5.0 + 4.0 * _noise.get_noise_2d(p.x * 0.004, p.y * 0.004)
	var land := plains
	if total > 0.0001:
		land = lerpf(plains, h / total, clampf(total * 3.0, 0.0, 1.0))
	# Küste folgt den Regionen: Wo keine Region mehr wirkt, beginnt das Meer.
	var shore := 0.012 * _noise.get_noise_2d(p.x * 0.006 + 40.0, p.y * 0.006)
	var mask := smoothstep(0.018, 0.065, total + shore)
	return lerpf(SEA_DEPTH, land, mask)


func _compute_heights() -> void:
	heights.resize(grid_size * grid_size)
	for iz in grid_size:
		for ix in grid_size:
			var p := _grid_point(ix, iz)
			var i := iz * grid_size + ix
			var h := _raw_height(p)
			# Flussbett: bis knapp unter den Meeresspiegel (seichtes Wasser).
			if _river[i] > 0.0:
				h = lerpf(h, -1.0, _river[i])
			heights[i] = h


## Straßen: Höhenverlauf entlang des Weges glätten und quer dazu eben machen,
## damit Wege begehbar sind (auch der Serpentinenweg zum Bergtempel).
func _level_roads() -> void:
	var target := PackedFloat32Array()
	target.resize(heights.size())
	var weight_sum := PackedFloat32Array()
	weight_sum.resize(heights.size())
	var weight := PackedFloat32Array()
	weight.resize(heights.size())
	for path in layout.roads:
		# Punkte alle 4 m entlang des Weges, Höhen geglättet (gleitender Mittelwert).
		var samples := PackedVector2Array()
		for s in path.size() - 1:
			var steps := maxi(1, int(path[s].distance_to(path[s + 1]) / 4.0))
			for k in steps:
				samples.append(path[s].lerp(path[s + 1], float(k) / steps))
		samples.append(path[path.size() - 1])
		var profile := PackedFloat32Array()
		for point in samples:
			profile.append(maxf(get_height(point.x, point.y), 0.8))
		for pass_index in 4:
			var smoothed := profile.duplicate()
			for i in profile.size():
				var sum := 0.0
				var n := 0
				for j in range(maxi(0, i - 6), mini(profile.size(), i + 7)):
					sum += profile[j]
					n += 1
				smoothed[i] = sum / n
			profile = smoothed
		# Steigung begrenzen (vorwärts und rückwärts), wie bei einer Bergstraße.
		var max_step := 4.0 * MAX_ROAD_GRADE
		for i in range(1, profile.size()):
			profile[i] = clampf(profile[i], profile[i - 1] - max_step, profile[i - 1] + max_step)
		for i in range(profile.size() - 2, -1, -1):
			profile[i] = clampf(profile[i], profile[i + 1] - max_step, profile[i + 1] + max_step)
		var reach := ROAD_WIDTH + ROAD_FALLOFF
		var cells := int(ceil(reach / layout.cell_size)) + 1
		for i in samples.size():
			var center := _grid_index(samples[i])
			for dz in range(-cells, cells + 1):
				for dx in range(-cells, cells + 1):
					var ix := center.x + dx
					var iz := center.y + dz
					if ix < 0 or iz < 0 or ix >= grid_size or iz >= grid_size:
						continue
					var dist := _grid_point(ix, iz).distance_to(samples[i])
					var w := 1.0 - smoothstep(ROAD_WIDTH + 1.0, reach, dist)
					if w <= 0.0:
						continue
					# Gewichtetes Mittel: An Kreuzungen treffen sich die Wege sanft.
					var index := iz * grid_size + ix
					target[index] += profile[i] * w
					weight_sum[index] += w
					weight[index] = maxf(weight[index], w)
	for i in heights.size():
		if weight[i] > 0.0:
			heights[i] = lerpf(heights[i], target[i] / weight_sum[i], weight[i])


## Bauplätze einebnen (Wahrzeichen stehen auf flachem Boden über dem Meer).
func _flatten_sites() -> void:
	for landmark in landmarks:
		var pos: Vector2 = landmark["pos"]
		var radius: float = landmark["radius"]
		var target := maxf(get_height(pos.x, pos.y), 1.5)
		var outer := radius * 1.6 + 6.0
		var cells := int(ceil(outer / layout.cell_size))
		var center := _grid_index(pos)
		for dz in range(-cells, cells + 1):
			for dx in range(-cells, cells + 1):
				var ix := center.x + dx
				var iz := center.y + dz
				if ix < 0 or iz < 0 or ix >= grid_size or iz >= grid_size:
					continue
				var dist := _grid_point(ix, iz).distance_to(pos)
				if dist > outer:
					continue
				var t := 1.0 - smoothstep(radius, outer, dist)
				var i := iz * grid_size + ix
				heights[i] = lerpf(heights[i], target, t)


# --- Straßen und Flüsse als Raster ---------------------------------------

func _rasterize_paths() -> void:
	_road = PackedFloat32Array()
	_road.resize(grid_size * grid_size)
	_river = PackedFloat32Array()
	_river.resize(grid_size * grid_size)
	for path in layout.roads:
		_rasterize(path, _road, ROAD_WIDTH, ROAD_FALLOFF)
	for path in layout.rivers:
		_rasterize(path, _river, RIVER_WIDTH, RIVER_WIDTH * 2.2)


func _rasterize(path: PackedVector2Array, target: PackedFloat32Array, width: float, falloff: float) -> void:
	var reach := width + falloff
	var cells := int(ceil(reach / layout.cell_size)) + 1
	for s in path.size() - 1:
		var a := path[s]
		var b := path[s + 1]
		var length := a.distance_to(b)
		var steps := maxi(1, int(length / (layout.cell_size * 0.5)))
		for k in steps + 1:
			var p := a.lerp(b, float(k) / steps)
			var center := _grid_index(p)
			for dz in range(-cells, cells + 1):
				for dx in range(-cells, cells + 1):
					var ix := center.x + dx
					var iz := center.y + dz
					if ix < 0 or iz < 0 or ix >= grid_size or iz >= grid_size:
						continue
					var dist := Geometry2D.get_closest_point_to_segment(_grid_point(ix, iz), a, b).distance_to(_grid_point(ix, iz))
					var value := 1.0 - smoothstep(width, reach, dist)
					var i := iz * grid_size + ix
					if value > target[i]:
						target[i] = value


func _sample(grid: PackedFloat32Array, point: Vector2) -> float:
	var index := _grid_index(point)
	if index.x < 0 or index.y < 0 or index.x >= grid_size or index.y >= grid_size:
		return 0.0
	return grid[index.y * grid_size + index.x]


func _grid_point(ix: int, iz: int) -> Vector2:
	return Vector2(-layout.half_size + ix * layout.cell_size, -layout.half_size + iz * layout.cell_size)


func _grid_index(point: Vector2) -> Vector2i:
	return Vector2i(int(round((point.x + layout.half_size) / layout.cell_size)),
		int(round((point.y + layout.half_size) / layout.cell_size)))


# --- Farben --------------------------------------------------------------

func _compute_colors() -> void:
	_colors.resize(grid_size * grid_size)
	for iz in grid_size:
		for ix in grid_size:
			var p := _grid_point(ix, iz)
			var i := iz * grid_size + ix
			var h := heights[i]
			var color := Color(0, 0, 0)
			var road := Color(0, 0, 0)
			var total := 0.0
			for region in layout.regions:
				var weight := _region_weight(region, p)
				if weight <= 0.0001:
					continue
				color += region.ground_color * weight
				road += region.road_color * weight
				total += weight
			if total > 0.0001:
				color /= total
				road /= total
			else:
				color = Color(0.4, 0.5, 0.32)
				road = Color(0.45, 0.38, 0.3)
			# Leichte Flecken, damit Flächen nicht glatt wirken.
			color = color.lerp(color.darkened(0.25), (_detail.get_noise_2d(p.x, p.y) * 0.5 + 0.5) * 0.5)
			var slope := 0.0
			if ix > 0 and iz > 0 and ix < grid_size - 1 and iz < grid_size - 1:
				var dx := heights[i + 1] - heights[i - 1]
				var dz := heights[i + grid_size] - heights[i - grid_size]
				slope = Vector2(dx, dz).length() / (2.0 * layout.cell_size)
			color = color.lerp(ROCK_COLOR, smoothstep(0.55, 1.1, slope))
			color = color.lerp(SNOW_COLOR, smoothstep(SNOW_HEIGHT - 15.0, SNOW_HEIGHT + 10.0, h))
			if h < 2.5:
				color = color.lerp(SAND_COLOR, clampf((2.5 - h) / 2.0, 0.0, 1.0))
			if _river[i] > 0.0 or _near_river(ix, iz):
				color = color.lerp(BANK_COLOR, 0.75 if h > 0.0 else 0.2)
			color = color.lerp(road, _road[i] * 0.85)
			_colors[i] = color


## Grüner Streifen am Fluss (auch in der Wüste).
func _near_river(ix: int, iz: int) -> bool:
	var cells := int(RIVER_BANK / layout.cell_size)
	for dx: int in [-cells, cells, 0]:
		for dz: int in [-cells, cells, 0]:
			var x := ix + dx
			var z := iz + dz
			if x >= 0 and z >= 0 and x < grid_size and z < grid_size and _river[z * grid_size + x] > 0.5:
				return true
	return false


# --- Gelände-Meshes und Kollision ----------------------------------------

func _build_terrain() -> void:
	_terrain_material = ToonStyle.make(Color.WHITE, false)
	_terrain_material.vertex_color_use_as_albedo = true
	_terrain_material.roughness = 1.0
	_terrain_material.set_meta(&"no_outline", true)
	var terrain := Node3D.new()
	terrain.name = "Terrain"
	add_child(terrain)
	var chunks := int(ceil(float(grid_size - 1) / CHUNK_CELLS))
	for cz in chunks:
		for cx in chunks:
			var mesh := _chunk_mesh(cx * CHUNK_CELLS, cz * CHUNK_CELLS)
			var instance := MeshInstance3D.new()
			instance.mesh = mesh
			instance.material_override = _terrain_material
			terrain.add_child(instance)
			mesh_count += 1
	# Kollision: ein Höhenfeld, gleichmäßig auf die Zellgröße skaliert.
	var shape := HeightMapShape3D.new()
	shape.map_width = grid_size
	shape.map_depth = grid_size
	var scaled := PackedFloat32Array()
	scaled.resize(heights.size())
	for i in heights.size():
		scaled[i] = heights[i] / layout.cell_size
	shape.map_data = scaled
	var body := StaticBody3D.new()
	body.name = "TerrainBody"
	body.collision_layer = PhysicsLayers.WORLD
	body.collision_mask = 0
	var collision := CollisionShape3D.new()
	collision.shape = shape
	collision.scale = Vector3.ONE * layout.cell_size
	body.add_child(collision)
	add_child(body)


func _chunk_mesh(x0: int, z0: int) -> ArrayMesh:
	var x1 := mini(x0 + CHUNK_CELLS, grid_size - 1)
	var z1 := mini(z0 + CHUNK_CELLS, grid_size - 1)
	var w := x1 - x0 + 1
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var colors := PackedColorArray()
	var indices := PackedInt32Array()
	for iz in range(z0, z1 + 1):
		for ix in range(x0, x1 + 1):
			var i := iz * grid_size + ix
			var p := _grid_point(ix, iz)
			vertices.append(Vector3(p.x, heights[i], p.y))
			colors.append(_colors[i])
			var hl := heights[i - 1] if ix > 0 else heights[i]
			var hr := heights[i + 1] if ix < grid_size - 1 else heights[i]
			var hd := heights[i - grid_size] if iz > 0 else heights[i]
			var hu := heights[i + grid_size] if iz < grid_size - 1 else heights[i]
			normals.append(Vector3(hl - hr, 2.0 * layout.cell_size, hd - hu).normalized())
	for z in z1 - z0:
		for x in w - 1:
			var a := z * w + x
			indices.append_array([a, a + 1, a + w, a + 1, a + w + 1, a + w])
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_COLOR] = colors
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


func _build_water() -> void:
	var plane := PlaneMesh.new()
	plane.size = Vector2.ONE * (layout.half_size * 2.0 + 1600.0)
	var material := StandardMaterial3D.new()
	material.albedo_color = WATER_COLOR
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.roughness = 0.15
	material.metallic = 0.2
	ToonStyle.apply(material, false)
	var water := MeshInstance3D.new()
	water.name = "Water"
	water.mesh = plane
	water.material_override = material
	water.position = Vector3(0, 0.0, 0)
	add_child(water)
	mesh_count += 1


# --- Pflanzen ------------------------------------------------------------

func _build_plants() -> void:
	var plants := Node3D.new()
	plants.name = "Plants"
	add_child(plants)
	var colliders := StaticBody3D.new()
	colliders.name = "PlantColliders"
	colliders.collision_layer = PhysicsLayers.WORLD
	colliders.collision_mask = 0
	add_child(colliders)
	var kit := ContinentPlants.new()
	for region in layout.regions:
		var placed: Dictionary[StringName, Array] = {}
		var count := 0
		var attempts := region.plant_count * 4
		for attempt in attempts:
			if count >= region.plant_count:
				break
			var p := region.center + Vector2.from_angle(_rng.randf_range(0.0, TAU)) * region.radius * sqrt(_rng.randf()) * 1.05
			if region_at(p) != region:
				continue
			var h := get_height(p.x, p.y)
			if h < 1.2 or road_influence(p) > 0.05 or not is_clear_of_landmarks(p, 5.0):
				continue
			var kind := kit.pick(region.style, h, river_influence(p) > 0.0 or _near_river_world(p), _rng)
			if kind == &"":
				continue
			if kit.is_tree(kind) and get_slope(p) > 0.7:
				continue
			var scale := _rng.randf_range(0.8, 1.35) * kit.base_scale(kind)
			var basis := Basis(Vector3.UP, _rng.randf_range(0.0, TAU)).scaled(Vector3.ONE * scale)
			if not placed.has(kind):
				placed[kind] = []
			placed[kind].append(Transform3D(basis, Vector3(p.x, h - 0.2, p.y)))
			if kit.has_collision(kind):
				var shape := CollisionShape3D.new()
				var cylinder := CylinderShape3D.new()
				cylinder.radius = kit.collision_radius(kind) * scale
				cylinder.height = 6.0 * scale
				shape.shape = cylinder
				shape.position = Vector3(p.x, h + cylinder.height / 2.0, p.y)
				colliders.add_child(shape)
			count += 1
		plant_counts[region.id] = count
		for kind: StringName in placed:
			for part in kit.meshes(kind):
				var multimesh := MultiMesh.new()
				multimesh.transform_format = MultiMesh.TRANSFORM_3D
				multimesh.mesh = part["mesh"]
				var transforms: Array = placed[kind]
				multimesh.instance_count = transforms.size()
				for t in transforms.size():
					multimesh.set_instance_transform(t, transforms[t])
				var instance := MultiMeshInstance3D.new()
				instance.name = "%s_%s" % [region.id, kind]
				instance.multimesh = multimesh
				instance.material_override = part["material"]
				plants.add_child(instance)
				mesh_count += 1


func _near_river_world(p: Vector2) -> bool:
	var index := _grid_index(p)
	if index.x < 0 or index.y < 0 or index.x >= grid_size or index.y >= grid_size:
		return false
	return _near_river(index.x, index.y)


# --- Karte ---------------------------------------------------------------

## Karte eintragen. Unentdeckte Regionen erscheinen als „???“.
func register_map(map_data: MapData, discovered: Array[StringName]) -> void:
	map_data.clear()
	map_data.area_name = layout.continent_name
	map_data.bounds = Rect2(-layout.half_size, -layout.half_size, layout.half_size * 2.0, layout.half_size * 2.0)
	map_data.minimap_scale = 0.9
	map_data.add_polygon(get_coast_points(), Color(0.3, 0.36, 0.28))
	for region in layout.regions:
		var known := discovered.has(region.id)
		var points := PackedVector2Array()
		for i in 28:
			var angle := TAU * float(i) / 28.0
			var r := region.radius * 0.72 * (1.0 + 0.12 * _noise.get_noise_2d(cos(angle) * 3.0 + region.center.x, sin(angle) * 3.0))
			points.append(region.center + Vector2.from_angle(angle) * r)
		var color := region.ground_color.darkened(0.25) if known else Color(0.2, 0.21, 0.24)
		map_data.add_polygon(points, color, region.region_name if known else "???", region.center)
	for path in layout.rivers:
		map_data.add_line(path, 14.0, Color(0.25, 0.5, 0.7))
	for path in layout.roads:
		map_data.add_line(path, 6.0, Color(0.55, 0.47, 0.35))

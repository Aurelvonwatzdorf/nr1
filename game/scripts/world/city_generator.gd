class_name CityGenerator
extends Node3D
## Baut eine Stadt aus einem CityLayout (Bauplan): Böden, Straßen, Häuser,
## Ruinen, Hochhäuser, Wahrzeichen (Gotteshäuser, Konzerntürme, Kaserne,
## Marktplatz) und überall leuchtende Ranken und Pflanzen.
##
## Gleicher `seed` = gleiche Stadt. Häuser und Mauern haben Kollision (Ebene Welt),
## Ranken, Pflanzen und Schutt nicht.

@export var layout: CityLayout
@export var seed: int = 7
## Hier wird der Grundriss für die Karte eingetragen.
@export var map_data: MapData

const VINE_COLORS: Array[Color] = [Color(0.2, 1.0, 0.75), Color(0.45, 1.0, 0.4), Color(0.4, 0.85, 1.0)]
const ROAD_COLOR := Color(0.11, 0.11, 0.13)

var _rng := RandomNumberGenerator.new()
## Flächen, auf denen schon etwas steht (Wahrzeichen, Straßen).
var _reserved: Array[Rect2] = []
## Anzahl gebauter Häuser (für Tests und Statistik).
var building_count: int = 0


func _ready() -> void:
	generate()


func generate() -> void:
	_rng.seed = seed
	_reserved.clear()
	building_count = 0
	for district in layout.districts:
		_build_ground(district)
	for road in layout.roads:
		_build_road(road)
		_reserved.append(road)
	for district in layout.districts:
		_build_landmarks(district)
	for district in layout.districts:
		_build_lots(district)
	_build_boundary()
	if map_data:
		map_data.bounds = layout.bounds
		map_data.area_name = layout.city_name


## Unsichtbare Mauern am Stadtrand, damit niemand von der Welt fällt.
func _build_boundary() -> void:
	var b := layout.bounds
	var walls: Array[Array] = [
		[Vector3(b.get_center().x, 10, b.position.y - 0.5), Vector3(b.size.x, 20, 1)],
		[Vector3(b.get_center().x, 10, b.end.y + 0.5), Vector3(b.size.x, 20, 1)],
		[Vector3(b.position.x - 0.5, 10, b.get_center().y), Vector3(1, 20, b.size.y)],
		[Vector3(b.end.x + 0.5, 10, b.get_center().y), Vector3(1, 20, b.size.y)],
	]
	for wall in walls:
		var body := StaticBody3D.new()
		body.collision_layer = PhysicsLayers.WORLD
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = wall[1]
		shape.shape = box
		body.add_child(shape)
		body.position = wall[0]
		add_child(body)


# --- Böden und Straßen ---

func _build_ground(district: CityDistrict) -> void:
	var rect := district.rect
	_add_box(Vector3(rect.get_center().x, -0.5, rect.get_center().y), Vector3(rect.size.x, 1.0, rect.size.y),
		district.ground_color, true)
	if map_data:
		map_data.add_rect(rect, district.ground_color.lightened(0.15), district.display_name)


func _build_road(road: Rect2) -> void:
	_add_box(Vector3(road.get_center().x, 0.01, road.get_center().y), Vector3(road.size.x, 0.02, road.size.y), ROAD_COLOR, false, false)
	if map_data:
		map_data.add_rect(road, Color(0.08, 0.08, 0.1))


# --- Grundstücke ---

func _build_lots(district: CityDistrict) -> void:
	var rect := district.rect.grow(-2.0)
	var columns := maxi(int(rect.size.x / district.lot_size), 1)
	var rows := maxi(int(rect.size.y / district.lot_size), 1)
	var lot_w := rect.size.x / columns
	var lot_d := rect.size.y / rows
	for row in rows:
		for column in columns:
			var lot := Rect2(rect.position + Vector2(column * lot_w, row * lot_d), Vector2(lot_w, lot_d))
			# Grundstück an Straßen/Wahrzeichen so weit verkleinern, bis es frei ist.
			lot = _fit_lot(lot)
			if lot.size.x < 5.0 or lot.size.y < 5.0:
				continue
			if _rng.randf() < district.empty_chance:
				_add_plants(Vector3(lot.get_center().x, 0.0, lot.get_center().y), 3)
				continue
			# Im Norden des Bezirks reicher (höher), im Süden ärmer (niedriger).
			var richness := 1.0 - (lot.get_center().y - district.rect.position.y) / district.rect.size.y
			if _rng.randf() < district.ruin_chance * (1.0 - richness * 0.5):
				_build_ruin(district, lot)
			else:
				_build_house(district, lot, richness)


## Schneidet ein Grundstück von Straßen und Wahrzeichen frei (bleibt rechteckig).
func _fit_lot(lot: Rect2) -> Rect2:
	for reserved in _reserved:
		if not reserved.intersects(lot):
			continue
		# Die Seite abschneiden, auf der am wenigsten verloren geht.
		var options: Array[Rect2] = [
			Rect2(lot.position, Vector2(reserved.position.x - lot.position.x, lot.size.y)),
			Rect2(Vector2(reserved.end.x, lot.position.y), Vector2(lot.end.x - reserved.end.x, lot.size.y)),
			Rect2(lot.position, Vector2(lot.size.x, reserved.position.y - lot.position.y)),
			Rect2(Vector2(lot.position.x, reserved.end.y), Vector2(lot.size.x, lot.end.y - reserved.end.y)),
		]
		var best := Rect2()
		for option in options:
			if option.size.x > 0.0 and option.size.y > 0.0 and option.get_area() > best.get_area():
				best = option
		lot = best
		if lot.get_area() <= 0.0:
			return Rect2()
	return lot


func _is_blocked(area: Rect2) -> bool:
	for reserved in _reserved:
		if reserved.intersects(area):
			return true
	return false


func _build_house(district: CityDistrict, lot: Rect2, richness: float) -> void:
	var margin := _rng.randf_range(1.0, 2.5)
	var footprint := lot.grow(-margin)
	var low := lerpf(district.height_poor.x, district.height_rich.x, richness)
	var high := lerpf(district.height_poor.y, district.height_rich.y, richness)
	var height := _rng.randf_range(low, high)
	var color := district.wall_colors[_rng.randi() % district.wall_colors.size()]
	var center := Vector3(footprint.get_center().x, height / 2.0, footprint.get_center().y)
	var size := Vector3(footprint.size.x, height, footprint.size.y)
	_add_box(center, size, color, true)
	if district.pitched_roofs:
		_add_roof(Vector3(center.x, height, center.z), size, district.roof_color)
	if district.neon and height > 20.0:
		_add_neon_bands(center, size)
	_add_vines(center, size, district.vines_per_building)
	building_count += 1
	if map_data:
		map_data.add_rect(footprint, color.darkened(0.25))


func _build_ruin(district: CityDistrict, lot: Rect2) -> void:
	var footprint := lot.grow(-_rng.randf_range(1.5, 3.0))
	var color := district.wall_colors[_rng.randi() % district.wall_colors.size()].darkened(0.35)
	# Zwei unterschiedlich hohe Mauerreste, leicht schief.
	var height_a := _rng.randf_range(1.5, 5.0)
	var center := Vector3(footprint.get_center().x, 0.0, footprint.get_center().y)
	var half := Vector3(footprint.size.x / 2.0, 0.0, footprint.size.y / 2.0)
	var wall_a := _add_box(center + Vector3(-half.x * 0.5, height_a / 2.0, 0.0), Vector3(footprint.size.x * 0.5, height_a, footprint.size.y), color, true)
	wall_a.rotation.z = _rng.randf_range(-0.08, 0.08)
	var height_b := _rng.randf_range(0.8, 3.0)
	_add_box(center + Vector3(half.x * 0.5, height_b / 2.0, -half.z * 0.3), Vector3(footprint.size.x * 0.45, height_b, footprint.size.y * 0.6), color.darkened(0.1), true)
	for i in _rng.randi_range(3, 7):
		var rubble := Vector3(_rng.randf_range(0.3, 1.2), _rng.randf_range(0.2, 0.8), _rng.randf_range(0.3, 1.2))
		var at := center + Vector3(_rng.randf_range(-half.x, half.x), rubble.y / 2.0, _rng.randf_range(-half.z, half.z))
		var piece := _add_box(at, rubble, color.darkened(0.2), false)
		piece.rotation.y = _rng.randf_range(0.0, TAU)
	# In Ruinen holt sich die Natur alles zurück.
	_add_vines(center + Vector3(0.0, height_a / 2.0, 0.0), Vector3(footprint.size.x, height_a, footprint.size.y), district.vines_per_building * 1.5)
	_add_plants(center, 4)
	building_count += 1
	if map_data:
		map_data.add_rect(footprint, color.darkened(0.3))


# --- Wahrzeichen ---

func _build_landmarks(district: CityDistrict) -> void:
	var center := Vector3(district.rect.get_center().x, 0.0, district.rect.get_center().y)
	match district.kind:
		CityDistrict.Kind.MARKET:
			_build_market(district)
		CityDistrict.Kind.CORPORATE:
			_build_corporate_towers(district)
			_build_barracks(district)
	match district.worship:
		CityDistrict.Worship.CHURCH:
			_build_church(center)
		CityDistrict.Worship.MOSQUE:
			_build_mosque(center)
		CityDistrict.Worship.SYNAGOGUE:
			_build_synagogue(center)
		CityDistrict.Worship.HOUSE_OF_SILENCE:
			_build_house_of_silence(center)


func _build_market(district: CityDistrict) -> void:
	var plaza := Rect2(district.rect.get_center() - Vector2(22, 22), Vector2(44, 44))
	_reserved.append(plaza)
	_add_box(Vector3(plaza.get_center().x, 0.02, plaza.get_center().y), Vector3(plaza.size.x, 0.04, plaza.size.y), Color(0.55, 0.5, 0.45), false, false)
	if map_data:
		map_data.add_rect(plaza, Color(0.5, 0.46, 0.4), "Marktplatz")
	var center := Vector3(plaza.get_center().x, 0.0, plaza.get_center().y)
	# Mystischer Baum in der Mitte.
	_add_cylinder(center + Vector3(0, 4, 0), 0.9, 1.3, 8.0, Color(0.35, 0.25, 0.2), true)
	for i in 6:
		var crown := center + Vector3(_rng.randf_range(-3, 3), _rng.randf_range(8.5, 11.0), _rng.randf_range(-3, 3))
		_add_glow_sphere(crown, _rng.randf_range(2.0, 3.0), Color(0.3, 0.95, 0.75), 0.8)
	# Marktstände im Kreis.
	var stall_colors: Array[Color] = [Color(0.85, 0.3, 0.3), Color(0.95, 0.7, 0.2), Color(0.3, 0.55, 0.9), Color(0.4, 0.8, 0.45), Color(0.75, 0.35, 0.8)]
	for i in 10:
		var angle := TAU * i / 10.0
		var at := center + Vector3(cos(angle), 0, sin(angle)) * 15.0
		var stall := _add_box(at + Vector3(0, 0.6, 0), Vector3(3.0, 1.2, 1.6), Color(0.45, 0.32, 0.22), true)
		stall.rotation.y = -angle
		var canopy := _add_prism(at + Vector3(0, 2.6, 0), Vector3(3.4, 0.8, 2.2), stall_colors[i % stall_colors.size()])
		canopy.rotation.y = -angle
	_add_marker(center, MapMarker.Kind.MARKET, "Marktplatz")


func _build_corporate_towers(district: CityDistrict) -> void:
	var count := 3
	for i in count:
		var x := lerpf(district.rect.position.x + 30.0, district.rect.end.x - 70.0, float(i) / (count - 1))
		var footprint := Rect2(Vector2(x, district.rect.position.y + 12.0), Vector2(22, 22))
		_reserved.append(footprint.grow(2.0))
		var height := 80.0 + i * 15.0
		var center := Vector3(footprint.get_center().x, height / 2.0, footprint.get_center().y)
		var size := Vector3(footprint.size.x, height, footprint.size.y)
		_add_box(center, size, Color(0.22, 0.24, 0.3), true)
		_add_neon_bands(center, size)
		_add_glow_box(Vector3(center.x, height + 1.5, center.z), Vector3(10, 3, 10), Color(1.0, 0.25, 0.3))
		_add_vines(center, size, 6.0)
		_add_marker(Vector3(center.x, 0, center.z), MapMarker.Kind.CORPORATE_TOWER, "Konzernturm")
		if map_data:
			map_data.add_rect(footprint, Color(0.6, 0.2, 0.25))


func _build_barracks(district: CityDistrict) -> void:
	var area := Rect2(Vector2(district.rect.end.x - 50.0, district.rect.position.y + 10.0), Vector2(40, 30))
	_reserved.append(area.grow(2.0))
	var wall_color := Color(0.3, 0.3, 0.33)
	var c := area.get_center()
	# Mauer mit Tor im Süden.
	_add_box(Vector3(c.x, 2, area.position.y), Vector3(area.size.x, 4, 1), wall_color, true)
	_add_box(Vector3(area.position.x, 2, c.y), Vector3(1, 4, area.size.y), wall_color, true)
	_add_box(Vector3(area.end.x, 2, c.y), Vector3(1, 4, area.size.y), wall_color, true)
	_add_box(Vector3(area.position.x + area.size.x * 0.2, 2, area.end.y), Vector3(area.size.x * 0.4, 4, 1), wall_color, true)
	_add_box(Vector3(area.end.x - area.size.x * 0.2, 2, area.end.y), Vector3(area.size.x * 0.4, 4, 1), wall_color, true)
	_add_box(Vector3(c.x - 8, 3.5, c.y - 4), Vector3(14, 7, 10), Color(0.35, 0.36, 0.4), true)
	_add_box(Vector3(c.x + 10, 2.5, c.y - 6), Vector3(10, 5, 8), Color(0.35, 0.36, 0.4), true)
	_add_glow_box(Vector3(c.x, 4.3, area.end.y), Vector3(4, 0.4, 1.2), Color(1.0, 0.2, 0.25))
	_add_marker(Vector3(c.x, 0, c.y), MapMarker.Kind.BARRACKS, "Kaserne")
	if map_data:
		map_data.add_rect(area, Color(0.45, 0.2, 0.22), "Kaserne")


func _reserve_landmark(center: Vector3, size: Vector2) -> void:
	var rect := Rect2(Vector2(center.x, center.z) - size / 2.0, size)
	_reserved.append(rect.grow(4.0))
	if map_data:
		map_data.add_rect(rect, Color(0.85, 0.85, 0.9))


func _build_church(center: Vector3) -> void:
	_reserve_landmark(center, Vector2(14, 30))
	var wall := Color(0.82, 0.78, 0.7)
	_add_box(center + Vector3(0, 5, 2), Vector3(12, 10, 22), wall, true)
	_add_roof(center + Vector3(0, 10, 2), Vector3(12, 10, 22), Color(0.6, 0.3, 0.22))
	_add_box(center + Vector3(0, 10, -11), Vector3(5, 20, 5), wall, true)
	_add_prism(center + Vector3(0, 23, -11), Vector3(5, 6, 5), Color(0.35, 0.4, 0.45))
	_add_glow_box(center + Vector3(0, 7, -13.6), Vector3(2.0, 3.0, 0.2), Color(1.0, 0.8, 0.5))
	_add_vines(center + Vector3(0, 5, 2), Vector3(12, 10, 22), 4.0)
	_add_sign(center + Vector3(0, 3.5, -14.0), "Kirche")
	_add_marker(center, MapMarker.Kind.CHURCH, "Kirche")


func _build_mosque(center: Vector3) -> void:
	_reserve_landmark(center, Vector2(26, 26))
	var wall := Color(0.92, 0.88, 0.8)
	_add_box(center + Vector3(0, 4, 0), Vector3(18, 8, 18), wall, true)
	_add_dome(center + Vector3(0, 8, 0), 7.0, Color(0.25, 0.6, 0.6))
	_add_cylinder(center + Vector3(10, 13, -10), 1.1, 1.3, 26.0, wall, true)
	_add_dome(center + Vector3(10, 26, -10), 1.6, Color(0.25, 0.6, 0.6))
	_add_glow_box(center + Vector3(0, 3.5, -9.1), Vector3(3.0, 5.0, 0.2), Color(0.5, 1.0, 0.85))
	_add_vines(center + Vector3(0, 4, 0), Vector3(18, 8, 18), 4.0)
	_add_sign(center + Vector3(0, 7.0, -9.4), "Moschee")
	_add_marker(center, MapMarker.Kind.MOSQUE, "Moschee")


func _build_synagogue(center: Vector3) -> void:
	_reserve_landmark(center, Vector2(18, 22))
	var wall := Color(0.85, 0.72, 0.55)
	_add_box(center + Vector3(0, 6, 0), Vector3(14, 12, 18), wall, true)
	_add_box(center + Vector3(0, 12.5, 0), Vector3(10, 1.0, 14), wall.darkened(0.15), true)
	_add_cylinder(center + Vector3(-4.5, 6, -9.3), 0.6, 0.6, 12.0, wall.lightened(0.1), true)
	_add_cylinder(center + Vector3(4.5, 6, -9.3), 0.6, 0.6, 12.0, wall.lightened(0.1), true)
	_add_glow_disc(center + Vector3(0, 8.5, -9.15), 2.0, Color(0.6, 0.75, 1.0))
	_add_vines(center + Vector3(0, 6, 0), Vector3(14, 12, 18), 4.0)
	_add_sign(center + Vector3(0, 3.5, -9.5), "Synagoge")
	_add_marker(center, MapMarker.Kind.SYNAGOGUE, "Synagoge")


func _build_house_of_silence(center: Vector3) -> void:
	_reserve_landmark(center, Vector2(24, 18))
	_add_box(center + Vector3(0, 3, 0), Vector3(20, 6, 14), Color(0.75, 0.76, 0.78), true)
	var glass := _add_box(center + Vector3(0, 3, -7.05), Vector3(16, 4.5, 0.1), Color(0.5, 0.75, 0.95, 0.6), false, false)
	(glass.material_override as StandardMaterial3D).transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	for i in 4:
		_add_plants(center + Vector3(-9 + i * 6, 0, -10), 3)
	_add_vines(center + Vector3(0, 3, 0), Vector3(20, 6, 14), 5.0)
	_add_sign(center + Vector3(0, 6.6, -7.2), "Haus der Stille")
	_add_marker(center, MapMarker.Kind.HOUSE_OF_SILENCE, "Haus der Stille")


# --- Ranken, Pflanzen, Leuchtstreifen ---

func _add_vines(center: Vector3, size: Vector3, per_building: float) -> void:
	var count := _rng.randi_range(int(per_building * 0.5), int(per_building * 1.5))
	for i in count:
		var color := VINE_COLORS[_rng.randi() % VINE_COLORS.size()]
		var height := _rng.randf_range(size.y * 0.3, size.y * 0.95)
		var width := _rng.randf_range(0.25, 0.7)
		var side := _rng.randi() % 4
		var along := _rng.randf_range(-0.45, 0.45)
		var at := Vector3.ZERO
		var vine_size := Vector3.ZERO
		match side:
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
		var base_y := center.y - size.y / 2.0
		_add_glow_box(Vector3(center.x + at.x, base_y + height / 2.0, center.z + at.z), vine_size, color, 0.6)
		# Leuchtende Blüte am Ende der Ranke.
		_add_glow_sphere(Vector3(center.x + at.x, base_y + height, center.z + at.z), _rng.randf_range(0.3, 0.6), color, 1.5)


func _add_plants(center: Vector3, count: int) -> void:
	for i in count:
		var at := center + Vector3(_rng.randf_range(-3, 3), 0, _rng.randf_range(-3, 3))
		var height := _rng.randf_range(0.6, 2.0)
		var color := VINE_COLORS[_rng.randi() % VINE_COLORS.size()]
		_add_cylinder(at + Vector3(0, height / 2.0, 0), 0.05, 0.08, height, Color(0.15, 0.35, 0.2), false)
		_add_glow_sphere(at + Vector3(0, height, 0), _rng.randf_range(0.2, 0.45), color, 1.8)


func _add_neon_bands(center: Vector3, size: Vector3) -> void:
	var colors: Array[Color] = [Color(1.0, 0.2, 0.6), Color(0.2, 0.8, 1.0), Color(0.7, 0.3, 1.0)]
	var color := colors[_rng.randi() % colors.size()]
	var y := center.y - size.y / 2.0 + 6.0
	while y < center.y + size.y / 2.0 - 2.0:
		_add_glow_box(Vector3(center.x, y, center.z), Vector3(size.x + 0.15, 0.25, size.z + 0.15), color, 1.2)
		y += _rng.randf_range(6.0, 12.0)


# --- Bausteine ---

func _add_box(center: Vector3, size: Vector3, color: Color, solid: bool, outline: bool = true) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var instance := _add_mesh(mesh, center, ToonStyle.make(color, outline))
	if solid:
		_add_collision(instance, size)
	return instance


func _add_prism(center: Vector3, size: Vector3, color: Color) -> MeshInstance3D:
	var mesh := PrismMesh.new()
	mesh.size = size
	return _add_mesh(mesh, center, ToonStyle.make(color))


func _add_roof(top_center: Vector3, house_size: Vector3, color: Color) -> void:
	var roof_height := minf(house_size.x, house_size.z) * 0.35
	# Der First (Dachkante) läuft entlang der längeren Seite.
	var roof := _add_prism(top_center + Vector3(0, roof_height / 2.0, 0), Vector3(house_size.x + 0.6, roof_height, house_size.z + 0.6), color)
	if house_size.x > house_size.z:
		roof.rotation.y = PI / 2.0
		(roof.mesh as PrismMesh).size = Vector3(house_size.z + 0.6, roof_height, house_size.x + 0.6)


func _add_cylinder(center: Vector3, top: float, bottom: float, height: float, color: Color, solid: bool) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = top
	mesh.bottom_radius = bottom
	mesh.height = height
	var instance := _add_mesh(mesh, center, ToonStyle.make(color, solid))
	if solid:
		_add_collision(instance, Vector3(bottom * 2.0, height, bottom * 2.0))
	return instance


func _add_dome(center: Vector3, radius: float, color: Color) -> void:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.is_hemisphere = true
	_add_mesh(mesh, center, ToonStyle.make(color))


func _add_glow_box(center: Vector3, size: Vector3, color: Color, energy: float = 1.5) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	return _add_mesh(mesh, center, _glow_material(color, energy))


func _add_glow_sphere(center: Vector3, radius: float, color: Color, energy: float) -> void:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = 12
	mesh.rings = 6
	_add_mesh(mesh, center, _glow_material(color, energy))


func _add_glow_disc(center: Vector3, radius: float, color: Color) -> void:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = 0.15
	var disc := _add_mesh(mesh, center, _glow_material(color, 1.5))
	disc.rotation.x = PI / 2.0


func _glow_material(color: Color, energy: float) -> StandardMaterial3D:
	var material := ToonStyle.make(color, false)
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = energy
	return material


func _add_mesh(mesh: Mesh, center: Vector3, material: Material) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.material_override = material
	# Position vor dem Einfügen setzen, damit die Kollision sofort am richtigen Ort ist.
	instance.position = center
	add_child(instance)
	return instance


func _add_collision(instance: MeshInstance3D, size: Vector3) -> void:
	var body := StaticBody3D.new()
	body.collision_layer = PhysicsLayers.WORLD
	body.collision_mask = 0
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	body.add_child(shape)
	instance.add_child(body)


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

class_name MapView
extends Control
## Zeichnet Grundriss und Marker. Zwei Arten:
## - Minimap: Spieler in der Mitte, dreht mit der Kamera (oben = Blickrichtung).
## - Große Karte: genordet, zeigt die ganze Gegend.

@export var minimap: bool = true
## Pixel pro Meter auf der Minimap.
@export var minimap_scale: float = 2.2

const BACKGROUND := Color(0.06, 0.07, 0.1, 0.85)


func _process(_delta: float) -> void:
	if is_visible_in_tree():
		queue_redraw()


func _draw() -> void:
	var player := get_tree().get_first_node_in_group(&"player") as Player
	var map_data := get_tree().get_first_node_in_group(&"map_data") as MapData
	draw_rect(Rect2(Vector2.ZERO, size), BACKGROUND)
	var center := Vector2.ZERO
	var angle := 0.0
	var scale := minimap_scale
	var origin := size / 2.0
	if minimap and player:
		center = Vector2(player.global_position.x, player.global_position.z)
		angle = player.camera_rig.rotation.y
	elif map_data:
		center = map_data.bounds.get_center()
		scale = minf(size.x / map_data.bounds.size.x, size.y / map_data.bounds.size.y) * 0.95
	var to_screen := func(world: Vector2) -> Vector2:
		return origin + (world - center).rotated(angle) * scale
	if map_data:
		# Auf der Minimap nur zeichnen, was in der Nähe ist.
		var view_radius := size.length() / 2.0 / scale
		for shape in map_data.shapes:
			var shape_center: Vector2 = shape["center"]
			if minimap and shape_center.distance_to(center) > view_radius + float(shape["radius"]):
				continue
			var world_points: PackedVector2Array = shape["points"]
			var points := PackedVector2Array()
			points.resize(world_points.size())
			for i in world_points.size():
				points[i] = to_screen.call(world_points[i])
			var width: float = shape["width"]
			if width > 0.0:
				draw_polyline(points, shape["color"], maxf(width * scale, 1.0))
			else:
				draw_colored_polygon(points, shape["color"])
		if not minimap:
			_draw_labels(map_data, to_screen)
	_draw_markers(to_screen)
	if player:
		var player_screen: Vector2 = origin if minimap else to_screen.call(Vector2(player.global_position.x, player.global_position.z))
		var facing := 0.0 if minimap else -player.camera_rig.rotation.y
		_draw_player_arrow(player_screen, facing)
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.5, 0.6, 0.8, 0.8), false, 2.0)


func _draw_labels(map_data: MapData, to_screen: Callable) -> void:
	var font := ThemeDB.fallback_font
	for shape in map_data.shapes:
		var label: String = shape["label"]
		if label == "":
			continue
		var at: Vector2 = to_screen.call(shape["center"])
		var width := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x
		draw_string_outline(font, at - Vector2(width / 2.0, 0.0), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, 4, Color(0, 0, 0, 0.8))
		draw_string(font, at - Vector2(width / 2.0, 0.0), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(1, 1, 1, 0.75))


func _draw_markers(to_screen: Callable) -> void:
	var font := ThemeDB.fallback_font
	var radius := 9.0 if minimap else 11.0
	var limit := size / 2.0 - Vector2(radius, radius)
	for node: Node in get_tree().get_nodes_in_group(&"map_markers"):
		var marker := node as MapMarker
		if marker == null or not marker.is_shown():
			continue
		var at: Vector2 = to_screen.call(Vector2(marker.global_position.x, marker.global_position.z))
		if minimap:
			# Außerhalb der Minimap: am Rand festhalten.
			var offset := at - size / 2.0
			offset = offset.clamp(-limit, limit)
			at = size / 2.0 + offset
		elif not Rect2(Vector2.ZERO, size).has_point(at):
			continue
		draw_circle(at, radius, Color(0.05, 0.05, 0.08, 0.9))
		draw_circle(at, radius, marker.get_color(), false, 2.0)
		var symbol := marker.get_symbol()
		var font_size := 12 if symbol.length() > 1 else 14
		var text_size := font.get_string_size(symbol, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
		draw_string(font, at + Vector2(-text_size.x / 2.0, text_size.y / 3.0), symbol, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, marker.get_color())


func _draw_player_arrow(at: Vector2, facing: float) -> void:
	var points := PackedVector2Array([Vector2(0, -10), Vector2(7, 8), Vector2(0, 4), Vector2(-7, 8)])
	for i in points.size():
		points[i] = at + points[i].rotated(facing)
	draw_colored_polygon(points, Color(1, 1, 1))
	draw_polyline(points + PackedVector2Array([points[0]]), Color(0, 0, 0), 1.5)

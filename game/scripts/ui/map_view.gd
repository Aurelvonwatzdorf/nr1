class_name MapView
extends Control
## Zeichnet Grundriss und Marker. Zwei Arten:
## - Minimap: Spieler in der Mitte, dreht mit der Kamera (oben = Blickrichtung).
## - Große Karte: genordet, zeigt die ganze Gegend.

@export var minimap: bool = true
## Pixel pro Meter auf der Minimap.
@export var minimap_scale: float = 2.2

const BACKGROUND := Color(0.06, 0.07, 0.1, 0.85)
const ROUTE_COLOR := Color(0.85, 0.35, 1.0)

## Umrechnung Welt → Bildschirm vom letzten Zeichnen (für Mausklicks).
var _center: Vector2 = Vector2.ZERO
var _scale: float = 1.0
var _angle: float = 0.0


func _ready() -> void:
	# Auf der großen Karte kann man klicken (Wegpunkt setzen).
	mouse_filter = Control.MOUSE_FILTER_IGNORE if minimap else Control.MOUSE_FILTER_STOP


func _gui_input(event: InputEvent) -> void:
	if minimap or not event is InputEventMouseButton or not event.is_pressed():
		return
	var click := event as InputEventMouseButton
	if click.button_index == MOUSE_BUTTON_RIGHT:
		GameState.clear_map_waypoint()
		accept_event()
	elif click.button_index == MOUSE_BUTTON_LEFT:
		var world := screen_to_world(click.position)
		# Klick auf den vorhandenen Wegpunkt löscht ihn wieder.
		if GameState.has_map_waypoint and world_to_screen(GameState.map_waypoint).distance_to(click.position) < 12.0:
			GameState.clear_map_waypoint()
		else:
			GameState.set_map_waypoint(world)
			var city := get_tree().get_first_node_in_group(&"city_generator") as CityGenerator
			if city:
				city.update_route()
		accept_event()


## Mitte, Maßstab und Drehung der Karte bestimmen.
func _update_view() -> void:
	var player := get_tree().get_first_node_in_group(&"player") as Player
	var map_data := get_tree().get_first_node_in_group(&"map_data") as MapData
	_center = Vector2.ZERO
	_angle = 0.0
	_scale = minimap_scale
	if minimap and player:
		_center = Vector2(player.global_position.x, player.global_position.z)
		_angle = player.camera_rig.rotation.y
	elif map_data:
		_center = map_data.bounds.get_center()
		_scale = minf(size.x / map_data.bounds.size.x, size.y / map_data.bounds.size.y) * 0.95
	_scale = maxf(_scale, 0.001)


func world_to_screen(world: Vector2) -> Vector2:
	_update_view()
	return size / 2.0 + (world - _center).rotated(_angle) * _scale


func screen_to_world(screen: Vector2) -> Vector2:
	_update_view()
	return _center + ((screen - size / 2.0) / _scale).rotated(-_angle)


func _process(_delta: float) -> void:
	if is_visible_in_tree():
		queue_redraw()


func _draw() -> void:
	var player := get_tree().get_first_node_in_group(&"player") as Player
	var map_data := get_tree().get_first_node_in_group(&"map_data") as MapData
	draw_rect(Rect2(Vector2.ZERO, size), BACKGROUND)
	_update_view()
	var center := _center
	var angle := _angle
	var scale := _scale
	var origin := size / 2.0
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
	_draw_route(to_screen, player)
	_draw_markers(to_screen)
	if GameState.inventory.has_radar():
		_draw_radar(to_screen)
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


## Navi: schnellster Weg zum Wegpunkt als Linie, dazu der Wegpunkt selbst.
func _draw_route(to_screen: Callable, player: Player) -> void:
	if not GameState.has_map_waypoint:
		return
	var city := get_tree().get_first_node_in_group(&"city_generator") as CityGenerator
	var route := PackedVector2Array()
	if city and not city.current_route.is_empty():
		route = city.current_route
	elif player:
		route = PackedVector2Array([Vector2(player.global_position.x, player.global_position.z), GameState.map_waypoint])
	if route.size() >= 2:
		var points := PackedVector2Array()
		for point in route:
			points.append(to_screen.call(point))
		draw_polyline(points, Color(0, 0, 0, 0.6), 7.0)
		draw_polyline(points, ROUTE_COLOR, 4.0)
	var at: Vector2 = to_screen.call(GameState.map_waypoint)
	if minimap:
		var limit := size / 2.0 - Vector2(10, 10)
		at = size / 2.0 + (at - size / 2.0).clamp(-limit, limit)
	var pin := PackedVector2Array([at + Vector2(0, -11), at + Vector2(8, 0), at + Vector2(0, 11), at + Vector2(-8, 0)])
	draw_colored_polygon(pin, ROUTE_COLOR)
	draw_polyline(pin + PackedVector2Array([pin[0]]), Color(0, 0, 0), 2.0)


## Radar (gekauft auf dem Schwarzmarkt): Gegner als rote Punkte.
func _draw_radar(to_screen: Callable) -> void:
	for node: Node in get_tree().get_nodes_in_group(&"enemies"):
		var enemy := node as Enemy
		if enemy == null or enemy.health.is_dead:
			continue
		var at: Vector2 = to_screen.call(Vector2(enemy.global_position.x, enemy.global_position.z))
		if Rect2(Vector2.ZERO, size).has_point(at):
			draw_circle(at, 4.0, Color(1.0, 0.2, 0.2))


func _draw_player_arrow(at: Vector2, facing: float) -> void:
	var points := PackedVector2Array([Vector2(0, -10), Vector2(7, 8), Vector2(0, 4), Vector2(-7, 8)])
	for i in points.size():
		points[i] = at + points[i].rotated(facing)
	draw_colored_polygon(points, Color(1, 1, 1))
	draw_polyline(points + PackedVector2Array([points[0]]), Color(0, 0, 0), 1.5)

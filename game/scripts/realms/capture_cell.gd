class_name CaptureCell
extends CorporateTower
## „Das Wartezimmer“: Hierhin sperren die Spiegeljäger einen. Ein endloser
## Warteraum, in dem die eigene Nummer nie aufgerufen wird. Zwei Risse finden,
## dann bricht man aus und wacht am letzten Ankerspiegel wieder auf.
## (Nutzt die Bauhelfer des Konzernturms.)


func _build_tower() -> void:
	var root := get_node_or_null("Geometry") as Node3D
	if root == null:
		root = Node3D.new()
		root.name = "Geometry"
		add_child(root)
	_box(root, "Floor", Vector3(0, -0.5, -16), Vector3(24, 1, 48), FLOOR_COLOR.darkened(0.1))
	_box(root, "WallWest", Vector3(-12, 3, -16), Vector3(1, 6, 48), WALL_COLOR)
	_box(root, "WallEast", Vector3(12, 3, -16), Vector3(1, 6, 48), WALL_COLOR)
	_box(root, "WallBack", Vector3(0, 3, -40), Vector3(24, 6, 1), Color(0.75, 0.78, 0.85))
	_box(root, "WallSouth", Vector3(0, 3, 8), Vector3(24, 6, 1), WALL_COLOR)
	_box(root, "WallNorthLeft", Vector3(-7, 3, -28), Vector3(10, 6, 1), WALL_COLOR)
	_box(root, "WallNorthRight", Vector3(7, 3, -28), Vector3(10, 6, 1), WALL_COLOR)
	_box(root, "WallNorthTop", Vector3(0, 5, -28), Vector3(4, 2, 1), WALL_COLOR)
	# Stuhlreihen, alle zur Anzeige gedreht.
	for row in 5:
		for seat in 6:
			var at := Vector3(-7.5 + seat * 3.0, 0, 2 - row * 3.5)
			_box(root, "Chair%d_%d" % [row, seat], at + Vector3(0, 0.25, 0), Vector3(1.0, 0.5, 1.0), ACCENT_COLOR)
			_box(root, "ChairBack%d_%d" % [row, seat], at + Vector3(0, 0.75, 0.45), Vector3(1.0, 1.0, 0.1), ACCENT_COLOR, false)
	_box(root, "Counter", Vector3(0, 0.6, -20), Vector3(8, 1.2, 1.2), DESK_COLOR)
	_box(root, "Display", Vector3(0, 4.2, -27.4), Vector3(6, 1.4, 0.2), Color(0.1, 0.12, 0.15), false)
	_label(root, Vector3(0, 4.2, -27.2), "Aufgerufen: 4416   ·   Ihre Nummer: 4417")
	for i in 3:
		_glow(root, Vector3(0, 6.2, 4 - i * 12.0), Vector3(20, 0.15, 0.6), LIGHT_COLOR)
	var door_root := get_node_or_null("BackDoor") as Node3D
	if door_root:
		_box(door_root, "FalseDoor", Vector3(0, 2, -28), Vector3(4, 4, 1), WALL_COLOR)


func _register_map() -> void:
	var map_data := get_node_or_null("MapData") as MapData
	if map_data == null:
		return
	map_data.bounds = Rect2(-14, -42, 28, 52)
	map_data.area_name = "Das Wartezimmer"
	map_data.add_rect(Rect2(-12, -40, 24, 48), Color(0.55, 0.57, 0.62))

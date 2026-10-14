extends Level
## Testarena: zum Ausprobieren neuer Mechaniken und für den Rauchtest.


func _ready() -> void:
	super._ready()
	_register_map_shapes()


## Boden und Hindernisse als Grundriss für die Karte eintragen.
func _register_map_shapes() -> void:
	var map_data := get_node_or_null("MapData") as MapData
	if map_data == null:
		return
	map_data.add_rect(Rect2(-30, -30, 60, 60), Color(0.22, 0.23, 0.26))
	map_data.add_rect(Rect2(-20, 11, 40, 4), Color(0.12, 0.12, 0.14), "Straße")
	for node: Node in $Obstacles.get_children():
		var body := node as StaticBody3D
		var mesh_instance := body.get_node_or_null("Mesh") as MeshInstance3D
		if mesh_instance and mesh_instance.mesh is BoxMesh:
			var box_size := (mesh_instance.mesh as BoxMesh).size
			var at := body.global_position
			map_data.add_rect(Rect2(at.x - box_size.x / 2.0, at.z - box_size.z / 2.0, box_size.x, box_size.z), Color(0.45, 0.46, 0.52))

extends Node3D
## Testarena: verbindet HUD und Spielfigur. Hier wird später auch ausprobiert,
## was neu dazukommt (Gegner in M2, Ankerspiegel in M3 …).

@onready var player: Player = $Player
@onready var hud: HUD = $HUD

## Wurde beim Start ein Spielstand geladen?
var _loaded_save: bool = false


func _enter_tree() -> void:
	# Vor allen _ready()-Aufrufen laden, damit Figur, Gegenstände und Stats
	# gleich mit den gespeicherten Daten starten.
	if SaveSystem.auto_load_enabled:
		_loaded_save = SaveSystem.load_game()


func _ready() -> void:
	ToonStyle.apply_to_tree(self)
	_register_map_shapes()
	if _loaded_save and GameState.has_checkpoint:
		player.global_transform = GameState.checkpoint_transform
		player.rest()
		hud.show_message.call_deferred("Spielstand geladen")
	# Die Arena kennt beide und verbindet sie. (_ready der Arena läuft erst,
	# wenn alle Kinder fertig sind.)
	hud.bind_player(player)


## Testarena: Boden und Hindernisse als Grundriss für die Karte eintragen.
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

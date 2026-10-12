class_name AnchorMirror
extends Interactable
## Ankerspiegel: Rastpunkt. Rasten heilt voll, setzt Gegner zurück und macht den
## Spiegel zum Wiederbelebungsort. Danach öffnet sich das Rast-Menü (Level-Up).
## (Ab M7 senkt Rasten auch die Verankerung.)

@onready var spawn_point: Marker3D = $SpawnPoint
@onready var glass: MeshInstance3D = $Glass

var _material: StandardMaterial3D


func _ready() -> void:
	super._ready()
	_material = StandardMaterial3D.new()
	_material.albedo_color = Color(0.55, 0.6, 0.75, 0.85)
	_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_material.metallic = 1.0
	_material.roughness = 0.05
	_material.emission_enabled = true
	glass.material_override = _material
	_set_active(is_active())
	EventBus.checkpoint_activated.connect(func(other: Node3D) -> void: _set_active(other == self))


func interact(player: Player) -> void:
	rest(player)
	super.interact(player)


func rest(player: Player) -> void:
	var first_time := not is_active()
	GameState.set_checkpoint(spawn_point.global_transform)
	if first_time:
		EventBus.checkpoint_activated.emit(self)
	player.rest()
	get_tree().call_group(&"enemies", &"reset_enemy")
	if player.character_data.id == &"aurel":
		EventBus.message_requested.emit("Aurel zündet sich eine Zigarette an.")
	EventBus.anchor_mirror_rested.emit(self, player)


func is_active() -> bool:
	return GameState.has_checkpoint and GameState.checkpoint_transform.is_equal_approx(spawn_point.global_transform)


func _set_active(active: bool) -> void:
	_material.emission = Color(0.45, 0.85, 1.0) if active else Color(0.1, 0.12, 0.2)
	_material.emission_energy_multiplier = 1.8 if active else 0.3

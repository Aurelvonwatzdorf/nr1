class_name Checkpoint
extends Area3D
## Checkpoint: Wer hindurchläuft, wird nach dem Tod hier wiederbelebt.
## (In M3 wird daraus der Ankerspiegel mit Rasten, Heilen und Speichern.)

@onready var spawn_point: Marker3D = $SpawnPoint
@onready var crystal: MeshInstance3D = $Crystal

var _material: StandardMaterial3D


func _ready() -> void:
	collision_layer = 0
	collision_mask = PhysicsLayers.PLAYER
	_material = StandardMaterial3D.new()
	_material.albedo_color = Color(0.5, 0.55, 0.65)
	_material.emission_enabled = true
	crystal.material_override = _material
	_set_active(false)
	body_entered.connect(_on_body_entered)
	EventBus.checkpoint_activated.connect(func(other: Node3D) -> void: _set_active(other == self))


func _on_body_entered(body: Node3D) -> void:
	if body is Player and not is_active():
		GameState.set_checkpoint(spawn_point.global_transform)
		EventBus.checkpoint_activated.emit(self)


func is_active() -> bool:
	return GameState.has_checkpoint and GameState.checkpoint_transform.is_equal_approx(spawn_point.global_transform)


func _set_active(active: bool) -> void:
	_material.emission = Color(0.4, 0.9, 1.0) if active else Color(0.15, 0.2, 0.3)
	_material.emission_energy_multiplier = 2.5 if active else 0.4

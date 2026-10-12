class_name RespawnManager
extends Node
## Regelt, was nach dem Tod der Spielfigur passiert:
## 1. Erinnerungen bleiben an der Todesstelle liegen (alte Reste gehen verloren).
## 2. Nach kurzer Wartezeit: Gegner zurücksetzen, Figur am Checkpoint wiederbeleben.

@export var player: Player
@export var remnant_scene: PackedScene
## Wartezeit zwischen Tod und Wiederbelebung (Sekunden).
@export var respawn_delay: float = 3.0

var _remnant: MemoryRemnant


func _ready() -> void:
	if not GameState.has_checkpoint:
		GameState.set_checkpoint(player.global_transform)
	EventBus.player_died.connect(_on_player_died)


## Die aktuell liegenden Erinnerungen (oder null).
func get_remnant() -> MemoryRemnant:
	return _remnant if is_instance_valid(_remnant) else null


func _on_player_died(dead_player: Player) -> void:
	if dead_player != player:
		return
	# Wer erneut stirbt, bevor er die alten Erinnerungen geholt hat, verliert sie.
	var old := get_remnant()
	if old:
		EventBus.memories_lost.emit(old.amount)
		old.queue_free()
	_remnant = null
	if GameState.memories > 0:
		_remnant = remnant_scene.instantiate() as MemoryRemnant
		_remnant.amount = GameState.memories
		get_parent().add_child(_remnant)
		_remnant.global_position = player.global_position + Vector3.UP * 0.6
		GameState.memories = 0

	await get_tree().create_timer(respawn_delay).timeout
	get_tree().call_group(&"enemies", &"reset_enemy")
	player.respawn(GameState.checkpoint_transform)

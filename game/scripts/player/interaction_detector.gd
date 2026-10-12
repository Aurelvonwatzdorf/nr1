class_name InteractionDetector
extends Area3D
## Findet das nächste Interactable in Reichweite der Spielfigur.

## Das Interactable, das E gerade auslösen würde (oder null).
var current: Interactable


func _ready() -> void:
	collision_layer = 0
	collision_mask = PhysicsLayers.INTERACTABLE
	monitoring = true
	monitorable = false


func _physics_process(_delta: float) -> void:
	var player := owner as Player
	var best: Interactable = null
	var best_distance := INF
	for area: Area3D in get_overlapping_areas():
		var interactable := area as Interactable
		if interactable == null or not interactable.can_interact(player):
			continue
		var distance := global_position.distance_to(interactable.global_position)
		if distance < best_distance:
			best_distance = distance
			best = interactable
	if best != current:
		current = best
		EventBus.interaction_prompt_changed.emit(current.prompt if current else "")

class_name MemoryRemnant
extends Area3D
## Die Erinnerungen, die beim Tod liegen bleiben. Hineinlaufen holt sie zurück.

## Wie viele Erinnerungen hier liegen.
var amount: int = 0

@onready var label: Label3D = $Label3D


func _ready() -> void:
	collision_layer = 0
	collision_mask = PhysicsLayers.PLAYER
	label.text = str(amount)
	# Auf Minimap und großer Karte zeigen, wo die Erinnerungen liegen.
	var marker := MapMarker.new()
	marker.kind = MapMarker.Kind.MEMORY_REMNANT
	marker.label = "Deine Erinnerungen (%d)" % amount
	add_child(marker)
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node3D) -> void:
	var player := body as Player
	if player == null or player.health.is_dead:
		return
	GameState.memories += amount
	EventBus.memories_recovered.emit(amount)
	queue_free()

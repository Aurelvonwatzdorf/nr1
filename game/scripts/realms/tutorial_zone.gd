class_name TutorialZone
extends Area3D
## Bereich, der beim ersten Betreten einen Hinweis zeigt (Steuerung lernen) und
## optional den Begleiter etwas sagen lässt.

@export_multiline var message: String = ""
@export_multiline var companion_line: String = ""

var triggered: bool = false


func _ready() -> void:
	collision_layer = 0
	collision_mask = PhysicsLayers.PLAYER
	monitorable = false
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node3D) -> void:
	if triggered or not body is Player:
		return
	triggered = true
	if message != "":
		EventBus.message_requested.emit(message)
	if companion_line != "":
		EventBus.companion_spoke.emit(companion_line)

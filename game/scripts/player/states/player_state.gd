class_name PlayerState
extends State
## Basis für alle Spieler-Zustände. Bietet Zugriff auf `player` und
## gemeinsame Prüfungen (Ausweichen/Angreifen starten).

var player: Player


func setup(new_actor: Node, machine: StateMachine) -> void:
	super.setup(new_actor, machine)
	player = new_actor as Player


## Prüft, ob Ausweichen oder Angreifen gedrückt wurde, und wechselt dann.
## Gibt true zurück, wenn gewechselt wurde.
func try_start_combat_action() -> bool:
	if not player.is_input_enabled() or not player.stamina.can_act():
		return false
	if Input.is_action_just_pressed(&"dodge"):
		state_machine.transition_to(&"dodge")
		return true
	var heavy := is_heavy_attack_pressed()
	if heavy or Input.is_action_just_pressed(&"attack_light"):
		state_machine.transition_to(&"attack", {"heavy": heavy})
		return true
	return false


## Schwerer Angriff: RT am Gamepad oder Shift + Linksklick.
static func is_heavy_attack_pressed() -> bool:
	if Input.is_action_just_pressed(&"attack_heavy"):
		return true
	return Input.is_action_just_pressed(&"attack_light") and Input.is_action_pressed(&"sprint")


## Zurück zu Stehen oder Laufen, je nach Eingabe.
func return_to_locomotion() -> void:
	if player.get_move_direction() == Vector3.ZERO:
		state_machine.transition_to(&"idle")
	else:
		state_machine.transition_to(&"move")

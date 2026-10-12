class_name PlayerBlockState
extends PlayerState
## Blocken (Taste halten). Treffer von vorne werden abgeschwächt und kosten
## Ausdauer. Wer im allerersten Moment getroffen wird, pariert (siehe Player).

## Wie lange schon geblockt wird. Am Anfang liegt das Parier-Fenster.
var time_in_block: float = 0.0


func enter(_msg: Dictionary = {}) -> void:
	time_in_block = 0.0
	player.animator.set_blocking(true)


func exit() -> void:
	player.animator.set_blocking(false)


func is_in_parry_window() -> bool:
	return time_in_block <= player.character_data.parry_window


func physics_update(delta: float) -> void:
	time_in_block += delta
	player.apply_gravity(delta)
	var data := player.character_data
	if not player.is_input_enabled() or not Input.is_action_pressed(&"block"):
		return_to_locomotion()
		return
	if Input.is_action_just_pressed(&"dodge") and player.stamina.can_act():
		state_machine.transition_to(&"dodge")
		return
	# Langsam gehen, Blick bleibt beim Ziel (Lock-on) oder in Laufrichtung.
	var direction := player.get_move_direction()
	player.accelerate_to(direction * data.block_move_speed, delta)
	var lock_direction := player.get_direction_to_lock_target()
	player.turn_towards(lock_direction if lock_direction != Vector3.ZERO else direction, delta)

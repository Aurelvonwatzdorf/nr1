class_name PlayerIdleState
extends PlayerState
## Stehen. Bremst ab und wartet auf Eingaben.


func enter(_msg: Dictionary = {}) -> void:
	player.animator.play(&"idle")
	player.animator.set_locomotion_blend(0.0)


func physics_update(delta: float) -> void:
	player.apply_gravity(delta)
	player.accelerate_to(Vector3.ZERO, delta)
	player.turn_towards(player.get_direction_to_lock_target(), delta)
	if player.is_on_floor() and (player.is_crouched() \
			or (player.is_input_enabled() and Input.is_action_pressed(&"crouch"))):
		state_machine.transition_to(&"crouch")
		return
	if try_start_combat_action():
		return
	if player.try_mantle():
		return
	player.try_jump()
	if player.get_move_direction() != Vector3.ZERO:
		state_machine.transition_to(&"move")

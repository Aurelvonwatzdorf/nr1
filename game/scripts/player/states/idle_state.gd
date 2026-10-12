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
	if try_start_combat_action():
		return
	if player.get_move_direction() != Vector3.ZERO:
		state_machine.transition_to(&"move")

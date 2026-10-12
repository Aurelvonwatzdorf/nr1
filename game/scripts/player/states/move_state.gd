class_name PlayerMoveState
extends PlayerState
## Gehen und Sprinten. Sprinten kostet laufend Ausdauer.


func enter(_msg: Dictionary = {}) -> void:
	player.animator.play(&"move")


func physics_update(delta: float) -> void:
	player.apply_gravity(delta)
	if try_start_combat_action():
		return
	var direction := player.get_move_direction()
	if direction == Vector3.ZERO:
		state_machine.transition_to(&"idle")
		return

	var data := player.character_data
	var sprinting := Input.is_action_pressed(&"sprint") and player.stamina.can_act()
	var speed := data.sprint_speed if sprinting else data.walk_speed
	if sprinting:
		player.stamina.drain(data.sprint_stamina_per_second * delta)

	player.accelerate_to(direction * speed, delta)
	player.turn_towards(direction, delta)
	player.animator.set_locomotion_blend(direction.length() * speed / data.sprint_speed)

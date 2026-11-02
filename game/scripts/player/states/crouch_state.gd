class_name PlayerCrouchState
extends PlayerState
## Ducken (C halten, Gamepad B halten): langsam und niedrig gehen. Grundlage
## für den Schleichgang. Aufstehen beim Loslassen, aber nur mit Platz über
## dem Kopf. Ausweichen und Angreifen richten die Figur auf.


func enter(_msg: Dictionary = {}) -> void:
	player.set_body_height(player.character_data.crouch_height)
	player.animator.play(&"crouch")


func exit() -> void:
	if player.can_stand_up():
		player.set_body_height(0.0)


func physics_update(delta: float) -> void:
	var data := player.character_data
	player.apply_gravity(delta)
	var can_stand := player.can_stand_up()
	var crouch_held := player.is_input_enabled() and Input.is_action_pressed(&"crouch")
	if can_stand:
		if try_start_combat_action():
			return
		if player.is_input_enabled() and Input.is_action_just_pressed(&"jump"):
			player.set_body_height(0.0)
			player.try_jump()
			state_machine.transition_to(&"move")
			return
		if not crouch_held:
			return_to_locomotion()
			return
	var direction := player.get_move_direction()
	player.accelerate_to(direction * data.crouch_speed * player.get_speed_multiplier(), delta)
	var lock_direction := player.get_direction_to_lock_target()
	player.turn_towards(lock_direction if lock_direction != Vector3.ZERO else direction, delta)
	player.animator.set_locomotion_blend(direction.length() * 0.3)

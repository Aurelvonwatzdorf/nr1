class_name PlayerSlideState
extends PlayerState
## Gleitschritt: aus dem Sprint mit Ducken (C) flach über den Boden rutschen.
## Erst schneller als der Sprint, dann bis Gehtempo langsamer. Körper niedrig,
## passt unter Hindernisse. Keine I-Frames (die gehören der Rolle).
## Aus dem Rutschen: angreifen, ausweichen, springen. Am Ende ducken, wenn C
## noch gehalten wird oder über einem kein Platz ist.

var _direction: Vector3 = Vector3.ZERO
var _time: float = 0.0


func enter(_msg: Dictionary = {}) -> void:
	var data := player.character_data
	player.stamina.consume(data.slide_stamina_cost)
	player.slide_cooldown_left = data.slide_cooldown
	_time = 0.0
	_direction = player.get_move_direction()
	_direction = Vector3(_direction.x, 0.0, _direction.z).normalized()
	player.snap_towards(_direction)
	player.set_body_height(data.slide_height)
	player.camera_rig.punch_fov(6.0, data.slide_duration)


func exit() -> void:
	if player.can_stand_up():
		player.set_body_height(0.0)


func physics_update(delta: float) -> void:
	var data := player.character_data
	_time += delta
	player.apply_gravity(delta)
	var progress := clampf(_time / data.slide_duration, 0.0, 1.0)
	var start_speed := data.sprint_speed * data.slide_speed_factor * player.get_speed_multiplier()
	var speed := lerpf(start_speed, data.walk_speed, progress)
	player.velocity.x = _direction.x * speed
	player.velocity.z = _direction.z * speed

	var can_stand := player.can_stand_up()
	if can_stand:
		if try_start_combat_action():
			return
		if player.is_input_enabled() and Input.is_action_just_pressed(&"jump"):
			player.set_body_height(0.0)
			player.try_jump()
			state_machine.transition_to(&"move")
			return
	if not player.is_on_floor() and progress > 0.2:
		# Über eine Kante gerutscht: im Fallen wieder aufrichten.
		if can_stand:
			player.set_body_height(0.0)
			return_to_locomotion()
		return
	if progress >= 1.0:
		var crouch_held := player.is_input_enabled() and Input.is_action_pressed(&"crouch")
		if crouch_held or not can_stand:
			state_machine.transition_to(&"crouch")
		else:
			return_to_locomotion()

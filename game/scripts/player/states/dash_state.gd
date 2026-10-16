class_name PlayerDashState
extends PlayerState
## Schubsprung (Implantat „Schubknoten“): kurzer, schneller Stoß in die gedrückte
## Richtung. In der Luft waagerecht ohne Absinken (einmal pro Sprung), am Boden
## beim Rennen statt der Rolle. Kürzere I-Frames als die Rolle, dafür billiger.

var _direction: Vector3 = Vector3.ZERO
var _time: float = 0.0
var _in_air: bool = false


func enter(_msg: Dictionary = {}) -> void:
	var data := player.character_data
	player.stamina.consume(data.dash_stamina_cost)
	player.dash_cooldown_left = data.dash_cooldown
	_time = 0.0
	_in_air = not player.is_on_floor()
	if _in_air:
		player.air_dash_used = true
	_direction = player.get_move_direction()
	if _direction == Vector3.ZERO:
		_direction = player.get_facing_direction()
	_direction = Vector3(_direction.x, 0.0, _direction.z).normalized()
	player.snap_towards(_direction)
	player.animator.play_dash(data.dash_duration)
	player.camera_rig.punch_fov(8.0, data.dash_duration + 0.15)


func exit() -> void:
	_set_invulnerable(false)
	# Etwas Schwung bleibt nach dem Stoß erhalten.
	player.velocity.x *= 0.4
	player.velocity.z *= 0.4


func physics_update(delta: float) -> void:
	var data := player.character_data
	_time += delta
	var speed := data.dash_distance / data.dash_duration
	player.velocity.x = _direction.x * speed
	player.velocity.z = _direction.z * speed
	if _in_air:
		player.velocity.y = 0.0
	else:
		player.apply_gravity(delta)
	_set_invulnerable(_time >= data.dash_iframe_start and _time <= data.dash_iframe_end)
	if _time >= data.dash_duration:
		return_to_locomotion()


func _set_invulnerable(value: bool) -> void:
	if player.hurtbox.invulnerable != value:
		player.hurtbox.invulnerable = value
		player.animator.set_invulnerable_visual(value)

class_name PlayerDodgeState
extends PlayerState
## Ausweichrolle. Kurz unverwundbar (I-Frames), danach verwundbar bis zum Ende.
## Ohne Richtungseingabe gibt es einen Rückwärtsschritt.

var _direction: Vector3 = Vector3.ZERO
var _time: float = 0.0


func enter(_msg: Dictionary = {}) -> void:
	var data := player.character_data
	player.stamina.consume(data.dodge_stamina_cost)
	_time = 0.0
	_direction = player.get_move_direction().normalized()
	if _direction == Vector3.ZERO:
		_direction = -player.get_facing_direction()
	else:
		player.snap_towards(_direction)
	player.animator.play(&"dodge", data.dodge_duration)


func exit() -> void:
	_set_invulnerable(false)


func physics_update(delta: float) -> void:
	var data := player.character_data
	_time += delta
	player.apply_gravity(delta)

	# Schnell starten, gegen Ende auslaufen lassen.
	var progress := clampf(_time / data.dodge_duration, 0.0, 1.0)
	var speed := data.dodge_speed * (1.0 - progress * progress)
	player.velocity.x = _direction.x * speed
	player.velocity.z = _direction.z * speed

	_set_invulnerable(_time >= data.dodge_iframe_start and _time <= data.dodge_iframe_end)

	if _time >= data.dodge_duration:
		return_to_locomotion()


func _set_invulnerable(value: bool) -> void:
	if player.hurtbox.invulnerable != value:
		player.hurtbox.invulnerable = value
		player.animator.set_invulnerable_visual(value)

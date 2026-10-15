class_name PlayerDodgeState
extends PlayerState
## Ausweichrolle. Kurz unverwundbar (I-Frames), danach verwundbar bis zum Ende.
## Die Rolle geht in die Richtung der gedrückten Taste (WASD, relativ zur Kamera).
## Wird die Richtung kurz nach der Ausweichtaste (Strg) gedrückt, zählt sie trotzdem noch
## (Kulanzzeit). Ganz ohne Richtung gibt es einen Rückwärtsschritt.

## So lange nach Rollbeginn darf man die Richtung noch angeben (Sekunden).
const DIRECTION_GRACE_TIME := 0.15

var _direction: Vector3 = Vector3.ZERO
var _time: float = 0.0
## true, sobald eine Richtung gewählt wurde.
var _direction_chosen: bool = false


func enter(_msg: Dictionary = {}) -> void:
	var data := player.character_data
	player.stamina.consume(data.dodge_stamina_cost)
	_time = 0.0
	_direction_chosen = false
	_direction = -player.get_facing_direction()
	_try_choose_direction()
	player.animator.play(&"dodge", data.dodge_duration)


func exit() -> void:
	_set_invulnerable(false)


func physics_update(delta: float) -> void:
	var data := player.character_data
	_time += delta
	player.apply_gravity(delta)
	if not _direction_chosen and _time <= DIRECTION_GRACE_TIME:
		_try_choose_direction()

	# Schnell starten, gegen Ende auslaufen lassen.
	var progress := clampf(_time / data.dodge_duration, 0.0, 1.0)
	var speed := data.dodge_speed * (1.0 - progress * progress)
	player.velocity.x = _direction.x * speed
	player.velocity.z = _direction.z * speed

	_set_invulnerable(_time >= data.dodge_iframe_start and _time <= data.dodge_iframe_end)

	if _time >= data.dodge_duration:
		return_to_locomotion()


## Übernimmt die gedrückte Richtung, falls es eine gibt.
func _try_choose_direction() -> void:
	var input_direction := player.get_move_direction()
	if input_direction == Vector3.ZERO:
		return
	_direction = input_direction.normalized()
	_direction_chosen = true
	player.snap_towards(_direction)


func _set_invulnerable(value: bool) -> void:
	if player.hurtbox.invulnerable != value:
		player.hurtbox.invulnerable = value
		player.animator.set_invulnerable_visual(value)

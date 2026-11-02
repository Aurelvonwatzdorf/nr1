class_name PlayerMantleState
extends PlayerState
## Aufschwung: an einer Kante hochziehen (hohe Kante) oder im Laufen darüber
## setzen (niedrige Kante). Erst nach oben, dann nach vorn auf die Kante.
## Keine Physik währenddessen; ein Treffer bricht ab (Getroffen-Zustand).

## Anteil der Zeit, in der es nach oben geht (der Rest geht nach vorn).
const UP_SHARE := 0.6

var _start: Vector3 = Vector3.ZERO
var _target: Vector3 = Vector3.ZERO
var _duration: float = 0.45
var _time: float = 0.0


func enter(msg: Dictionary = {}) -> void:
	var data := player.character_data
	_start = player.global_position
	_target = msg.get("target", _start)
	var vault: bool = msg.get("vault", false)
	_duration = data.vault_duration if vault else data.mantle_duration
	_time = 0.0
	player.stamina.consume(data.mantle_stamina_cost)
	player.velocity = Vector3.ZERO
	player.consume_jump_input()
	player.snap_towards(Vector3(_target.x - _start.x, 0.0, _target.z - _start.z))
	player.animator.play_mantle(_duration, vault)
	if not vault:
		player.camera_rig.kick(Vector3.UP, 0.6)


func physics_update(delta: float) -> void:
	_time += delta
	var progress := clampf(_time / _duration, 0.0, 1.0)
	var position := _start
	if progress < UP_SHARE:
		position.y = lerpf(_start.y, _target.y, ease(progress / UP_SHARE, 0.5))
	else:
		var forward := (progress - UP_SHARE) / (1.0 - UP_SHARE)
		position = Vector3(lerpf(_start.x, _target.x, forward), _target.y, lerpf(_start.z, _target.z, forward))
	# Bewegung selbst setzen; move_and_slide() danach soll nichts verschieben.
	player.velocity = (position - player.global_position) / maxf(delta, 0.0001)
	if progress >= 1.0:
		player.global_position = _target
		player.velocity = Vector3.ZERO
		return_to_locomotion()

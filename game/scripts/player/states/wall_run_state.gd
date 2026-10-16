class_name PlayerWallRunState
extends PlayerState
## Wandlauf (Implantat „Haftsehnen“): rennend schräg an eine Wand springen und
## seitlich an ihr entlanglaufen. Kostet laufend Ausdauer, man sinkt langsam ab.
## Leertaste springt schräg von der Wand weg (auch zur Wand gegenüber).
## Ende: Zeit um, Ausdauer leer, Shift losgelassen, Wand zu Ende oder Boden.

## So lange darf die Wand kurz fehlen (Fugen, Kanten), bevor man fällt.
const OFF_WALL_GRACE := 0.1
## Nach dem Wandlauf kurz kein neuer (sonst klebt man sofort wieder).
const REENTRY_COOLDOWN := 0.3

var _normal: Vector3 = Vector3.ZERO
var _tangent: Vector3 = Vector3.ZERO
var _speed: float = 0.0
var _time: float = 0.0
var _off_wall_time: float = 0.0


func enter(msg: Dictionary = {}) -> void:
	_normal = msg.get("normal", Vector3.ZERO)
	var direction: Vector3 = msg.get("direction", player.get_facing_direction())
	_tangent = _along_wall(direction)
	var horizontal := Vector3(player.velocity.x, 0.0, player.velocity.z)
	_speed = maxf(horizontal.length(), player.character_data.sprint_speed * player.get_speed_multiplier())
	_time = 0.0
	_off_wall_time = 0.0
	player.velocity.y = maxf(player.velocity.y, 0.5)
	player.snap_towards(_tangent)
	# Wand links (Normale zeigt nach rechts) = -1, Wand rechts = 1.
	var side := -signf(_normal.dot(player.global_basis.x))
	player.animator.play_wall_run(side)
	player.camera_rig.set_roll(9.0 * side)


func exit() -> void:
	player.animator.play_wall_run(0.0)
	player.camera_rig.set_roll(0.0)
	player.wall_run_cooldown_left = REENTRY_COOLDOWN


func physics_update(delta: float) -> void:
	var data := player.character_data
	_time += delta
	player.stamina.drain(data.wall_run_stamina_per_second * delta)

	if player.is_on_wall():
		_off_wall_time = 0.0
		var normal := player.get_wall_normal()
		normal.y = 0.0
		if normal.length_squared() > 0.01:
			# Gebogene Wände: der neuen Wand folgen, Richtung beibehalten.
			_normal = normal.normalized()
			_tangent = _along_wall(_tangent)
	else:
		_off_wall_time += delta

	if player.is_input_enabled() and Input.is_action_just_pressed(&"jump"):
		_wall_jump()
		return
	var sprinting := player.is_input_enabled() and Input.is_action_pressed(&"sprint")
	if _time >= data.wall_run_max_time or player.stamina.is_empty() or not sprinting \
			or _off_wall_time > OFF_WALL_GRACE or player.is_on_floor():
		return_to_locomotion()
		return

	# An der Wand entlang, leicht hineingedrückt, damit man an ihr bleibt.
	player.velocity.x = _tangent.x * _speed - _normal.x * 2.0
	player.velocity.z = _tangent.z * _speed - _normal.z * 2.0
	player.velocity.y -= player.gravity * data.wall_run_gravity_factor * delta


## Richtung auf die Wand-Ebene legen (waagerecht, Länge 1).
func _along_wall(direction: Vector3) -> Vector3:
	var along := direction - _normal * direction.dot(_normal)
	along.y = 0.0
	if along.length_squared() < 0.0001:
		along = _normal.cross(Vector3.UP)
	return along.normalized()


func _wall_jump() -> void:
	var data := player.character_data
	player.stamina.consume(data.jump_stamina_cost)
	var push := _normal * data.wall_jump_push + _tangent * _speed * 0.6
	player.velocity = Vector3(push.x, data.jump_velocity, push.z)
	player.snap_towards(Vector3(player.velocity.x, 0.0, player.velocity.z))
	player.animator.play(&"jump", 0.35)
	return_to_locomotion()

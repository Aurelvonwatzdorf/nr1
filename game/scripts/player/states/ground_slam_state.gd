class_name PlayerGroundSlamState
extends PlayerState
## Aufschlag (Implantat): in der Luft schwerer Angriff. Die Figur stürzt senkrecht
## herab und schlägt mit einer Druckwelle auf (Schaden + Rückstoß im Umkreis,
## mehr Schaden aus größerer Höhe). Bis `slam_safe_height` kein eigener Fallschaden.

var _start_y: float = 0.0
var _landed: bool = false
var _recovery_left: float = 0.0


func enter(_msg: Dictionary = {}) -> void:
	var data := player.character_data
	player.stamina.consume(data.slam_stamina_cost)
	_start_y = player.global_position.y
	_landed = false
	_recovery_left = data.slam_recovery_time
	player.velocity = Vector3(0.0, -data.slam_fall_speed, 0.0)
	player.animator.play(&"jump", 0.2)
	player.camera_rig.punch_fov(-6.0, 0.4)


func physics_update(delta: float) -> void:
	if _landed:
		player.accelerate_to(Vector3.ZERO, delta)
		_recovery_left -= delta
		if _recovery_left <= 0.0:
			return_to_locomotion()
		return
	if player.is_on_floor():
		_landed = true
		player.velocity = Vector3.ZERO
		player.release_ground_slam(maxf(_start_y - player.global_position.y, 0.0))
		return
	player.velocity = Vector3(0.0, -player.character_data.slam_fall_speed, 0.0)

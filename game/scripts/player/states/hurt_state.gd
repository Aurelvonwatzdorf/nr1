class_name PlayerHurtState
extends PlayerState
## Getroffen: kurz taumeln und vom Treffer weggestoßen werden.
## In dieser Zeit kann man nichts tun, darum lohnt sich Ausweichen und Blocken.

var _time_left: float = 0.0


func enter(_msg: Dictionary = {}) -> void:
	_time_left = player.character_data.hurt_stagger_time
	var hit := player.last_hit
	if hit:
		var push := hit.direction * hit.knockback * 2.0
		player.velocity.x = push.x
		player.velocity.z = push.z
	player.hitbox.deactivate()
	player.animator.play(&"hurt", _time_left)


func physics_update(delta: float) -> void:
	_time_left -= delta
	player.apply_gravity(delta)
	player.accelerate_to(Vector3.ZERO, delta * 0.5)
	if _time_left <= 0.0:
		return_to_locomotion()

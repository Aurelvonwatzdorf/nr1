class_name PlayerDeadState
extends PlayerState
## Tot: fällt um und wartet, bis der RespawnManager die Figur wiederbelebt.


func enter(_msg: Dictionary = {}) -> void:
	player.hitbox.deactivate()
	player.hurtbox.invulnerable = false
	player.animator.play(&"death")


func physics_update(delta: float) -> void:
	player.apply_gravity(delta)
	player.accelerate_to(Vector3.ZERO, delta)

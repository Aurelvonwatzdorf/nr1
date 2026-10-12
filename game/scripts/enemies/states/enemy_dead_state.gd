class_name EnemyDeadState
extends EnemyState
## Tot: fällt um, ist nicht mehr anvisierbar und blockiert keine Wege.
## Bleibt liegen, bis `Enemy.reset_enemy()` ihn wiederbelebt.


func enter(_msg: Dictionary = {}) -> void:
	enemy.velocity = Vector3.ZERO
	enemy.hitbox.deactivate()
	enemy.set_telegraph(false)
	enemy.collision_shape.set_deferred(&"disabled", true)
	enemy.hurtbox.set_deferred(&"monitorable", false)
	enemy.health_label.visible = false
	enemy.play_death()


func physics_update(delta: float) -> void:
	enemy.accelerate_to(Vector3.ZERO, delta)

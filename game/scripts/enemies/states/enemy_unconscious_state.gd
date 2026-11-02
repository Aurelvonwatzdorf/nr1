class_name EnemyUnconsciousState
extends EnemyState
## Bewusstlos (betäubt): liegt am Boden, nimmt nichts wahr, ist nicht anvisierbar,
## aber verwundbar. Wacht nach `WAKE_TIME` auf (misstrauisch) oder beim Rasten
## (`Enemy.reset_enemy()`).

const WAKE_TIME := 300.0

var _time_left: float = 0.0


func enter(_msg: Dictionary = {}) -> void:
	_time_left = WAKE_TIME
	enemy.velocity = Vector3.ZERO
	enemy.hitbox.deactivate()
	enemy.set_telegraph(false)
	enemy.perception.reset()
	enemy.collision_shape.set_deferred(&"disabled", true)
	var tween := enemy.create_tween()
	tween.tween_property(enemy.model, "rotation:x", deg_to_rad(-90.0), 0.5)


func exit() -> void:
	enemy.collision_shape.set_deferred(&"disabled", false)
	enemy.model.rotation.x = 0.0


func physics_update(delta: float) -> void:
	enemy.accelerate_to(Vector3.ZERO, delta)
	_time_left -= delta
	if _time_left <= 0.0:
		enemy.perception.awareness = 0.6
		enemy.perception.last_known_position = enemy.global_position
		enemy.perception.wants_to_investigate = true
		state_machine.transition_to(&"search")

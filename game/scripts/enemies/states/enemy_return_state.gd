class_name EnemyReturnState
extends EnemyState
## Geht zurück zum Startpunkt und heilt sich dabei voll.


func enter(_msg: Dictionary = {}) -> void:
	enemy.health.revive()


func physics_update(delta: float) -> void:
	if enemy.perception.alerted:
		state_machine.transition_to(&"chase")
		return
	if enemy.perception.wants_to_investigate:
		state_machine.transition_to(&"search")
		return
	var offset := enemy.home_transform.origin - enemy.global_position
	offset.y = 0.0
	if offset.length() < 0.5:
		state_machine.transition_to(&"idle")
		return
	enemy.accelerate_to(offset.normalized() * enemy.data.walk_speed, delta)
	enemy.turn_towards(offset, delta)

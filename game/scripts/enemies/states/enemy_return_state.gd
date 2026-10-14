class_name EnemyReturnState
extends EnemyState
## Geht zurück zum Startpunkt und heilt sich dabei voll.


func enter(_msg: Dictionary = {}) -> void:
	enemy.health.revive()


func physics_update(delta: float) -> void:
	var player := enemy.get_player()
	if player and enemy.distance_to_node(player) <= enemy.get_detection_radius():
		state_machine.transition_to(&"chase")
		return
	var offset := enemy.home_transform.origin - enemy.global_position
	offset.y = 0.0
	if offset.length() < 0.5:
		state_machine.transition_to(&"idle")
		return
	enemy.accelerate_to(offset.normalized() * enemy.data.walk_speed, delta)
	enemy.turn_towards(offset, delta)

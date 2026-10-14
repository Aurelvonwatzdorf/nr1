class_name EnemyIdleState
extends EnemyState
## Steht herum, bis die Spielfigur nah genug kommt.


func physics_update(delta: float) -> void:
	enemy.accelerate_to(Vector3.ZERO, delta)
	var player := enemy.get_player()
	if player and enemy.distance_to_node(player) <= enemy.get_detection_radius():
		state_machine.transition_to(&"chase")

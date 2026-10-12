class_name EnemyChaseState
extends EnemyState
## Läuft auf die Spielfigur zu und greift an, sobald sie in Reichweite ist.
## (Ohne Wegfindung: läuft direkt hin. Navigation kommt mit der Open World.)


func physics_update(delta: float) -> void:
	var player := enemy.get_player()
	if player == null or enemy.distance_to_node(player) > enemy.data.lose_radius:
		state_machine.transition_to(&"return")
		return
	var direction := enemy.direction_to_node(player)
	enemy.turn_towards(direction, delta)
	if enemy.distance_to_node(player) <= enemy.data.attack_range:
		enemy.accelerate_to(Vector3.ZERO, delta)
		if enemy.attack_cooldown_left <= 0.0:
			state_machine.transition_to(&"attack")
	else:
		enemy.accelerate_to(direction * enemy.data.chase_speed, delta)

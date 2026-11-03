class_name EnemyChaseState
extends EnemyState
## Läuft auf die Spielfigur zu und greift an, sobald sie in Reichweite ist.
## (Ohne Wegfindung: läuft direkt hin. Navigation kommt mit der Open World.)
## Verliert er sie (zu weit weg oder lange nicht gesehen), sucht er an der
## letzten bekannten Stelle.

## So lange darf die Spielfigur außer Sicht sein, bevor er sie verliert.
const LOSE_SIGHT_TIME := 4.0

var _unseen_time: float = 0.0


func enter(_msg: Dictionary = {}) -> void:
	_unseen_time = 0.0


func physics_update(delta: float) -> void:
	var player := enemy.get_player()
	var perception := enemy.perception
	if not perception.alerted and player:
		# Spur verloren (z. B. geblendet): an der letzten Stelle suchen.
		state_machine.transition_to(&"search")
		return
	_unseen_time = 0.0 if perception.sees_player else _unseen_time + delta
	if player == null or enemy.distance_to_node(player) > enemy.data.lose_radius or _unseen_time > LOSE_SIGHT_TIME:
		perception.alerted = false
		perception.awareness = 0.6
		perception.wants_to_investigate = player != null
		state_machine.transition_to(&"search" if player else &"return")
		return
	var direction := enemy.direction_to_node(player)
	enemy.turn_towards(direction, delta)
	if enemy.distance_to_node(player) <= enemy.data.attack_range:
		enemy.accelerate_to(Vector3.ZERO, delta)
		if enemy.attack_cooldown_left <= 0.0:
			state_machine.transition_to(&"attack")
	else:
		enemy.accelerate_to(direction * enemy.data.chase_speed, delta)

class_name EnemySearchState
extends EnemyState
## Geht zur letzten bekannten Stelle (gehört oder kurz gesehen) und schaut sich
## dort um. Nach `search_time` ohne Fund kehrt er auf seinen Posten zurück.

var _target: Vector3 = Vector3.ZERO
var _look_time: float = 0.0


func enter(_msg: Dictionary = {}) -> void:
	_target = enemy.perception.last_known_position
	enemy.perception.wants_to_investigate = false
	_look_time = 0.0


func physics_update(delta: float) -> void:
	var perception := enemy.perception
	if perception.alerted:
		state_machine.transition_to(&"chase")
		return
	if perception.wants_to_investigate:
		# Neuer Hinweis: dorthin.
		_target = perception.last_known_position
		perception.wants_to_investigate = false
		_look_time = 0.0
	var offset := _target - enemy.global_position
	offset.y = 0.0
	if offset.length() > 1.0 and _look_time == 0.0:
		enemy.accelerate_to(offset.normalized() * enemy.data.walk_speed * 1.2, delta)
		enemy.turn_towards(offset, delta)
		return
	# Angekommen: stehen bleiben und sich umsehen.
	enemy.accelerate_to(Vector3.ZERO, delta)
	_look_time += delta
	enemy.rotation.y += sin(_look_time * 1.5) * delta * 1.6
	if _look_time >= enemy.data.search_time:
		state_machine.transition_to(&"return")

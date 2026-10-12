class_name EnemyStaggerState
extends EnemyState
## Taumeln nach einem Treffer (kurz) oder nach einer Parade (lang).
## Wird mit Rückstoß weggeschoben.

var _time_left: float = 0.0


func enter(msg: Dictionary = {}) -> void:
	_time_left = msg.get("time", 0.4)
	var hit := enemy.last_hit
	if hit and not msg.get("parried", false):
		var push := hit.direction * hit.knockback * 2.0
		enemy.velocity.x = push.x
		enemy.velocity.z = push.z
	enemy.play_lean(25.0 if msg.get("parried", false) else 12.0, _time_left)


func physics_update(delta: float) -> void:
	_time_left -= delta
	enemy.accelerate_to(Vector3.ZERO, delta * 0.5)
	if _time_left <= 0.0:
		state_machine.transition_to(&"chase")

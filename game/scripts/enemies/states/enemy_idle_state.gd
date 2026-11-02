class_name EnemyIdleState
extends EnemyState
## Steht auf seinem Posten. Alarmiert → verfolgen; etwas gehört oder halb
## bemerkt → nachsehen (siehe EnemyPerception).


func physics_update(delta: float) -> void:
	enemy.accelerate_to(Vector3.ZERO, delta)
	if enemy.perception.alerted:
		state_machine.transition_to(&"chase")
	elif enemy.perception.wants_to_investigate:
		state_machine.transition_to(&"search")

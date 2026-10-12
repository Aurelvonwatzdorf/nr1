class_name EnemyState
extends State
## Basis für alle Gegner-Zustände.

var enemy: Enemy


func setup(new_actor: Node, machine: StateMachine) -> void:
	super.setup(new_actor, machine)
	enemy = new_actor as Enemy

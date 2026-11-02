class_name EnemyGrabbedState
extends EnemyState
## Von hinten gepackt (lautloses Erledigen): steht still und zappelt. Wie es
## ausgeht, entscheidet der Takedown-Zustand der Spielfigur.


func enter(_msg: Dictionary = {}) -> void:
	enemy.velocity = Vector3.ZERO
	enemy.hitbox.deactivate()
	enemy.set_telegraph(false)
	enemy.play_lean(-15.0, 0.3)


func physics_update(delta: float) -> void:
	enemy.accelerate_to(Vector3.ZERO, delta)

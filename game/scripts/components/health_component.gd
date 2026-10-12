class_name HealthComponent
extends StatPoolComponent
## Lebenspunkte. Meldet `died` genau einmal, wenn das Leben 0 erreicht.

signal damaged(amount: float)
signal died

var is_dead: bool = false


func take_damage(amount: float) -> void:
	if is_dead or amount <= 0.0:
		return
	remove(amount)
	damaged.emit(amount)
	if is_empty():
		is_dead = true
		died.emit()


func heal(amount: float) -> void:
	if not is_dead:
		add(amount)


## Volles Leben, wieder lebendig (Respawn, Ankerspiegel).
func revive() -> void:
	is_dead = false
	refill()

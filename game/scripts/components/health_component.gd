class_name HealthComponent
extends StatPoolComponent
## Lebenspunkte. Meldet `died` genau einmal, wenn das Leben 0 erreicht.

signal damaged(amount: float)
signal died

var is_dead: bool = false
## Regeneration: nach `regen_delay` Sekunden ohne Schaden gibt es jede Sekunde
## `regen_per_second` Leben. 0 = keine Regeneration (Gegner, NPCs).
var regen_per_second: float = 0.0
var regen_delay: float = 10.0
## Sekunden seit dem letzten Schaden.
var time_since_damage: float = 0.0
var _regen_tick: float = 0.0


func _physics_process(delta: float) -> void:
	if regen_per_second <= 0.0 or is_dead:
		return
	time_since_damage += delta
	if time_since_damage < regen_delay or current >= max_value:
		_regen_tick = 0.0
		return
	_regen_tick += delta
	if _regen_tick >= 1.0:
		_regen_tick -= 1.0
		add(regen_per_second)


func take_damage(amount: float) -> void:
	if is_dead or amount <= 0.0:
		return
	remove(amount)
	time_since_damage = 0.0
	_regen_tick = 0.0
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
	time_since_damage = 0.0
	refill()

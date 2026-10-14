class_name AmbitionComponent
extends StatPoolComponent
## Aurels Ehrgeiz (0 bis 100). Wächst mit jedem eigenen Treffer, sinkt, wenn er
## getroffen wird oder eine Weile nicht angreift. Voller Ehrgeiz = mehr Schaden.

## Ehrgeiz pro eigenem Treffer.
@export var gain_per_hit: float = 12.0
## So lange nach dem letzten Treffer bleibt der Ehrgeiz stabil.
@export var decay_delay: float = 2.5
@export var decay_per_second: float = 15.0
## Verlust, wenn Aurel selbst getroffen wird.
@export var loss_when_hit: float = 25.0
## Schadens-Bonus bei vollem Ehrgeiz (0.2 = +20 %).
@export var max_damage_bonus: float = 0.2

var _time_since_hit: float = 0.0


func _ready() -> void:
	super._ready()
	current = 0.0


func _physics_process(delta: float) -> void:
	_time_since_hit += delta
	if _time_since_hit > decay_delay and current > 0.0:
		remove(decay_per_second * delta)


## Eigener Treffer gelandet.
func on_hit_landed() -> void:
	var gain := gain_per_hit
	if GameState.has_skill(&"aurel_hunger"):
		gain *= 1.5
	add(gain)
	_time_since_hit = 0.0


## Selbst getroffen worden.
func on_got_hit() -> void:
	remove(loss_when_hit)


func is_full() -> bool:
	return current >= max_value - 0.01


func get_damage_bonus() -> float:
	return get_ratio() * max_damage_bonus


func spend_all() -> void:
	remove(current)

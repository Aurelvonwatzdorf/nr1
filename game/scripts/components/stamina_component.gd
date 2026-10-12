class_name StaminaComponent
extends StatPoolComponent
## Ausdauer. Regeneriert sich nach einer kurzen Pause automatisch.
##
## Soulslike-Regel: Eine Aktion ist erlaubt, solange noch etwas Ausdauer da ist.
## Sie darf den Wert auf 0 drücken, aber nicht ins Minus.

## Ausdauer pro Sekunde beim Regenerieren.
@export var regen_per_second: float = 35.0
## Wartezeit nach dem letzten Verbrauch, bevor die Regeneration einsetzt.
@export var regen_delay: float = 0.8

var _delay_left: float = 0.0


func _physics_process(delta: float) -> void:
	if _delay_left > 0.0:
		_delay_left -= delta
	elif current < max_value:
		add(regen_per_second * delta)


func can_act() -> bool:
	return current > 0.0


## Einmaliger Verbrauch (Angriff, Ausweichen).
func consume(amount: float) -> void:
	remove(amount)
	_delay_left = regen_delay


## Dauerverbrauch (Sprinten). `amount` ist schon mit delta multipliziert.
func drain(amount: float) -> void:
	consume(amount)

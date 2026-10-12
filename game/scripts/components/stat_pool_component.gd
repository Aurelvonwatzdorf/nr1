class_name StatPoolComponent
extends Node
## Gemeinsame Basis für Werte mit Maximum (Leben, Ausdauer, Fokus).

## Meldet jede Änderung, z. B. damit das HUD seinen Balken aktualisiert.
signal value_changed(current: float, maximum: float)
## Der Wert ist auf 0 gefallen.
signal depleted

@export var max_value: float = 100.0

var current: float = 0.0


func _ready() -> void:
	current = max_value


## Setzt ein neues Maximum (z. B. aus CharacterData oder nach einem Level-Up).
func set_max_value(value: float, refill: bool = true) -> void:
	max_value = maxf(value, 1.0)
	_set_current(max_value if refill else current)


func add(amount: float) -> void:
	_set_current(current + amount)


func remove(amount: float) -> void:
	_set_current(current - amount)


func refill() -> void:
	_set_current(max_value)


func is_empty() -> bool:
	return current <= 0.0


func get_ratio() -> float:
	return current / max_value


func _set_current(value: float) -> void:
	var old := current
	current = clampf(value, 0.0, max_value)
	if not is_equal_approx(old, current):
		value_changed.emit(current, max_value)
		if current <= 0.0:
			depleted.emit()

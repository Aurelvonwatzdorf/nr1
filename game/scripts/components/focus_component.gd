class_name FocusComponent
extends StatPoolComponent
## Fokus (Mana). Wird ab M5 für den Realitätsblick und Fähigkeiten gebraucht.
## Anders als Ausdauer muss die volle Menge vorhanden sein.

## Standard 0: Fokus füllt sich nicht von selbst (nur an Ankerspiegeln o. Ä.).
@export var regen_per_second: float = 0.0


func _physics_process(delta: float) -> void:
	if regen_per_second > 0.0 and current < max_value:
		add(regen_per_second * delta)


func try_spend(amount: float) -> bool:
	if current < amount:
		return false
	remove(amount)
	return true

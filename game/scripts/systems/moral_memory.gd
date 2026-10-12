class_name MoralMemory
extends Resource
## Moral-Gedächtnis: merkt sich unsichtbar, wie gut oder schlecht man als Mensch
## gehandelt hat. Grundlage für Rafas Prüfung (M9).
##
## Bewertet nach christlichen Werten, aber über Taten, nicht über den Glauben.
## Gute Taten haben positive Werte, schlechte negative (z. B. Grausamkeit =
## negative Barmherzigkeit).

const VIRTUES: Dictionary[StringName, String] = {
	&"charity": "Nächstenliebe",
	&"mercy": "Barmherzigkeit",
	&"honesty": "Ehrlichkeit",
	&"forgiveness": "Vergebung",
	&"humility": "Demut",
	&"protection": "Schwache schützen",
}

## Alle Taten in Reihenfolge: {id, virtue, value, text}.
var deeds: Array[Dictionary] = []


## Merkt sich eine Tat. Jede Tat-ID zählt nur einmal. Gibt false zurück, wenn
## die Tat schon bekannt war.
func record(id: StringName, virtue: StringName, value: int, text: String) -> bool:
	assert(VIRTUES.has(virtue), "Unbekannte Tugend: %s" % virtue)
	if has_deed(id):
		return false
	deeds.append({"id": String(id), "virtue": String(virtue), "value": value, "text": text})
	emit_changed()
	return true


func has_deed(id: StringName) -> bool:
	for deed in deeds:
		if deed["id"] == String(id):
			return true
	return false


## Gesamtwert (positiv = eher gut).
func get_score() -> int:
	var total := 0
	for deed in deeds:
		total += int(deed["value"])
	return total


func get_virtue_score(virtue: StringName) -> int:
	var total := 0
	for deed in deeds:
		if deed["virtue"] == String(virtue):
			total += int(deed["value"])
	return total


func to_array() -> Array:
	return deeds.duplicate(true)


func from_array(data: Array) -> void:
	deeds.clear()
	for entry: Variant in data:
		if entry is Dictionary:
			deeds.append(entry)
	emit_changed()

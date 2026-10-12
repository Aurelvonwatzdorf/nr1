class_name Inventory
extends Resource
## Was die Spielfigur besitzt: Gegenstands-ID → Anzahl.
## Änderungen melden sich über das Resource-Signal `changed`.

var items: Dictionary[StringName, int] = {}


func add(id: StringName, amount: int = 1) -> void:
	items[id] = get_count(id) + amount
	emit_changed()


func remove(id: StringName, amount: int = 1) -> bool:
	if get_count(id) < amount:
		return false
	items[id] -= amount
	if items[id] <= 0:
		items.erase(id)
	emit_changed()
	return true


func get_count(id: StringName) -> int:
	return items.get(id, 0)


func has(id: StringName) -> bool:
	return get_count(id) > 0


## Alle Gegenstände als ItemData (nur die, die man besitzt).
func get_owned_items() -> Array[ItemData]:
	var result: Array[ItemData] = []
	for id: StringName in items:
		var item := ItemDatabase.get_item(id)
		if item:
			result.append(item)
	return result


## Erster Heilgegenstand, den man besitzt (für Taste R), sonst null.
func find_healing_item() -> ItemData:
	if has(&"healing_potion"):
		return ItemDatabase.get_item(&"healing_potion")
	for item in get_owned_items():
		if item.is_consumable() and item.heal_amount > 0.0:
			return item
	return null


## Summe eines Dauer-Bonus über alle permanenten Artefakte.
func get_permanent_bonus(property: StringName) -> float:
	var total := 0.0
	for item in get_owned_items():
		if item.kind == ItemData.Kind.PERMANENT:
			total += float(item.get(property))
	return total


func to_dict() -> Dictionary:
	var data := {}
	for id: StringName in items:
		data[String(id)] = items[id]
	return data


func from_dict(data: Dictionary) -> void:
	items.clear()
	for key: String in data:
		items[StringName(key)] = int(data[key])
	emit_changed()

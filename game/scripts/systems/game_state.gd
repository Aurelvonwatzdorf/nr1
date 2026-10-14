extends Node
## Spielzustand über Szenen hinweg (Autoload „GameState“).
##
## Hier liegt alles, was ein Szenenwechsel nicht löschen darf: gewählte Figur,
## Währung, später Story-Fortschritt und freigeschaltete Fähigkeiten.

## Alle spielbaren Figuren als Daten-Resources (Schlüssel = CharacterData.id).
const CHARACTER_PATHS: Dictionary[StringName, String] = {
	&"aurel": "res://resources/characters/aurel.tres",
	&"tahirou": "res://resources/characters/tahirou.tres",
}

## Gewählte Figur. `null` heißt: Die Spielfigur nimmt die im Inspector eingestellte.
var selected_character: CharacterData = null

## Geld zum Kaufen. Bleibt beim Tod erhalten (anders als Erinnerungen).
var money: int = 0:
	set(value):
		money = maxi(value, 0)
		EventBus.money_changed.emit(money)

## Wie viele Menüs gerade offen sind. > 0 = Spiel pausiert, Maus frei.
var open_menu_count: int = 0:
	set(value):
		var was_open := open_menu_count > 0
		open_menu_count = maxi(value, 0)
		var is_open := open_menu_count > 0
		if was_open != is_open:
			get_tree().paused = is_open
			EventBus.menu_state_changed.emit(is_open)

## Stats der Spielfigur (Stärke, Schnelligkeit …).
var stats: PlayerStats = PlayerStats.new()

## Inventar (Tränke, Artefakte).
var inventory: Inventory = Inventory.new()
## IDs bereits aufgehobener Gegenstände in der Welt.
var collected_pickups: Array[StringName] = []

## Moral-Gedächtnis (unsichtbar für den Spieler).
var moral: MoralMemory = MoralMemory.new()

## Wo die Spielfigur nach dem Tod wiederbelebt wird.
var checkpoint_transform: Transform3D = Transform3D.IDENTITY
var has_checkpoint: bool = false

## Währung „Erinnerungen“.
var memories: int = 0:
	set(value):
		memories = maxi(value, 0)
		EventBus.memories_changed.emit(memories)


## Wählt eine Figur anhand ihrer ID (wird ab M4 vom Auswahlbildschirm genutzt).
func select_character(id: StringName) -> bool:
	if not CHARACTER_PATHS.has(id):
		push_warning("Unbekannte Figur: %s" % id)
		return false
	selected_character = load(CHARACTER_PATHS[id]) as CharacterData
	return selected_character != null


## Gibt Erinnerungen aus, um einen Stat zu erhöhen. Gibt false zurück, wenn
## es nicht geht (zu wenig Erinnerungen oder Stat nicht so levelbar).
func try_level_up(stat: StringName) -> bool:
	if not stat in PlayerStats.LEVELABLE:
		return false
	var cost := stats.get_level_up_cost()
	if memories < cost:
		return false
	memories -= cost
	stats.increase(stat)
	return true


func is_menu_open() -> bool:
	return open_menu_count > 0


## Bezahlen. Gibt false zurück, wenn das Geld nicht reicht.
func try_spend_money(amount: int) -> bool:
	if money < amount:
		return false
	money -= amount
	return true


func set_checkpoint(at: Transform3D) -> void:
	checkpoint_transform = at
	has_checkpoint = true


## Alles zurück auf Anfang (neues Spiel).
func reset() -> void:
	selected_character = null
	memories = 0
	money = 0
	stats.from_dict({})
	inventory.from_dict({})
	moral.from_array([])
	collected_pickups.clear()
	checkpoint_transform = Transform3D.IDENTITY
	has_checkpoint = false


## Speicherbare Daten als Dictionary (wird von SaveSystem genutzt).
func to_dict() -> Dictionary:
	return {
		"character_id": String(selected_character.id) if selected_character else "",
		"memories": memories,
		"money": money,
		"stats": stats.to_dict(),
		"inventory": inventory.to_dict(),
		"collected_pickups": collected_pickups.map(func(id: StringName) -> String: return String(id)),
		"has_checkpoint": has_checkpoint,
		"checkpoint": var_to_str(checkpoint_transform),
		"moral": moral.to_array(),
	}


func from_dict(data: Dictionary) -> void:
	reset()
	var character_id := StringName(str(data.get("character_id", "")))
	if character_id != &"":
		select_character(character_id)
	memories = int(data.get("memories", 0))
	money = int(data.get("money", 0))
	stats.from_dict(data.get("stats", {}))
	inventory.from_dict(data.get("inventory", {}))
	for id: Variant in data.get("collected_pickups", []):
		collected_pickups.append(StringName(str(id)))
	has_checkpoint = bool(data.get("has_checkpoint", false))
	var transform: Variant = str_to_var(str(data.get("checkpoint", "")))
	if transform is Transform3D:
		checkpoint_transform = transform
	moral.from_array(data.get("moral", []))

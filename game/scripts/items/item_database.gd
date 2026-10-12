class_name ItemDatabase
## Alle Gegenstände des Spiels, nach ID. Neue Gegenstände hier eintragen.

const PATHS: Dictionary[StringName, String] = {
	&"healing_potion": "res://resources/items/healing_potion.tres",
	&"focus_potion": "res://resources/items/focus_potion.tres",
	&"power_ampoule": "res://resources/items/power_ampoule.tres",
	&"stamina_talisman": "res://resources/items/stamina_talisman.tres",
	&"heart_amulet": "res://resources/items/heart_amulet.tres",
}

static var _cache: Dictionary[StringName, ItemData] = {}


static func get_item(id: StringName) -> ItemData:
	if not _cache.has(id):
		if not PATHS.has(id):
			push_warning("Unbekannter Gegenstand: %s" % id)
			return null
		_cache[id] = load(PATHS[id]) as ItemData
	return _cache[id]

class_name ItemDatabase
## Alle Gegenstände des Spiels, nach ID. Neue Gegenstände hier eintragen.

const PATHS: Dictionary[StringName, String] = {
	&"healing_potion": "res://resources/items/healing_potion.tres",
	&"focus_potion": "res://resources/items/focus_potion.tres",
	&"power_ampoule": "res://resources/items/power_ampoule.tres",
	&"stamina_talisman": "res://resources/items/stamina_talisman.tres",
	&"heart_amulet": "res://resources/items/heart_amulet.tres",
	&"short_sword": "res://resources/items/short_sword.tres",
	&"battle_staff": "res://resources/items/battle_staff.tres",
	&"vibro_blade": "res://resources/items/vibro_blade.tres",
	&"pistol": "res://resources/items/pistol.tres",
	&"pistol_ammo": "res://resources/items/pistol_ammo.tres",
	&"radar_system": "res://resources/items/radar_system.tres",
	&"leg_servos": "res://resources/items/leg_servos.tres",
	&"dermal_plating": "res://resources/items/dermal_plating.tres",
	&"neuro_booster": "res://resources/items/neuro_booster.tres",
	&"heart_pump": "res://resources/items/heart_pump.tres",
	&"cyber_legs": "res://resources/items/cyber_legs.tres",
}

static var _cache: Dictionary[StringName, ItemData] = {}


static func get_item(id: StringName) -> ItemData:
	if not _cache.has(id):
		if not PATHS.has(id):
			push_warning("Unbekannter Gegenstand: %s" % id)
			return null
		_cache[id] = load(PATHS[id]) as ItemData
	return _cache[id]

class_name MissionDatabase
## Alle Missionen des Spiels, nach ID. Neue Missionen hier eintragen.

const PATHS: Dictionary[StringName, String] = {
	&"help_old_woman": "res://resources/missions/help_old_woman.tres",
	&"heal_sick_man": "res://resources/missions/heal_sick_man.tres",
}

static var _cache: Dictionary[StringName, MissionData] = {}


static func get_mission(id: StringName) -> MissionData:
	if not _cache.has(id):
		if not PATHS.has(id):
			push_warning("Unbekannte Mission: %s" % id)
			return null
		_cache[id] = load(PATHS[id]) as MissionData
	return _cache[id]

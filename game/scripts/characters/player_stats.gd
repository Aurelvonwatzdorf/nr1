class_name PlayerStats
extends Resource
## Die Stats (Attribute) der Spielfigur und was aus ihnen folgt.
##
## Alle Werte starten bei 1. Körperwerte und Fokus levelt man mit Erinnerungen
## am Ankerspiegel. Spiritualität nur durch Beten und bestimmte Missionen (ab M8).
## Änderungen melden sich über das Resource-Signal `changed`.

## Stats, die man mit Erinnerungen leveln kann (in Menü-Reihenfolge).
const LEVELABLE: Array[StringName] = [&"strength", &"agility", &"endurance", &"resistance", &"focus"]
const ALL: Array[StringName] = [&"strength", &"agility", &"endurance", &"resistance", &"focus", &"spirituality"]

const DISPLAY_NAMES: Dictionary[StringName, String] = {
	&"strength": "Stärke",
	&"agility": "Schnelligkeit",
	&"endurance": "Ausdauer",
	&"resistance": "Widerstand",
	&"focus": "Fokus",
	&"spirituality": "Spiritualität",
}
const DESCRIPTIONS: Dictionary[StringName, String] = {
	&"strength": "+5 % Schaden",
	&"agility": "+2 % Lauftempo",
	&"endurance": "+6 Ausdauer, schnellere Erholung",
	&"resistance": "+8 Leben",
	&"focus": "+5 Fokus",
	&"spirituality": "Hält spirituellem Druck stand (nur durch Beten)",
}

@export var strength: int = 1
@export var agility: int = 1
@export var endurance: int = 1
@export var resistance: int = 1
@export var focus: int = 1
@export var spirituality: int = 1


func get_stat(stat: StringName) -> int:
	return int(get(stat))


func set_stat(stat: StringName, value: int) -> void:
	assert(stat in ALL, "Unbekannter Stat: %s" % stat)
	set(stat, maxi(value, 1))
	emit_changed()


func increase(stat: StringName, amount: int = 1) -> void:
	set_stat(stat, get_stat(stat) + amount)


## Gesamtstufe der Figur (beginnt bei 1). Spiritualität zählt nicht mit, damit
## Beten das Leveln mit Erinnerungen nicht teurer macht.
func get_level() -> int:
	var total := 0
	for stat in LEVELABLE:
		total += get_stat(stat)
	return total - LEVELABLE.size() + 1


## Erinnerungen, die die nächste Stufe kostet. Jede Stufe wird teurer.
func get_level_up_cost() -> int:
	return roundi(100.0 * pow(1.12, get_level() - 1))


# --- Abgeleitete Werte (Grundwerte kommen aus CharacterData) ---

func get_max_health(base: float) -> float:
	return base + (resistance - 1) * 8.0


func get_max_stamina(base: float) -> float:
	return base + (endurance - 1) * 6.0


func get_stamina_regen(base: float) -> float:
	return base + (endurance - 1) * 1.0


func get_max_focus(base: float) -> float:
	return base + (focus - 1) * 5.0


func get_damage_multiplier() -> float:
	return 1.0 + (strength - 1) * 0.05


func get_speed_multiplier() -> float:
	return minf(1.0 + (agility - 1) * 0.02, 1.4)


func to_dict() -> Dictionary:
	var data := {}
	for stat in ALL:
		data[String(stat)] = get_stat(stat)
	return data


func from_dict(data: Dictionary) -> void:
	for stat in ALL:
		set(stat, maxi(int(data.get(String(stat), 1)), 1))
	emit_changed()

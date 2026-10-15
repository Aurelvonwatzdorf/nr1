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

## Testversion: Beim Start wird das Geld mindestens auf diesen Betrag
## aufgefüllt, damit man alles kaufen und ausprobieren kann. 0 = aus.
## Für die fertige Version auf 0 setzen. (In den Tests aus.)
var test_start_money: int = 5000

## Bei neuem Spiel die Charakterauswahl zeigen? (Im Rauchtest aus.)
var ask_character_on_new_game: bool = true

## Gewählte Figur. `null` heißt: Die Spielfigur nimmt die im Inspector eingestellte.
var selected_character: CharacterData = null

## Geld zum Kaufen. Bleibt beim Tod erhalten (anders als Erinnerungen).
var money: int = 0:
	set(value):
		money = maxi(value, 0)
		EventBus.money_changed.emit(money)

enum SkillStatus { UNLOCKED, AVAILABLE, NEEDS_POINTS, NEEDS_PREVIOUS, STORY_LOCKED }

## Fähigkeitspunkte (1 pro Level-Up).
var skill_points: int = 0
## Freigeschaltete Fähigkeiten (IDs).
var unlocked_skills: Array[StringName] = []
## Erreichter Story-Fortschritt (z. B. &"first_boss_defeated").
var story_flags: Array[StringName] = []

enum MissionStatus { NOT_STARTED, ACTIVE, COMPLETED, FAILED }

## IDs getöteter NPCs (bleiben auch nach dem Laden tot).
var dead_npcs: Array[StringName] = []

## Stand aller Missionen: ID → MissionStatus.
var mission_states: Dictionary[StringName, int] = {}

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
## Ist gerade der Realitätsblick an? (Setzt die Spielfigur.)
var reality_sight_active: bool = false
## Zu tief verankert: Der Realitätsblick geht nicht (bis zum nächsten Rasten).
var reality_sight_blocked: bool = false
## Level (Szenenpfad), in dem man zuletzt war; wird gespeichert, damit man nach
## dem Laden in der richtigen Welt (Stadt oder Spiegelrealität) weiterspielt.
var current_scene: String = ""
## Fahndung (0–100): steigt, wenn man Konzernkräfte angreift. Nicht gespeichert.
var wanted_level: float = 0.0
## Gerade von Spiegeljägern gefangen (bis man ausbricht).
var is_captured: bool = false
## Wo man nach dem Ausbruch aus einer Gefangenen-Realität aufwacht.
var return_scene: String = ""
var return_transform: Transform3D = Transform3D.IDENTITY
## Bezirk (CityDistrict.id), in dem man gefangen wurde, und die frei gehaltenen
## Stellen der Stadt (damit die Spiegelrealität genau dieselben Häuser hat).
var capture_district: StringName = &""
var capture_clear_circles: Array[Vector3] = []

## Startpunkt im nächsten Level (z. B. nach dem Ausbruch). Nicht gespeichert.
var has_pending_spawn: bool = false
var pending_spawn: Transform3D = Transform3D.IDENTITY
## Meldung für das nächste Level (z. B. nach dem Aufwachen). Nicht gespeichert.
var pending_message: String = ""
## Szene, zu der der Checkpoint gehört.
var checkpoint_scene: String = ""

## Wegpunkt auf der Karte (wie ein Navi). Wird nicht gespeichert.
var has_map_waypoint: bool = false
var map_waypoint: Vector2 = Vector2.ZERO

## Ausgerüstete Waffen (Item-IDs, leer = keine).
var equipped_weapon: StringName = &""
var equipped_firearm: StringName = &""
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
	skill_points += 1
	stats.increase(stat)
	return true


func has_skill(id: StringName) -> bool:
	return unlocked_skills.has(id)


func has_story_flag(flag: StringName) -> bool:
	return story_flags.has(flag)


## Story-Fortschritt erreicht (schaltet Story-gebundene Fähigkeiten frei).
func set_story_flag(flag: StringName) -> void:
	if not story_flags.has(flag):
		story_flags.append(flag)
		EventBus.story_flag_set.emit(flag)


func get_skill_status(skill: SkillData) -> SkillStatus:
	if has_skill(skill.id):
		return SkillStatus.UNLOCKED
	if skill.story_flag != &"" and not has_story_flag(skill.story_flag):
		return SkillStatus.STORY_LOCKED
	for required in skill.requires:
		if not has_skill(required):
			return SkillStatus.NEEDS_PREVIOUS
	if skill_points < skill.cost:
		return SkillStatus.NEEDS_POINTS
	return SkillStatus.AVAILABLE


func try_unlock_skill(skill: SkillData) -> bool:
	if get_skill_status(skill) != SkillStatus.AVAILABLE:
		return false
	skill_points -= skill.cost
	unlocked_skills.append(skill.id)
	EventBus.skill_unlocked.emit(skill)
	return true


func is_menu_open() -> bool:
	return open_menu_count > 0


func get_mission_status(id: StringName) -> MissionStatus:
	return mission_states.get(id, MissionStatus.NOT_STARTED) as MissionStatus


## Mission annehmen (wenn noch nicht begonnen).
func start_mission(mission: MissionData) -> void:
	if get_mission_status(mission.id) != MissionStatus.NOT_STARTED:
		return
	mission_states[mission.id] = MissionStatus.ACTIVE
	EventBus.mission_started.emit(mission)


## Mission abschließen: Belohnung geben, Tat ins Moral-Gedächtnis.
func complete_mission(mission: MissionData) -> void:
	if get_mission_status(mission.id) == MissionStatus.COMPLETED:
		return
	mission_states[mission.id] = MissionStatus.COMPLETED
	money += mission.reward_money
	memories += mission.reward_memories
	if mission.moral_virtue != &"":
		moral.record(StringName("mission_%s" % mission.id), mission.moral_virtue, mission.moral_value, mission.moral_text)
	EventBus.mission_completed.emit(mission)


## Mission scheitern lassen (z. B. weil die Person tot ist).
func fail_mission(mission: MissionData) -> void:
	if get_mission_status(mission.id) == MissionStatus.COMPLETED:
		return
	mission_states[mission.id] = MissionStatus.FAILED
	EventBus.mission_failed.emit(mission)


## Alle angenommenen, noch offenen Missionen.
func get_active_missions() -> Array[MissionData]:
	var result: Array[MissionData] = []
	for id: StringName in mission_states:
		if mission_states[id] == MissionStatus.ACTIVE:
			var mission := MissionDatabase.get_mission(id)
			if mission:
				result.append(mission)
	return result


## Bezahlen. Gibt false zurück, wenn das Geld nicht reicht.
func try_spend_money(amount: int) -> bool:
	if money < amount:
		return false
	money -= amount
	return true


func set_checkpoint(at: Transform3D) -> void:
	checkpoint_transform = at
	has_checkpoint = true
	checkpoint_scene = current_scene


## Checkpoint vergessen (z. B. beim Wechsel in eine andere Welt).
func clear_checkpoint() -> void:
	has_checkpoint = false
	checkpoint_scene = ""


## Wegpunkt setzen (x, z in Weltkoordinaten).
func set_map_waypoint(at: Vector2) -> void:
	map_waypoint = at
	has_map_waypoint = true
	EventBus.map_waypoint_changed.emit()


func clear_map_waypoint() -> void:
	has_map_waypoint = false
	EventBus.map_waypoint_changed.emit()


## Waffe ausrüsten (oder ablegen, wenn sie schon ausgerüstet ist).
func toggle_equip(item: ItemData) -> void:
	if item.kind == ItemData.Kind.WEAPON:
		equipped_weapon = &"" if equipped_weapon == item.id else item.id
	elif item.kind == ItemData.Kind.FIREARM:
		equipped_firearm = &"" if equipped_firearm == item.id else item.id
	EventBus.equipment_changed.emit()


func is_equipped(item: ItemData) -> bool:
	return item.id == equipped_weapon or item.id == equipped_firearm


## Alles zurück auf Anfang (neues Spiel).
func reset() -> void:
	selected_character = null
	memories = 0
	money = 0
	stats.from_dict({})
	inventory.from_dict({})
	equipped_weapon = &""
	equipped_firearm = &""
	has_map_waypoint = false
	reality_sight_blocked = false
	wanted_level = 0.0
	is_captured = false
	return_scene = ""
	current_scene = ""
	checkpoint_scene = ""
	moral.from_array([])
	collected_pickups.clear()
	mission_states.clear()
	dead_npcs.clear()
	skill_points = 0
	unlocked_skills.clear()
	story_flags.clear()
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
		"current_scene": current_scene,
		"return_scene": return_scene,
		"return_transform": var_to_str(return_transform),
		"capture_district": String(capture_district),
		"capture_clear_circles": var_to_str(capture_clear_circles),
		"checkpoint_scene": checkpoint_scene,
		"equipped_weapon": String(equipped_weapon),
		"equipped_firearm": String(equipped_firearm),
		"collected_pickups": collected_pickups.map(func(id: StringName) -> String: return String(id)),
		"has_checkpoint": has_checkpoint,
		"checkpoint": var_to_str(checkpoint_transform),
		"moral": moral.to_array(),
		"missions": _missions_to_dict(),
		"skill_points": skill_points,
		"skills": unlocked_skills.map(func(id: StringName) -> String: return String(id)),
		"story_flags": story_flags.map(func(id: StringName) -> String: return String(id)),
		"dead_npcs": dead_npcs.map(func(id: StringName) -> String: return String(id)),
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
	current_scene = str(data.get("current_scene", ""))
	return_scene = str(data.get("return_scene", ""))
	var saved_return: Variant = str_to_var(str(data.get("return_transform", "")))
	if saved_return is Transform3D:
		return_transform = saved_return
	capture_district = StringName(str(data.get("capture_district", "")))
	var saved_circles: Variant = str_to_var(str(data.get("capture_clear_circles", "")))
	capture_clear_circles.clear()
	if saved_circles is Array:
		for circle: Variant in saved_circles:
			if circle is Vector3:
				capture_clear_circles.append(circle)
	checkpoint_scene = str(data.get("checkpoint_scene", ""))
	equipped_weapon = StringName(str(data.get("equipped_weapon", "")))
	equipped_firearm = StringName(str(data.get("equipped_firearm", "")))
	for id: Variant in data.get("collected_pickups", []):
		collected_pickups.append(StringName(str(id)))
	has_checkpoint = bool(data.get("has_checkpoint", false))
	var transform: Variant = str_to_var(str(data.get("checkpoint", "")))
	if transform is Transform3D:
		checkpoint_transform = transform
	moral.from_array(data.get("moral", []))
	skill_points = int(data.get("skill_points", 0))
	for id: Variant in data.get("skills", []):
		unlocked_skills.append(StringName(str(id)))
	for id: Variant in data.get("story_flags", []):
		story_flags.append(StringName(str(id)))
	for id: Variant in data.get("dead_npcs", []):
		dead_npcs.append(StringName(str(id)))
	var missions: Dictionary = data.get("missions", {})
	for key: String in missions:
		mission_states[StringName(key)] = int(missions[key])


func _missions_to_dict() -> Dictionary:
	var result := {}
	for id: StringName in mission_states:
		result[String(id)] = mission_states[id]
	return result

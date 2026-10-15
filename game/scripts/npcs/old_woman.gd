class_name OldWoman
extends NPC
## Alte Frau, die über die Straße will. Hilft man ihr, folgt sie der Spielfigur,
## bis sie im Zielbereich auf der anderen Seite ankommt. Danach geht sie in ihr
## Haus (falls `home_door` gesetzt ist) und bleibt dort.

enum Mode { WAITING, FOLLOWING, ARRIVED, GOING_HOME, HOME }

@export var mission: MissionData
## Bereich auf der anderen Straßenseite (Area3D, erkennt NPCs).
@export var destination: Area3D
## Tür ihres Hauses (Marker vor der Tür). Leer = sie bleibt am Ziel stehen.
@export var home_door: Node3D
## So nah läuft sie an die Spielfigur heran.
@export var follow_distance: float = 1.8

var mode: Mode = Mode.WAITING
var _player: Player


func _ready() -> void:
	super._ready()
	if is_queued_for_deletion():
		return
	destination.body_entered.connect(_on_destination_body_entered)
	match GameState.get_mission_status(mission.id):
		GameState.MissionStatus.COMPLETED:
			if home_door:
				_enter_home()
			else:
				mode = Mode.ARRIVED
				global_position = destination.global_position
		GameState.MissionStatus.ACTIVE:
			mode = Mode.FOLLOWING


func talk(player: Player, dialogue: DialogueBox) -> void:
	match mode:
		Mode.WAITING:
			var choice := await dialogue.ask(display_name,
				"Entschuldigung … könntest du mir über die Straße helfen? Allein traue ich mich nicht.",
				["Natürlich, ich helfe dir.", "Keine Zeit."])
			if choice == 0:
				_player = player
				mode = Mode.FOLLOWING
				GameState.start_mission(mission)
				await dialogue.ask(display_name, "Danke! Geh voraus, ich folge dir.")
			else:
				await dialogue.ask(display_name, "Ach so … schon gut.")
		Mode.FOLLOWING:
			_player = player
			await dialogue.ask(display_name, "Ich bin direkt hinter dir.")
		Mode.ARRIVED, Mode.GOING_HOME:
			await dialogue.ask(display_name, "Danke dir vielmals. Solche Menschen gibt es nicht mehr oft.")
		_:
			pass


func _npc_physics(delta: float) -> void:
	if mode == Mode.GOING_HOME:
		var to_door := home_door.global_position - global_position
		to_door.y = 0.0
		if to_door.length() < 0.8:
			_enter_home()
		else:
			walk_towards(home_door.global_position, walk_speed * 0.8, delta)
		return
	if mode == Mode.HOME:
		return
	if mode == Mode.FOLLOWING:
		if _player == null:
			_player = get_tree().get_first_node_in_group(&"player") as Player
		if _player and global_position.distance_to(_player.global_position) > follow_distance:
			walk_towards(_player.global_position, walk_speed, delta)
			return
	super._npc_physics(delta)


## Sie läuft nicht frei herum: Sie wartet an der Straße und geht danach nach Hause.
func _can_roam() -> bool:
	return false


func is_home() -> bool:
	return mode == Mode.HOME


## Geht durch die Tür ins Haus: unsichtbar, nicht mehr ansprechbar.
func _enter_home() -> void:
	mode = Mode.HOME
	velocity = Vector3.ZERO
	if home_door:
		global_position = home_door.global_position
	visible = false
	collision_layer = 0
	collision_mask = 0
	set_physics_process(false)
	talk_area.set_deferred(&"monitorable", false)
	hurtbox.set_deferred(&"monitorable", false)


func _on_destination_body_entered(body: Node3D) -> void:
	if body == self and mode == Mode.FOLLOWING:
		mode = Mode.GOING_HOME if home_door else Mode.ARRIVED
		GameState.complete_mission(mission)


func _on_death() -> void:
	GameState.fail_mission(mission)

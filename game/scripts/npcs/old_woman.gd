class_name OldWoman
extends NPC
## Alte Frau, die über die Straße will. Hilft man ihr, folgt sie der Spielfigur,
## bis sie im Zielbereich auf der anderen Seite ankommt.

enum Mode { WAITING, FOLLOWING, ARRIVED }

@export var mission: MissionData
## Bereich auf der anderen Straßenseite (Area3D, erkennt NPCs).
@export var destination: Area3D
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
			mode = Mode.ARRIVED
			global_position = destination.global_position
			home_position = global_position
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
		Mode.ARRIVED:
			await dialogue.ask(display_name, "Danke dir vielmals. Solche Menschen gibt es nicht mehr oft.")


func _npc_physics(delta: float) -> void:
	if mode == Mode.FOLLOWING:
		if _player == null:
			_player = get_tree().get_first_node_in_group(&"player") as Player
		if _player and global_position.distance_to(_player.global_position) > follow_distance:
			walk_towards(_player.global_position, walk_speed, delta)
			return
	super._npc_physics(delta)


## Wartet sie auf Hilfe, bleibt sie an der Straße. Danach geht sie ihrer Wege.
func _can_roam() -> bool:
	return mode == Mode.ARRIVED


func _on_destination_body_entered(body: Node3D) -> void:
	if body == self and mode == Mode.FOLLOWING:
		mode = Mode.ARRIVED
		home_position = global_position
		GameState.complete_mission(mission)


func _on_death() -> void:
	GameState.fail_mission(mission)

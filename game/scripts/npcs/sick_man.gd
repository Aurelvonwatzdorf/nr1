class_name SickMan
extends NPC
## Kranker Mann, der um Hilfe bittet. Ein Heiltrank hilft ihm.

@export var mission: MissionData


func _ready() -> void:
	super._ready()
	if is_queued_for_deletion():
		return
	_update_pose()


func talk(_player: Player, dialogue: DialogueBox) -> void:
	if GameState.get_mission_status(mission.id) == GameState.MissionStatus.COMPLETED:
		await dialogue.ask(display_name, "Danke, Fremder. Das werde ich dir nie vergessen.")
		return
	var has_potion := GameState.inventory.has(&"healing_potion")
	var options: Array[String] = []
	if has_potion:
		options.append("Ihm einen Heiltrank geben")
	options.append("Ich habe nichts dabei. Ich komme wieder.")
	options.append("Weitergehen")
	var choice := await dialogue.ask(display_name, "*hustet* Bitte … hast du irgendetwas, das mir hilft?", options)
	var picked := options[choice]
	if picked == "Ihm einen Heiltrank geben":
		GameState.inventory.remove(&"healing_potion")
		GameState.complete_mission(mission)
		_update_pose()
		await dialogue.ask(display_name, "Oh … es geht mir schon besser. Danke!")
	elif picked == "Ich habe nichts dabei. Ich komme wieder.":
		GameState.start_mission(mission)
		await dialogue.ask(display_name, "Ich warte hier … ich kann ohnehin nirgendwohin.")


## Krank: sitzt zusammengesunken. Geheilt: steht aufrecht.
func _update_pose() -> void:
	var healed := GameState.get_mission_status(mission.id) == GameState.MissionStatus.COMPLETED
	model.rotation.x = 0.0 if healed else deg_to_rad(-25.0)
	model.position.y = 0.0 if healed else -0.3


func _on_death() -> void:
	GameState.fail_mission(mission)

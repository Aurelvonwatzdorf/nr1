class_name RealityRift
extends Interactable
## Der Realitätsriss: erscheint, wenn genug Hinweise gefunden sind. Wer
## hindurchgeht, bricht die Illusion.


func _ready() -> void:
	super._ready()
	prompt = "Die Illusion brechen"
	EventBus.reality_rift_opened.connect(_update)
	_update()


func can_interact(_player: Player) -> bool:
	return _is_open()


func interact(player: Player) -> void:
	var reality := get_tree().get_first_node_in_group(&"reality") as RealityLevel
	if reality and reality.is_rift_open():
		reality.break_reality()
	super.interact(player)


func _is_open() -> bool:
	var reality := get_tree().get_first_node_in_group(&"reality") as RealityLevel
	return reality != null and reality.is_rift_open()


func _update() -> void:
	var open := _is_open()
	visible = open
	set_deferred(&"monitorable", open)
	if open:
		var tween := create_tween().set_loops()
		tween.tween_property(self, "scale", Vector3(1.05, 1.0, 1.05), 0.8)
		tween.tween_property(self, "scale", Vector3.ONE, 0.8)

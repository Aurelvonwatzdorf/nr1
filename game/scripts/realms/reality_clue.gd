class_name RealityClue
extends Interactable
## Ein Hinweis in einer Spiegelrealität (ein Riss, ein Fehler in der Welt).
## Nur mit Realitätsblick (Q) zu sehen und zu untersuchen.

## Was der Begleiter beim Untersuchen sagt.
@export_multiline var companion_line: String = ""

var found: bool = false


func _ready() -> void:
	super._ready()
	prompt = "Riss untersuchen"
	EventBus.reality_sight_changed.connect(func(_active: bool) -> void: _update())
	_update()


func can_interact(_player: Player) -> bool:
	return not found and GameState.reality_sight_active


func interact(player: Player) -> void:
	if found:
		return
	found = true
	var reality := get_tree().get_first_node_in_group(&"reality") as RealityLevel
	if reality:
		reality.add_clue(companion_line)
	_update()
	super.interact(player)


func _update() -> void:
	var present := GameState.reality_sight_active and not found
	visible = present
	set_deferred(&"monitorable", present)

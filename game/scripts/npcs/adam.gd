class_name Adam
extends NPC
## Adam: bewegt sich mühelos durch Spiegelrealitäten. Erscheint im Konzernturm,
## sobald sich der Realitätsriss öffnet. Nie ganz durchschaubar.

var has_appeared: bool = false


func _ready() -> void:
	super._ready()
	if is_queued_for_deletion():
		return
	_set_present(false)
	EventBus.reality_rift_opened.connect(appear)


## Taucht auf, als wäre er schon immer da gewesen.
func appear() -> void:
	if has_appeared:
		return
	has_appeared = true
	_set_present(true)
	model.scale = Vector3(0.01, 0.01, 0.01)
	create_tween().tween_property(model, "scale", Vector3.ONE, 0.6).set_trans(Tween.TRANS_BACK)
	EventBus.message_requested.emit("Jemand steht neben dem Riss.")


func talk(_player: Player, dialogue: DialogueBox) -> void:
	var tahirou := GameState.selected_character != null and GameState.selected_character.id == &"tahirou"
	var greeting := "Na, Twin? Du bist weit weg von deinen Raben." if tahirou \
		else "Aurel. Pünktlich wie jeden Tag. Seit … wie vielen Jahren eigentlich?"
	var choice := await dialogue.ask("Fremder in Galabiya", greeting + "\n\nIch bin Adam. Keine Angst, ich gehöre nicht zu denen.",
		["Wer bist du wirklich?", "Was ist das hier?", "Wie komme ich raus?"])
	match choice:
		0:
			await dialogue.ask("Adam", "Jemand, der Türen findet, wo andere Wände sehen. Mehr musst du heute nicht wissen.")
		1:
			await dialogue.ask("Adam", "Ein Gefängnis, das sich wie ein Arbeitstag anfühlt. Die Konzerne sperren Menschen in solche Welten. Die meisten merken es nie.")
	await dialogue.ask("Adam", "Der Riss dort. Geh hindurch, dann bricht dieser Turm. Wir sehen uns draußen. Vielleicht.")
	GameState.set_story_flag(&"met_adam")


func _set_present(present: bool) -> void:
	visible = present
	collision_layer = PhysicsLayers.NPC if present else 0
	talk_area.set_deferred(&"monitorable", present)
	hurtbox.set_deferred(&"monitorable", present)

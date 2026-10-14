class_name SkillTreeMenu
extends GameMenu
## Fähigkeitenbaum (Taste K): Äste nebeneinander, Fähigkeiten mit Punkten freischalten.

@onready var title_label: Label = %TitleLabel
@onready var points_label: Label = %PointsLabel
@onready var branches_box: HBoxContainer = %Branches
@onready var close_button: Button = %CloseButton


func _ready() -> void:
	super._ready()
	close_button.pressed.connect(close)


func _unhandled_input(event: InputEvent) -> void:
	if is_open and (event.is_action_pressed(&"menu") or event.is_action_pressed(&"skills")):
		close()
		get_viewport().set_input_as_handled()
	elif not is_open and event.is_action_pressed(&"skills") and not GameState.is_menu_open():
		open()
		get_viewport().set_input_as_handled()


func _on_opened() -> void:
	_refresh()
	close_button.grab_focus()


## Freischalten (auch für Tests).
func try_unlock(skill: SkillData) -> bool:
	var success := GameState.try_unlock_skill(skill)
	_refresh()
	return success


func _get_tree_data() -> SkillTreeData:
	var player := get_tree().get_first_node_in_group(&"player") as Player
	return player.character_data.skill_tree if player else null


func _refresh() -> void:
	for child in branches_box.get_children():
		child.queue_free()
	points_label.text = "Fähigkeitspunkte: %d   (1 Punkt pro Level-Up am Ankerspiegel)" % GameState.skill_points
	var tree_data := _get_tree_data()
	var player := get_tree().get_first_node_in_group(&"player") as Player
	title_label.text = "Fähigkeiten – %s" % (player.character_data.display_name if player else "")
	if tree_data == null:
		var label := Label.new()
		label.text = "Dieser Fähigkeitenbaum kommt bald."
		branches_box.add_child(label)
		return
	for branch in tree_data.branches:
		branches_box.add_child(_make_branch(tree_data, branch))


func _make_branch(tree_data: SkillTreeData, branch: String) -> VBoxContainer:
	var column := VBoxContainer.new()
	column.custom_minimum_size.x = 300
	column.add_theme_constant_override(&"separation", 10)
	var header := Label.new()
	header.text = branch
	header.add_theme_font_size_override(&"font_size", 24)
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(header)
	for skill in tree_data.get_skills_in_branch(branch):
		column.add_child(_make_skill_card(skill))
	return column


func _make_skill_card(skill: SkillData) -> PanelContainer:
	var card := PanelContainer.new()
	var box := VBoxContainer.new()
	var name_label := Label.new()
	name_label.text = skill.display_name
	name_label.add_theme_font_size_override(&"font_size", 19)
	var description := Label.new()
	description.text = skill.description
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.modulate.a = 0.75
	box.add_child(name_label)
	box.add_child(description)
	var status := GameState.get_skill_status(skill)
	if status == GameState.SkillStatus.UNLOCKED:
		var done := Label.new()
		done.text = "✓ Erlernt"
		done.modulate = Color(0.6, 1.0, 0.7)
		box.add_child(done)
	elif status == GameState.SkillStatus.STORY_LOCKED:
		var locked := Label.new()
		locked.text = "Gesperrt: %s" % skill.story_hint
		locked.modulate = Color(1.0, 0.75, 0.5)
		box.add_child(locked)
	else:
		var button := Button.new()
		button.text = "Lernen (%d Punkt)" % skill.cost
		button.disabled = status != GameState.SkillStatus.AVAILABLE
		if status == GameState.SkillStatus.NEEDS_PREVIOUS:
			button.text = "Braucht vorige Fähigkeit"
		button.pressed.connect(try_unlock.bind(skill))
		box.add_child(button)
	card.add_child(box)
	return card

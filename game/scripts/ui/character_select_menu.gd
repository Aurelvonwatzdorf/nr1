class_name CharacterSelectMenu
extends GameMenu
## Charakterauswahl beim Start eines neuen Spiels: Aurel oder Tahirou.

@onready var choices: HBoxContainer = %Choices


func _ready() -> void:
	super._ready()
	for id: StringName in GameState.CHARACTER_PATHS:
		choices.add_child(_make_card(load(GameState.CHARACTER_PATHS[id]) as CharacterData))
	if GameState.ask_character_on_new_game and GameState.selected_character == null:
		open.call_deferred()


func _unhandled_input(event: InputEvent) -> void:
	# Die Wahl ist Pflicht: Esc schließt dieses Menü nicht.
	if is_open and event.is_action_pressed(&"menu"):
		get_viewport().set_input_as_handled()


## Figur wählen und auf die Spielfigur anwenden (auch für Tests).
func choose(id: StringName) -> void:
	if not GameState.select_character(id):
		return
	var player := get_tree().get_first_node_in_group(&"player") as Player
	if player:
		player.apply_character(GameState.selected_character)
	close()
	SaveSystem.save_game()


func _make_card(data: CharacterData) -> PanelContainer:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(360, 300)
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 20)
	var box := VBoxContainer.new()
	box.add_theme_constant_override(&"separation", 12)
	var swatch := ColorRect.new()
	swatch.color = data.placeholder_color
	swatch.custom_minimum_size = Vector2(0, 8)
	var name_label := Label.new()
	name_label.text = data.display_name
	name_label.add_theme_font_size_override(&"font_size", 32)
	var description := Label.new()
	description.text = data.description
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var button := Button.new()
	button.text = "%s wählen" % data.display_name
	button.pressed.connect(choose.bind(data.id))
	box.add_child(swatch)
	box.add_child(name_label)
	box.add_child(description)
	box.add_child(button)
	margin.add_child(box)
	card.add_child(margin)
	return card

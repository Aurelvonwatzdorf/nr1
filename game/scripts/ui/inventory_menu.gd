class_name InventoryMenu
extends GameMenu
## Inventar (Taste I): zeigt alle Gegenstände. Verbrauchbares lässt sich benutzen.

@onready var item_rows: VBoxContainer = %ItemRows
@onready var empty_label: Label = %EmptyLabel
@onready var close_button: Button = %CloseButton


func _ready() -> void:
	super._ready()
	close_button.pressed.connect(close)


func _unhandled_input(event: InputEvent) -> void:
	if is_open and (event.is_action_pressed(&"menu") or event.is_action_pressed(&"inventory")):
		close()
		get_viewport().set_input_as_handled()
	elif not is_open and event.is_action_pressed(&"inventory") and not GameState.is_menu_open():
		open()
		get_viewport().set_input_as_handled()


func _on_opened() -> void:
	_refresh()
	close_button.grab_focus()


func _refresh() -> void:
	for child in item_rows.get_children():
		child.queue_free()
	var items := GameState.inventory.get_owned_items()
	empty_label.visible = items.is_empty()
	for item in items:
		item_rows.add_child(_make_row(item))


func _make_row(item: ItemData) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override(&"separation", 16)
	var name_label := Label.new()
	name_label.text = "%s ×%d" % [item.display_name, GameState.inventory.get_count(item.id)]
	name_label.custom_minimum_size.x = 220
	var description := Label.new()
	description.text = item.description
	description.modulate.a = 0.7
	description.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	row.add_child(name_label)
	row.add_child(description)
	if item.is_consumable():
		var button := Button.new()
		button.text = "Benutzen"
		button.pressed.connect(_use.bind(item))
		row.add_child(button)
	else:
		var tag := Label.new()
		tag.text = "wirkt dauerhaft"
		tag.modulate = Color(0.6, 1.0, 0.7)
		row.add_child(tag)
	return row


func _use(item: ItemData) -> void:
	close()
	var player := get_tree().get_first_node_in_group(&"player") as Player
	if player:
		player.use_item(item)

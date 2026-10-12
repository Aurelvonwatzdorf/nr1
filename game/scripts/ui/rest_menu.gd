class_name RestMenu
extends GameMenu
## Rast-Menü am Ankerspiegel: Erinnerungen in Stats investieren.

@onready var level_label: Label = %LevelLabel
@onready var memories_label: Label = %MemoriesLabel
@onready var cost_label: Label = %CostLabel
@onready var stat_rows: VBoxContainer = %StatRows
@onready var leave_button: Button = %LeaveButton


func _ready() -> void:
	super._ready()
	leave_button.pressed.connect(close)
	EventBus.anchor_mirror_rested.connect(func(_m: Node3D, _p: Player) -> void: open())


func _unhandled_input(event: InputEvent) -> void:
	if is_open and event.is_action_pressed(&"menu"):
		close()
		get_viewport().set_input_as_handled()


func _on_opened() -> void:
	_refresh()
	leave_button.grab_focus()


## Erhöht einen Stat, falls genug Erinnerungen da sind (auch für Tests).
func try_increase(stat: StringName) -> bool:
	var success := GameState.try_level_up(stat)
	_refresh()
	return success


func _refresh() -> void:
	var stats := GameState.stats
	var cost := stats.get_level_up_cost()
	level_label.text = "Stufe %d" % stats.get_level()
	memories_label.text = "Erinnerungen: %d" % GameState.memories
	cost_label.text = "Nächste Stufe kostet: %d" % cost
	for child in stat_rows.get_children():
		child.queue_free()
	for stat: StringName in PlayerStats.ALL:
		stat_rows.add_child(_make_row(stat, cost))


func _make_row(stat: StringName, cost: int) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override(&"separation", 16)
	var name_label := Label.new()
	name_label.text = PlayerStats.DISPLAY_NAMES[stat]
	name_label.custom_minimum_size.x = 160
	var value_label := Label.new()
	value_label.text = str(GameState.stats.get_stat(stat))
	value_label.custom_minimum_size.x = 40
	var hint := Label.new()
	hint.text = PlayerStats.DESCRIPTIONS[stat]
	hint.modulate.a = 0.6
	hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(name_label)
	row.add_child(value_label)
	row.add_child(hint)
	if stat in PlayerStats.LEVELABLE:
		var button := Button.new()
		button.text = " + "
		button.disabled = GameState.memories < cost
		button.pressed.connect(try_increase.bind(stat))
		row.add_child(button)
	return row

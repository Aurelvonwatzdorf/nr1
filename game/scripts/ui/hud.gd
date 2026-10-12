class_name HUD
extends CanvasLayer
## Anzeige für Leben, Ausdauer und Fokus der Spielfigur.

@onready var name_label: Label = %NameLabel
@onready var health_bar: ProgressBar = %HealthBar
@onready var stamina_bar: ProgressBar = %StaminaBar
@onready var focus_bar: ProgressBar = %FocusBar
@onready var pause_label: Label = %PauseLabel

var _player: Player


func _process(_delta: float) -> void:
	pause_label.visible = _player != null and not _player.camera_rig.is_capturing


## Verbindet die Balken mit den Komponenten der Spielfigur.
func bind_player(player: Player) -> void:
	_player = player
	name_label.text = player.character_data.display_name
	_bind_bar(health_bar, player.health)
	_bind_bar(stamina_bar, player.stamina)
	_bind_bar(focus_bar, player.focus)


func _bind_bar(bar: ProgressBar, pool: StatPoolComponent) -> void:
	var update := func(current: float, maximum: float) -> void:
		bar.max_value = maximum
		bar.value = current
		# Längerer Balken bei höherem Maximum: Wachstum soll man sehen.
		bar.custom_minimum_size.x = maximum * 3.0
	pool.value_changed.connect(update)
	update.call(pool.current, pool.max_value)

class_name HUD
extends CanvasLayer
## Anzeige für Leben, Ausdauer und Fokus der Spielfigur.

@onready var name_label: Label = %NameLabel
@onready var health_bar: ProgressBar = %HealthBar
@onready var stamina_bar: ProgressBar = %StaminaBar
@onready var focus_bar: ProgressBar = %FocusBar
@onready var pause_label: Label = %PauseLabel
@onready var memories_label: Label = %MemoriesLabel
@onready var money_label: Label = %MoneyLabel
@onready var death_label: Label = %DeathLabel
@onready var message_label: Label = %MessageLabel
@onready var prompt_label: Label = %PromptLabel
@onready var potion_label: Label = %PotionLabel
@onready var saved_label: Label = %SavedLabel

var _player: Player
var _message_tween: Tween


func _ready() -> void:
	death_label.modulate.a = 0.0
	saved_label.modulate.a = 0.0
	message_label.modulate.a = 0.0
	_on_memories_changed(GameState.memories)
	EventBus.memories_changed.connect(_on_memories_changed)
	EventBus.money_changed.connect(_on_money_changed)
	_on_money_changed(GameState.money)
	EventBus.player_died.connect(_on_player_died)
	EventBus.player_respawned.connect(_on_player_respawned)
	prompt_label.text = ""
	EventBus.interaction_prompt_changed.connect(func(prompt: String) -> void: prompt_label.text = "E: %s" % prompt if prompt != "" else "")
	EventBus.message_requested.connect(show_message)
	EventBus.game_saved.connect(func() -> void: saved_label_flash())
	GameState.inventory.changed.connect(_update_potions)
	_update_potions()
	EventBus.checkpoint_activated.connect(func(_c: Node3D) -> void: show_message("Ankerspiegel berührt"))
	EventBus.memories_recovered.connect(func(amount: int) -> void: show_message("%d Erinnerungen zurückgeholt" % amount))
	EventBus.memories_lost.connect(func(amount: int) -> void: show_message("%d Erinnerungen für immer verloren" % amount))


func _process(_delta: float) -> void:
	pause_label.visible = _player != null and not _player.camera_rig.is_capturing and not GameState.is_menu_open()


## Kurze Meldung in der Bildschirmmitte, die von selbst verschwindet.
func show_message(text: String) -> void:
	message_label.text = text
	if _message_tween and _message_tween.is_valid():
		_message_tween.kill()
	_message_tween = create_tween()
	_message_tween.tween_property(message_label, "modulate:a", 1.0, 0.2)
	_message_tween.tween_interval(2.0)
	_message_tween.tween_property(message_label, "modulate:a", 0.0, 0.6)


## Kleiner Hinweis unten rechts, dass gespeichert wurde.
func saved_label_flash() -> void:
	saved_label.modulate.a = 1.0
	create_tween().tween_property(saved_label, "modulate:a", 0.0, 1.5).set_delay(1.0)


func _update_potions() -> void:
	potion_label.text = "Heiltränke: %d   [R]" % GameState.inventory.get_count(&"healing_potion")


func _on_money_changed(amount: int) -> void:
	money_label.text = "Geld: %d" % amount


func _on_memories_changed(amount: int) -> void:
	memories_label.text = "Erinnerungen: %d" % amount


func _on_player_died(_dead: Player) -> void:
	create_tween().tween_property(death_label, "modulate:a", 1.0, 1.2)


func _on_player_respawned(_player_node: Player) -> void:
	create_tween().tween_property(death_label, "modulate:a", 0.0, 0.5)


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

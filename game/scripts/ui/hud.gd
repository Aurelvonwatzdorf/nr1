class_name HUD
extends CanvasLayer
## Anzeige für Leben, Ausdauer und Fokus der Spielfigur.

@onready var name_label: Label = %NameLabel
@onready var health_bar: ProgressBar = %HealthBar
@onready var stamina_bar: ProgressBar = %StaminaBar
@onready var focus_bar: ProgressBar = %FocusBar
@onready var special_bar: ProgressBar = %SpecialBar
@onready var special_label: Label = %SpecialLabel
@onready var raven_label: Label = %RavenLabel

var _raven_tween: Tween
@onready var pause_label: Label = %PauseLabel
@onready var memories_label: Label = %MemoriesLabel
@onready var money_label: Label = %MoneyLabel
@onready var death_label: Label = %DeathLabel
@onready var message_label: Label = %MessageLabel
@onready var prompt_label: Label = %PromptLabel
@onready var potion_label: Label = %PotionLabel
@onready var saved_label: Label = %SavedLabel
@onready var mission_label: Label = %MissionLabel

var _player: Player
## Nur in Spiegelrealitäten: Verankerung und Hinweise, dazu die Stimme des Begleiters.
var reality_label: Label
var companion_label: Label
## Fahndung als Sterne (nur sichtbar, wenn man gesucht wird).
var wanted_label: Label
var _companion_tween: Tween
## Großer Regionsname beim Betreten (Titelkarte).
var region_title: Label
var region_subtitle: Label
var _region_tween: Tween
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
	EventBus.special_resource_changed.connect(_bind_special)
	EventBus.raven_gift_granted.connect(show_raven_gift)
	raven_label.modulate.a = 0.0
	EventBus.character_changed.connect(func(data: CharacterData) -> void: name_label.text = data.display_name)
	EventBus.game_saved.connect(func() -> void: saved_label_flash())
	GameState.inventory.changed.connect(_update_potions)
	EventBus.equipment_changed.connect(_update_potions)
	EventBus.mission_started.connect(func(m: MissionData) -> void:
		show_message("Neue Mission: %s" % m.title)
		_update_missions())
	EventBus.mission_completed.connect(func(m: MissionData) -> void:
		var reward := "   +%d Geld" % m.reward_money if m.reward_money > 0 else ""
		show_message("Mission erfüllt: %s%s" % [m.title, reward])
		_update_missions())
	EventBus.mission_failed.connect(func(m: MissionData) -> void:
		show_message("Mission gescheitert: %s" % m.title)
		_update_missions())
	_update_missions()
	_update_potions()
	_create_reality_labels()
	EventBus.companion_spoke.connect(show_companion)
	EventBus.reality_clue_found.connect(func(found: int, needed: int) -> void:
		show_message("Hinweis gefunden (%d/%d)" % [found, needed]))
	EventBus.checkpoint_activated.connect(func(_c: Node3D) -> void: show_message("Ankerspiegel berührt"))
	EventBus.memories_recovered.connect(func(amount: int) -> void: show_message("%d Erinnerungen zurückgeholt" % amount))
	EventBus.memories_lost.connect(func(amount: int) -> void: show_message("%d Erinnerungen für immer verloren" % amount))


func _process(_delta: float) -> void:
	pause_label.visible = _player != null and not _player.camera_rig.is_capturing and not GameState.is_menu_open()
	_update_reality()
	_update_wanted()


func _create_reality_labels() -> void:
	reality_label = Label.new()
	reality_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	reality_label.position = Vector2(-360, 24)
	reality_label.size = Vector2(330, 60)
	reality_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	reality_label.add_theme_font_size_override(&"font_size", 20)
	reality_label.add_theme_color_override(&"font_color", Color(0.6, 0.9, 1.0))
	reality_label.visible = false
	add_child(reality_label)
	wanted_label = Label.new()
	wanted_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	wanted_label.position = Vector2(-360, 96)
	wanted_label.size = Vector2(330, 40)
	wanted_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	wanted_label.add_theme_font_size_override(&"font_size", 26)
	wanted_label.add_theme_color_override(&"font_color", Color(1.0, 0.35, 0.35))
	wanted_label.add_theme_color_override(&"font_outline_color", Color(0, 0, 0))
	wanted_label.add_theme_constant_override(&"outline_size", 6)
	wanted_label.visible = false
	add_child(wanted_label)
	companion_label = Label.new()
	companion_label.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	companion_label.position = Vector2(-450, -170)
	companion_label.size = Vector2(900, 40)
	companion_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	companion_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	companion_label.add_theme_font_size_override(&"font_size", 20)
	companion_label.add_theme_color_override(&"font_color", Color(0.85, 0.95, 1.0))
	companion_label.add_theme_color_override(&"font_outline_color", Color(0, 0, 0))
	companion_label.add_theme_constant_override(&"outline_size", 6)
	companion_label.modulate.a = 0.0
	add_child(companion_label)
	region_title = Label.new()
	region_title.set_anchors_preset(Control.PRESET_CENTER_TOP)
	region_title.position = Vector2(-500, 150)
	region_title.size = Vector2(1000, 70)
	region_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	region_title.add_theme_font_size_override(&"font_size", 54)
	region_title.add_theme_color_override(&"font_color", Color(1.0, 0.95, 0.85))
	region_title.add_theme_color_override(&"font_outline_color", Color(0, 0, 0, 0.85))
	region_title.add_theme_constant_override(&"outline_size", 10)
	region_title.modulate.a = 0.0
	add_child(region_title)
	region_subtitle = Label.new()
	region_subtitle.set_anchors_preset(Control.PRESET_CENTER_TOP)
	region_subtitle.position = Vector2(-500, 222)
	region_subtitle.size = Vector2(1000, 40)
	region_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	region_subtitle.add_theme_font_size_override(&"font_size", 22)
	region_subtitle.add_theme_color_override(&"font_color", Color(0.85, 0.85, 0.8))
	region_subtitle.add_theme_color_override(&"font_outline_color", Color(0, 0, 0, 0.85))
	region_subtitle.add_theme_constant_override(&"outline_size", 6)
	region_subtitle.modulate.a = 0.0
	add_child(region_subtitle)


## In Spiegelrealitäten: Verankerung anzeigen und das HUD verblassen lassen.
func _update_wanted() -> void:
	var stars := ceili(GameState.wanted_level / 20.0)
	wanted_label.visible = stars > 0
	wanted_label.text = "Fahndung  " + "★".repeat(stars) + "☆".repeat(5 - stars)


func _update_reality() -> void:
	var reality := get_tree().get_first_node_in_group(&"reality") as RealityLevel
	reality_label.visible = reality != null
	var fade := 0.0
	if reality:
		reality_label.text = "%s\nVerankerung %d %%   ·   Hinweise %d/%d" % [
			reality.reality_name, roundi(reality.anchoring), reality.clues_found, reality.clues_needed]
		fade = reality.get_fade()
	var alpha := lerpf(1.0, 0.25, fade)
	for child in get_children():
		var control := child as Control
		if control and control != companion_label and control != message_label:
			control.self_modulate.a = alpha


## Der Begleiter spricht (kursive Zeile unten). Bei hoher Verankerung leiser.
func show_companion(text: String) -> void:
	var reality := get_tree().get_first_node_in_group(&"reality") as RealityLevel
	var loudness := lerpf(1.0, 0.3, reality.get_fade()) if reality else 1.0
	companion_label.text = "Begleiter: „%s“" % text
	if _companion_tween and _companion_tween.is_valid():
		_companion_tween.kill()
	_companion_tween = create_tween()
	_companion_tween.tween_property(companion_label, "modulate:a", loudness, 0.4)
	_companion_tween.tween_interval(4.0)
	_companion_tween.tween_property(companion_label, "modulate:a", 0.0, 0.8)


## Gabe der Raben-Ahnen (nur Tahirou): eigene Zeile, verblasst nach ein paar Sekunden.
func show_raven_gift(gift_name: String, text: String) -> void:
	raven_label.text = "Die Ahnen leihen dir: %s\n„%s“" % [gift_name, text]
	if _raven_tween and _raven_tween.is_valid():
		_raven_tween.kill()
	_raven_tween = create_tween()
	_raven_tween.tween_property(raven_label, "modulate:a", 1.0, 0.3)
	_raven_tween.tween_interval(3.5)
	_raven_tween.tween_property(raven_label, "modulate:a", 0.0, 0.8)


## Titelkarte: Regionsname groß, darunter die Epoche (bzw. „Neu entdeckt“).
func show_region_title(title: String, subtitle: String) -> void:
	region_title.text = "— %s —" % title
	region_subtitle.text = subtitle
	if _region_tween and _region_tween.is_valid():
		_region_tween.kill()
	_region_tween = create_tween().set_parallel()
	for label: Label in [region_title, region_subtitle]:
		label.modulate.a = 0.0
		_region_tween.tween_property(label, "modulate:a", 1.0, 0.8)
	_region_tween.chain().tween_interval(3.0)
	_region_tween.chain().tween_property(region_title, "modulate:a", 0.0, 1.2)
	_region_tween.parallel().tween_property(region_subtitle, "modulate:a", 0.0, 1.2)


## Kurze Meldung in der Bildschirmmitte, die von selbst verschwindet.
func show_message(text: String) -> void:
	message_label.text = text
	if _message_tween and _message_tween.is_valid():
		_message_tween.kill()
	_message_tween = create_tween()
	_message_tween.tween_property(message_label, "modulate:a", 1.0, 0.2)
	# Längere Hinweise (z. B. Steuerung) bleiben länger stehen.
	_message_tween.tween_interval(maxf(2.0, text.length() * 0.06))
	_message_tween.tween_property(message_label, "modulate:a", 0.0, 0.6)


## Kleiner Hinweis unten rechts, dass gespeichert wurde.
func saved_label_flash() -> void:
	saved_label.modulate.a = 1.0
	create_tween().tween_property(saved_label, "modulate:a", 0.0, 1.5).set_delay(1.0)


func _update_missions() -> void:
	var lines: PackedStringArray = []
	for mission in GameState.get_active_missions():
		lines.append("◆ %s\n   %s" % [mission.title, mission.objective])
	mission_label.text = "\n".join(lines)


func _update_potions() -> void:
	var text := "Heiltränke: %d   [R]" % GameState.inventory.get_count(&"healing_potion")
	var weapon := ItemDatabase.get_item(GameState.equipped_weapon) if GameState.equipped_weapon != &"" else null
	if weapon:
		text += "\nWaffe: %s" % weapon.display_name
	var firearm := ItemDatabase.get_item(GameState.equipped_firearm) if GameState.equipped_firearm != &"" else null
	if firearm:
		text += "\n%s: %d Schuss   [V]" % [firearm.display_name, GameState.inventory.get_count(firearm.ammo_id)]
	potion_label.text = text


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
	_bind_special(player.special_resource, player.character_data.special_resource)


## Balken für die eigene Ressource der Figur (Ehrgeiz …), sonst ausgeblendet.
func _bind_special(pool: StatPoolComponent, kind: StringName) -> void:
	special_bar.visible = pool != null
	special_label.visible = pool != null
	if pool == null:
		return
	special_label.text = {&"ambition": "Ehrgeiz", &"ravens": "Rabenbund"}.get(kind, String(kind))
	var fill := StyleBoxFlat.new()
	fill.bg_color = {&"ambition": Color(0.95, 0.55, 0.15), &"ravens": Color(0.5, 0.42, 0.85)}.get(kind, Color.WHITE)
	special_bar.add_theme_stylebox_override(&"fill", fill)
	var update := func(current: float, maximum: float) -> void:
		special_bar.max_value = maximum
		special_bar.value = current
	pool.value_changed.connect(update)
	update.call(pool.current, pool.max_value)


func _bind_bar(bar: ProgressBar, pool: StatPoolComponent) -> void:
	var update := func(current: float, maximum: float) -> void:
		bar.max_value = maximum
		bar.value = current
		# Längerer Balken bei höherem Maximum: Wachstum soll man sehen.
		bar.custom_minimum_size.x = maximum * 3.0
	pool.value_changed.connect(update)
	update.call(pool.current, pool.max_value)

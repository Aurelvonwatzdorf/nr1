class_name MainMenu
extends Control
## Hauptmenü beim Start des Spiels: Weiterspielen, Neues Spiel, Steuerung,
## Beenden. Baut seine Oberfläche im Code.

const SCENE := "res://scenes/ui/main_menu.tscn"
const TITLE := "Spiegelrealitäten"
const VERSION_TEXT := "Version 0.1 · erste spielbare Fassung"
const CONTROLS := [
	["WASD", "Laufen (Shift: rennen)"],
	["Maus", "Kamera"],
	["Leertaste", "Springen"],
	["Strg", "Ausweichen"],
	["Linksklick", "Angriff (mit Shift: schwerer Angriff)"],
	["Rechtsklick", "Blocken / Parieren"],
	["Tab / Mittelklick", "Gegner anvisieren"],
	["V", "Schusswaffe"],
	["Q", "Realitätsblick"],
	["E", "Benutzen / Sprechen"],
	["R", "Heiltrank"],
	["F", "Raben (Tahirou) / Fernzugriff (Aurel)"],
	["I / K / M", "Inventar / Fähigkeiten / Karte"],
	["Esc", "Pause"],
]

## Szenen wechseln? (Im Test aus.)
var change_scene: bool = true

var continue_button: Button
var new_game_button: Button
var controls_button: Button
var quit_button: Button
var _menu_box: VBoxContainer
var _controls_panel: PanelContainer
var _confirm_panel: PanelContainer


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().paused = false
	_build_background()
	_build_menu()
	_controls_panel = _build_controls()
	_confirm_panel = _build_confirm()
	continue_button.disabled = not SaveSystem.has_save()
	(continue_button if not continue_button.disabled else new_game_button).grab_focus.call_deferred()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"menu") and (_controls_panel.visible or _confirm_panel.visible):
		_show_menu()
		get_viewport().set_input_as_handled()


## Gespeichertes Spiel laden und in die gespeicherte Welt wechseln.
func continue_game() -> void:
	if not SaveSystem.load_game():
		return
	var target := GameState.current_scene
	if target == "" or not ResourceLoader.exists(target):
		target = GameState.START_SCENE
	_go(target)


## Spielstand löschen und im Konzernturm neu beginnen (Figurenwahl folgt dort).
func start_new_game() -> void:
	SaveSystem.delete_save()
	GameState.reset()
	_go(GameState.START_SCENE)


func _go(scene: String) -> void:
	if change_scene:
		get_tree().change_scene_to_file(scene)


func _on_new_game_pressed() -> void:
	if SaveSystem.has_save():
		_menu_box.visible = false
		_confirm_panel.visible = true
	else:
		start_new_game()


func _show_menu() -> void:
	_controls_panel.visible = false
	_confirm_panel.visible = false
	_menu_box.visible = true
	new_game_button.grab_focus()


func _build_background() -> void:
	var gradient := Gradient.new()
	gradient.set_color(0, Color(0.03, 0.04, 0.08))
	gradient.set_color(1, Color(0.16, 0.08, 0.2))
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill_from = Vector2(0.5, 0.0)
	texture.fill_to = Vector2(0.5, 1.0)
	var background := TextureRect.new()
	background.texture = texture
	background.stretch_mode = TextureRect.STRETCH_SCALE
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	# Ein feiner Riss quer durchs Bild: das Motiv der Spiegelrealitäten.
	var crack := Line2D.new()
	crack.width = 2.0
	crack.default_color = Color(0.55, 0.85, 1.0, 0.35)
	crack.points = PackedVector2Array([Vector2(1180, 0), Vector2(1130, 210), Vector2(1210, 380),
		Vector2(1150, 560), Vector2(1240, 740), Vector2(1200, 900)])
	add_child(crack)
	var version := Label.new()
	version.text = VERSION_TEXT
	version.modulate = Color(1, 1, 1, 0.45)
	version.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	version.position = Vector2(-340, -40)
	version.size = Vector2(320, 24)
	version.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_child(version)


func _build_menu() -> void:
	_menu_box = VBoxContainer.new()
	_menu_box.position = Vector2(140, 220)
	_menu_box.custom_minimum_size = Vector2(420, 0)
	_menu_box.add_theme_constant_override(&"separation", 14)
	add_child(_menu_box)
	var title := Label.new()
	title.text = TITLE
	title.add_theme_font_size_override(&"font_size", 64)
	title.add_theme_color_override(&"font_color", Color(0.9, 0.93, 1.0))
	_menu_box.add_child(title)
	var subtitle := Label.new()
	subtitle.text = "Nichts ist, wie es scheint."
	subtitle.add_theme_font_size_override(&"font_size", 22)
	subtitle.modulate = Color(0.7, 0.85, 1.0, 0.8)
	_menu_box.add_child(subtitle)
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 40)
	_menu_box.add_child(spacer)
	continue_button = _menu_button("Weiterspielen", continue_game)
	new_game_button = _menu_button("Neues Spiel", _on_new_game_pressed)
	controls_button = _menu_button("Steuerung", func() -> void:
		_menu_box.visible = false
		_controls_panel.visible = true)
	quit_button = _menu_button("Beenden", func() -> void: get_tree().quit())


func _menu_button(text: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.custom_minimum_size = Vector2(320, 52)
	button.add_theme_font_size_override(&"font_size", 26)
	button.pressed.connect(action)
	_menu_box.add_child(button)
	return button


func _panel(heading: String) -> Array:
	var panel := PanelContainer.new()
	panel.position = Vector2(140, 200)
	panel.visible = false
	add_child(panel)
	var margin := MarginContainer.new()
	for side: String in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 28)
	panel.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override(&"separation", 10)
	margin.add_child(box)
	var label := Label.new()
	label.text = heading
	label.add_theme_font_size_override(&"font_size", 34)
	box.add_child(label)
	return [panel, box]


func _build_controls() -> PanelContainer:
	var parts := _panel("Steuerung")
	var box: VBoxContainer = parts[1]
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override(&"h_separation", 32)
	for row: Array in CONTROLS:
		var key := Label.new()
		key.text = row[0]
		key.add_theme_color_override(&"font_color", Color(0.6, 0.85, 1.0))
		var what := Label.new()
		what.text = row[1]
		grid.add_child(key)
		grid.add_child(what)
	box.add_child(grid)
	var back := Button.new()
	back.text = "Zurück"
	back.pressed.connect(_show_menu)
	box.add_child(back)
	return parts[0]


func _build_confirm() -> PanelContainer:
	var parts := _panel("Neues Spiel?")
	var box: VBoxContainer = parts[1]
	var text := Label.new()
	text.text = "Dein bisheriger Spielstand wird gelöscht."
	box.add_child(text)
	var row := HBoxContainer.new()
	row.add_theme_constant_override(&"separation", 16)
	var yes := Button.new()
	yes.text = "Ja, neu beginnen"
	yes.pressed.connect(start_new_game)
	var no := Button.new()
	no.text = "Abbrechen"
	no.pressed.connect(_show_menu)
	row.add_child(yes)
	row.add_child(no)
	box.add_child(row)
	return parts[0]

class_name TouchControls
extends CanvasLayer
## Bildschirm-Steuerung für iPhone/iPad: links ein Stick zum Laufen (ganz nach
## außen = rennen), rechts Knöpfe für Kampf und Aktionen, freies Wischen dreht
## die Kamera. Die Knöpfe lösen dieselben Input-Aktionen aus wie Tastatur und
## Controller, die Spiellogik merkt keinen Unterschied.
## Sichtbar nur, wenn `GameState.touch_controls` an ist (Handy/Tablet).

const STICK_RADIUS := 90.0
const SPRINT_THRESHOLD := 0.95
const LOOK_SENSITIVITY := 0.006
## Knöpfe: Aktion, Beschriftung, Ecke (unten rechts / oben rechts), Abstand zur Ecke, Radius.
const BUTTONS := [
	[&"attack_light", "Schlag", "br", Vector2(-150, -150), 70.0],
	[&"attack_heavy", "Schwer", "br", Vector2(-310, -110), 48.0],
	[&"dodge", "Ausw.", "br", Vector2(-150, -310), 48.0],
	[&"jump", "Sprung", "br", Vector2(-290, -250), 48.0],
	[&"block", "Block", "br", Vector2(-430, -150), 44.0],
	[&"lock_on", "Ziel", "br", Vector2(-50, -330), 36.0],
	[&"interact", "E", "tr", Vector2(-60, 70), 34.0],
	[&"reality_sight", "Q", "tr", Vector2(-140, 70), 34.0],
	[&"heal", "R", "tr", Vector2(-220, 70), 34.0],
	[&"call_spirit", "F", "tr", Vector2(-300, 70), 34.0],
	[&"fire", "V", "tr", Vector2(-380, 70), 34.0],
	[&"map", "Karte", "tr", Vector2(-60, 160), 34.0],
	[&"inventory", "Inv.", "tr", Vector2(-140, 160), 34.0],
	[&"skills", "Fäh.", "tr", Vector2(-220, 160), 34.0],
	[&"menu", "II", "tr", Vector2(-300, 160), 34.0],
]
## In Menüs (Karte, Inventar …) gibt es nur diesen Knopf; er wirkt wie Esc.
const BACK_BUTTON := [&"menu", "Zurück", "tr", Vector2(-80, 60), 44.0]

## Welcher Finger macht was: Index → &"stick", &"look" oder eine Aktion.
var _touches: Dictionary[int, StringName] = {}
## Gedrückte Aktionen mit Stärke.
var _pressed: Dictionary[StringName, float] = {}
var _stick_origin: Vector2 = Vector2.ZERO
var _stick_vector: Vector2 = Vector2.ZERO
var _pad: Control
## Feste Bildschirmgröße für Tests (ohne Fenster ist es sonst winzig). ZERO = echte Größe.
var screen_size_override: Vector2 = Vector2.ZERO


## Ist gerade ein Menü offen? Dann nur der Zurück-Knopf, Tippen geht ans Menü.
var _menu_mode: bool = false


func _ready() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS
	_pad = Control.new()
	_pad.set_anchors_preset(Control.PRESET_FULL_RECT)
	_pad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pad.draw.connect(_draw_controls)
	add_child(_pad)
	visible = GameState.touch_controls


func _process(_delta: float) -> void:
	visible = GameState.touch_controls
	var menu_open := GameState.is_menu_open()
	if menu_open != _menu_mode:
		_menu_mode = menu_open
		release_all()
	if visible:
		_pad.queue_redraw()


func _input(event: InputEvent) -> void:
	if not visible:
		return
	if _menu_mode:
		_menu_input(event)
		return
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed:
			_touch_started(touch.index, touch.position)
		else:
			_touch_ended(touch.index)
		get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag:
		var drag := event as InputEventScreenDrag
		_touch_moved(drag.index, drag.position, drag.relative)
		get_viewport().set_input_as_handled()


## Im Menü: nur der Zurück-Knopf zählt, alles andere tippt ins Menü (als Mausklick).
func _menu_input(event: InputEvent) -> void:
	if not event is InputEventScreenTouch:
		return
	var touch := event as InputEventScreenTouch
	var on_back := touch.position.distance_to(_button_center(BACK_BUTTON)) <= float(BACK_BUTTON[4]) * 1.15
	if touch.pressed and on_back:
		_touches[touch.index] = &"menu"
		_set_action(&"menu", true)
		get_viewport().set_input_as_handled()
	elif not touch.pressed and _touches.get(touch.index, &"") == &"menu":
		_touches.erase(touch.index)
		_set_action(&"menu", false)
		get_viewport().set_input_as_handled()


## Alle Knöpfe loslassen (z. B. wenn ein Menü aufgeht).
func release_all() -> void:
	for action: StringName in _pressed.keys():
		_set_action(action, false)
	_touches.clear()
	_stick_vector = Vector2.ZERO


func _touch_started(index: int, position: Vector2) -> void:
	var action := _button_at(position)
	if action != &"":
		_touches[index] = action
		_set_action(action, true)
	elif position.x < _screen_size().x * 0.45 and position.y > _screen_size().y * 0.35:
		_touches[index] = &"stick"
		_stick_origin = position
		_stick_vector = Vector2.ZERO
	else:
		_touches[index] = &"look"


func _touch_moved(index: int, position: Vector2, relative: Vector2) -> void:
	match _touches.get(index, &""):
		&"stick":
			_stick_vector = ((position - _stick_origin) / STICK_RADIUS).limit_length(1.0)
			_apply_stick()
		&"look":
			var player := get_tree().get_first_node_in_group(&"player") as Player
			if player and player.is_input_enabled():
				player.camera_rig.add_look(relative * LOOK_SENSITIVITY)


func _touch_ended(index: int) -> void:
	var role: StringName = _touches.get(index, &"")
	_touches.erase(index)
	if role == &"stick":
		_stick_vector = Vector2.ZERO
		_apply_stick()
	elif role != &"look" and role != &"":
		_set_action(role, false)


func _apply_stick() -> void:
	_set_action(&"move_right", _stick_vector.x > 0.0, maxf(_stick_vector.x, 0.0))
	_set_action(&"move_left", _stick_vector.x < 0.0, maxf(-_stick_vector.x, 0.0))
	_set_action(&"move_back", _stick_vector.y > 0.0, maxf(_stick_vector.y, 0.0))
	_set_action(&"move_forward", _stick_vector.y < 0.0, maxf(-_stick_vector.y, 0.0))
	_set_action(&"sprint", _stick_vector.length() >= SPRINT_THRESHOLD)


## Aktion wie eine echte Taste auslösen (auch Menüs, die auf Ereignisse hören, merken es).
func _set_action(action: StringName, pressed: bool, strength: float = 1.0) -> void:
	if not pressed and not _pressed.has(action):
		return
	if pressed and is_equal_approx(_pressed.get(action, -1.0), strength):
		return
	var event := InputEventAction.new()
	event.action = action
	event.pressed = pressed
	event.strength = strength if pressed else 0.0
	if pressed:
		_pressed[action] = strength
	else:
		_pressed.erase(action)
	Input.parse_input_event(event)


func _button_at(position: Vector2) -> StringName:
	for button: Array in BUTTONS:
		if position.distance_to(_button_center(button)) <= float(button[4]) * 1.15:
			return button[0]
	return &""


func _button_center(button: Array) -> Vector2:
	var size := _screen_size()
	var corner := Vector2(size.x, size.y) if button[2] == "br" else Vector2(size.x, 0.0)
	return corner + (button[3] as Vector2)


## Mitte eines Knopfs (für Tests).
func button_center(action: StringName) -> Vector2:
	if _menu_mode and action == &"menu":
		return _button_center(BACK_BUTTON)
	for button: Array in BUTTONS:
		if button[0] == action:
			return _button_center(button)
	return Vector2.ZERO


func _screen_size() -> Vector2:
	if screen_size_override != Vector2.ZERO:
		return screen_size_override
	return get_viewport().get_visible_rect().size


func _draw_controls() -> void:
	for button: Array in ([BACK_BUTTON] if _menu_mode else BUTTONS):
		_draw_button(button)
	if _menu_mode:
		return
	# Stick: Grundkreis und Knauf, solange ein Finger darauf liegt.
	if _touches.values().has(&"stick"):
		_pad.draw_circle(_stick_origin, STICK_RADIUS, Color(0.08, 0.1, 0.16, 0.3))
		_pad.draw_arc(_stick_origin, STICK_RADIUS, 0.0, TAU, 48, Color(0.6, 0.85, 1.0, 0.5), 2.0)
		_pad.draw_circle(_stick_origin + _stick_vector * STICK_RADIUS, 34.0, Color(0.6, 0.85, 1.0, 0.6))
	else:
		var hint := Vector2(200, _screen_size().y - 200)
		_pad.draw_arc(hint, STICK_RADIUS, 0.0, TAU, 48, Color(0.6, 0.85, 1.0, 0.25), 2.0)


func _draw_button(button: Array) -> void:
	var font := ThemeDB.fallback_font
	var center := _button_center(button)
	var radius := float(button[4])
	var held := _pressed.has(button[0] as StringName)
	_pad.draw_circle(center, radius, Color(0.08, 0.1, 0.16, 0.55 if held else 0.35))
	_pad.draw_arc(center, radius, 0.0, TAU, 40, Color(0.6, 0.85, 1.0, 0.9 if held else 0.5), 2.0)
	var text := String(button[1])
	var font_size := 22 if radius >= 44.0 else 18
	var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	_pad.draw_string(font, center + Vector2(-width * 0.5, font_size * 0.35), text,
		HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(1, 1, 1, 0.85))

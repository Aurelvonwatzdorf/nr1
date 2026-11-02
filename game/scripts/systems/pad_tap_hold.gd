extends Node
## Gamepad: eine Taste, zwei Aktionen (Entscheidung des Nutzers „Tippen/Halten“).
## Kurz tippen löst die erste Aktion beim Loslassen aus (wie die Rolle in
## Souls-Spielen), halten löst nach HOLD_TIME die zweite aus, solange gehalten.
## Gesendet werden echte InputEventActions; die Spiellogik merkt keinen Unterschied.
## Die Knöpfe hier dürfen in der Input-Map **nicht** selbst eingetragen sein.

const HOLD_TIME := 0.25
## Gamepad-Knopf → [Aktion beim Tippen, Aktion beim Halten].
const PAIRS: Dictionary[int, Array] = {
	JOY_BUTTON_B: [&"dodge", &"crouch"],
	JOY_BUTTON_DPAD_UP: [&"call_spirit", &"ability"],
}
## So viele Physik-Frames bleibt eine getippte Aktion gedrückt (sonst sieht
## `is_action_just_pressed` sie evtl. nicht).
const TAP_FRAMES := 2

## Knopf → gehaltene Zeit; Knöpfe, deren Halte-Aktion schon läuft.
var _held_time: Dictionary[int, float] = {}
var _holding: Dictionary[int, bool] = {}
## Getippte Aktion → verbleibende Physik-Frames bis zum Loslassen.
var _tap_release: Dictionary[StringName, int] = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _input(event: InputEvent) -> void:
	var button := event as InputEventJoypadButton
	if button == null or not PAIRS.has(button.button_index):
		return
	var index := button.button_index
	if button.pressed:
		_held_time[index] = 0.0
		_holding[index] = false
	elif _held_time.has(index):
		var actions: Array = PAIRS[index]
		if _holding[index]:
			_send(actions[1], false)
		else:
			_send(actions[0], true)
			_tap_release[actions[0]] = TAP_FRAMES
		_held_time.erase(index)
		_holding.erase(index)


func _process(delta: float) -> void:
	for index: int in _held_time.keys():
		_held_time[index] += delta
		if not _holding[index] and _held_time[index] >= HOLD_TIME:
			_holding[index] = true
			_send(PAIRS[index][1], true)


func _physics_process(_delta: float) -> void:
	for action: StringName in _tap_release.keys():
		_tap_release[action] -= 1
		if _tap_release[action] <= 0:
			_tap_release.erase(action)
			_send(action, false)


func _send(action: StringName, pressed: bool) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = pressed
	event.strength = 1.0 if pressed else 0.0
	Input.parse_input_event(event)

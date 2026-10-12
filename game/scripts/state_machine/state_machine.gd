class_name StateMachine
extends Node
## Endlicher Automat: genau ein Kind-Zustand ist aktiv.
##
## Die Zustände sind Kind-Knoten (Typ State). Ihr Knotenname in Kleinbuchstaben ist
## ihr Schlüssel, z. B. „Idle“ → &"idle". Der Besitzer ruft `physics_update()` selbst
## auf, damit die Reihenfolge (Zustand → move_and_slide) eindeutig ist.

signal state_changed(old_state: StringName, new_state: StringName)

## Zustand, mit dem die Maschine startet.
@export var initial_state: State

var current_state: State
var _states: Dictionary[StringName, State] = {}


func start(actor: Node) -> void:
	for child in get_children():
		if child is State:
			var state := child as State
			state.setup(actor, self)
			_states[StringName(state.name.to_lower())] = state
	current_state = initial_state
	if current_state:
		current_state.enter()


func physics_update(delta: float) -> void:
	if current_state:
		current_state.physics_update(delta)


## Wechselt den Zustand. Ein Wechsel in denselben Zustand startet ihn neu
## (wichtig für Angriffs-Kombos).
func transition_to(state_name: StringName, msg: Dictionary = {}) -> void:
	var next: State = _states.get(state_name)
	if next == null:
		push_warning("Zustand nicht gefunden: %s" % state_name)
		return
	var old_name := get_current_state_name()
	if current_state:
		current_state.exit()
	current_state = next
	current_state.enter(msg)
	state_changed.emit(old_name, state_name)


func get_current_state_name() -> StringName:
	return StringName(current_state.name.to_lower()) if current_state else &""

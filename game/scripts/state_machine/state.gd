class_name State
extends Node
## Ein Zustand einer StateMachine (z. B. „Laufen“ oder „Angreifen“).
##
## Eigene Zustände erben hiervon und überschreiben nur, was sie brauchen.

## Die Maschine, zu der dieser Zustand gehört.
var state_machine: StateMachine
## Die Figur, die gesteuert wird (Spieler oder Gegner).
var actor: Node


## Wird einmal beim Start der Maschine aufgerufen.
func setup(new_actor: Node, machine: StateMachine) -> void:
	actor = new_actor
	state_machine = machine


## Zustand wird betreten. `msg` kann Zusatzinfos enthalten (z. B. {"heavy": true}).
func enter(_msg: Dictionary = {}) -> void:
	pass


## Zustand wird verlassen.
func exit() -> void:
	pass


## Jeden Physik-Frame, solange der Zustand aktiv ist.
func physics_update(_delta: float) -> void:
	pass

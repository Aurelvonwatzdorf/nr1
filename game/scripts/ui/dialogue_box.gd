class_name DialogueBox
extends GameMenu
## Gesprächsfenster. NPCs rufen `await ask(...)` auf und bekommen die Nummer der
## gewählten Antwort zurück. Am Ende des Gesprächs `finish()` aufrufen.
##
##   var choice := await dialogue.ask("Händler", "Was darf's sein?", ["Kaufen", "Tschüss"])

signal option_chosen(index: int)

@onready var speaker_label: Label = %SpeakerLabel
@onready var text_label: Label = %TextLabel
@onready var options_box: VBoxContainer = %Options

var _option_count: int = 0


func _ready() -> void:
	super._ready()
	add_to_group(&"dialogue_box")


func _unhandled_input(event: InputEvent) -> void:
	# Esc wählt die letzte Antwort (meist „Tschüss“).
	if is_open and event.is_action_pressed(&"menu"):
		choose(_option_count - 1)
		get_viewport().set_input_as_handled()


## Zeigt einen Satz mit Antworten und wartet auf die Wahl.
## Ohne Antworten gibt es nur „Weiter“.
func ask(speaker: String, text: String, options: Array[String] = []) -> int:
	open()
	speaker_label.text = speaker
	text_label.text = text
	if options.is_empty():
		options = ["Weiter"]
	_option_count = options.size()
	for child in options_box.get_children():
		child.queue_free()
	for i in options.size():
		var button := Button.new()
		button.text = "%d. %s" % [i + 1, options[i]]
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.pressed.connect(choose.bind(i))
		options_box.add_child(button)
		if i == 0:
			button.grab_focus.call_deferred()
	var index: int = await option_chosen
	return index


## Wählt eine Antwort (auch für Tests).
func choose(index: int) -> void:
	if is_open:
		option_chosen.emit(clampi(index, 0, _option_count - 1))


## Gespräch beenden: Fenster zu, Spiel läuft weiter.
func finish() -> void:
	close()

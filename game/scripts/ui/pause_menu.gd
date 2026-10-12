class_name PauseMenu
extends GameMenu
## Pausenmenü (Esc): Fortsetzen, Speichern, Beenden.

@onready var resume_button: Button = %ResumeButton
@onready var save_button: Button = %SaveButton
@onready var new_game_button: Button = %NewGameButton
@onready var quit_button: Button = %QuitButton
@onready var status_label: Label = %StatusLabel


func _ready() -> void:
	super._ready()
	resume_button.pressed.connect(close)
	save_button.pressed.connect(_on_save_pressed)
	new_game_button.pressed.connect(_on_new_game_pressed)
	quit_button.pressed.connect(func() -> void: get_tree().quit())


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed(&"menu"):
		return
	if is_open:
		close()
	elif GameState.open_menu_count == 0:
		open()
	else:
		return
	get_viewport().set_input_as_handled()


func _on_opened() -> void:
	status_label.text = ""
	resume_button.grab_focus()


## Spielstand löschen und von vorn beginnen.
func _on_new_game_pressed() -> void:
	SaveSystem.delete_save()
	GameState.reset()
	close()
	get_tree().reload_current_scene()


func _on_save_pressed() -> void:
	status_label.text = "Gespeichert." if SaveSystem.save_game() else "Speichern fehlgeschlagen."

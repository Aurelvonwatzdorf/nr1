extends Node
## Speichern und Laden (Autoload „SaveSystem“).
##
## Grundgerüst: schreibt den GameState als JSON nach `user://savegame.json`.
## Ab M3 speichern Ankerspiegel hier zusätzlich Position, Inventar usw.

const SAVE_PATH := "user://savegame.json"


func save_game() -> bool:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("Speichern fehlgeschlagen: %s" % error_string(FileAccess.get_open_error()))
		return false
	file.store_string(JSON.stringify(GameState.to_dict(), "\t"))
	return true


func load_game() -> bool:
	if not has_save():
		return false
	var text := FileAccess.get_file_as_string(SAVE_PATH)
	var data: Variant = JSON.parse_string(text)
	if data is Dictionary:
		GameState.from_dict(data)
		return true
	push_error("Spielstand ist beschädigt.")
	return false


func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

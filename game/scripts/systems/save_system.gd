extends Node
## Speichern und Laden (Autoload „SaveSystem“).
##
## Schreibt den ganzen GameState als JSON nach `save_path`. Gespeichert wird beim
## Rasten am Ankerspiegel und über das Pausenmenü. Geladen wird beim Start der
## Spielszene (siehe test_arena.gd), bevor die Figur und die Welt bereit sind.

const SAVE_VERSION := 1

var save_path: String = "user://savegame.json"
## Beim Start automatisch laden? (Im Rauchtest aus.)
var auto_load_enabled: bool = true


func _ready() -> void:
	# Die fertige App hat einen eigenen Spielstand, getrennt vom Testen im Editor.
	if not OS.is_debug_build():
		save_path = "user://spielstand.json"
	EventBus.anchor_mirror_rested.connect(func(_m: Node3D, _p: Player) -> void: save_game())


func save_game() -> bool:
	var file := FileAccess.open(save_path, FileAccess.WRITE)
	if file == null:
		push_error("Speichern fehlgeschlagen: %s" % error_string(FileAccess.get_open_error()))
		return false
	var data := GameState.to_dict()
	data["version"] = SAVE_VERSION
	file.store_string(JSON.stringify(data, "\t"))
	EventBus.game_saved.emit()
	return true


func load_game() -> bool:
	if not has_save():
		return false
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(save_path))
	if not data is Dictionary:
		push_error("Spielstand ist beschädigt.")
		return false
	GameState.from_dict(data)
	return true


func has_save() -> bool:
	return FileAccess.file_exists(save_path)


func delete_save() -> void:
	if has_save():
		DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path))

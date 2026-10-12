class_name GameMenu
extends CanvasLayer
## Basis für Vollbild-Menüs (Pause, Rasten, Inventar). Beim Öffnen wird das Spiel
## pausiert und die Maus freigegeben, beim Schließen wieder eingefangen.

signal opened
signal closed

var is_open: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false


func open() -> void:
	if is_open:
		return
	is_open = true
	visible = true
	GameState.open_menu_count += 1
	_on_opened()
	opened.emit()


func close() -> void:
	if not is_open:
		return
	is_open = false
	visible = false
	GameState.open_menu_count -= 1
	closed.emit()


## Für Unterklassen: Inhalt beim Öffnen aktualisieren.
func _on_opened() -> void:
	pass

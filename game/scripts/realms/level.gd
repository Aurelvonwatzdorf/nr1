class_name Level
extends Node3D
## Gemeinsame Grundlage für spielbare Gebiete (Testarena, Santo Santiago …):
## lädt den Spielstand vor dem Aufbau, stellt den gezeichneten Look ein und
## verbindet Spielfigur und Oberfläche.
##
## Erwartet die Kinder „Player“ und „GameUI“ (scenes/ui/game_ui.tscn).

@onready var player: Player = $Player
@onready var hud: HUD = $GameUI/HUD

## Wurde beim Start ein Spielstand geladen?
var _loaded_save: bool = false


func _enter_tree() -> void:
	# Vor allen _ready()-Aufrufen laden, damit Figur, Gegenstände und Stats
	# gleich mit den gespeicherten Daten starten.
	if SaveSystem.auto_load_enabled:
		_loaded_save = SaveSystem.load_game()


func _ready() -> void:
	ToonStyle.apply_to_tree(self)
	if _loaded_save and GameState.has_checkpoint:
		player.global_transform = GameState.checkpoint_transform
		player.rest()
		hud.show_message.call_deferred("Spielstand geladen")
	# Die Arena kennt beide und verbindet sie. (_ready der Arena läuft erst,
	# wenn alle Kinder fertig sind.)
	hud.bind_player(player)

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
		# Gespeichert wurde in einer anderen Welt (z. B. in einer Spiegelrealität)?
		# Dann dorthin wechseln.
		if _loaded_save and GameState.current_scene != "" and GameState.current_scene != scene_file_path \
				and get_tree().current_scene == self and ResourceLoader.exists(GameState.current_scene):
			get_tree().change_scene_to_file.call_deferred(GameState.current_scene)
			return
	if scene_file_path != "":
		GameState.current_scene = scene_file_path
	# Checkpoint aus einer anderen Welt gilt hier nicht.
	if GameState.has_checkpoint and GameState.checkpoint_scene != "" and GameState.checkpoint_scene != GameState.current_scene:
		GameState.clear_checkpoint()
	# Testversion: genug Startgeld zum Ausprobieren (siehe GameState).
	if GameState.money < GameState.test_start_money:
		GameState.money = GameState.test_start_money


func _ready() -> void:
	ToonStyle.apply_to_tree(self)
	if _loaded_save and GameState.has_checkpoint and GameState.checkpoint_scene in ["", GameState.current_scene]:
		player.global_transform = GameState.checkpoint_transform
		player.rest()
		hud.show_message.call_deferred("Spielstand geladen")
	if GameState.has_pending_spawn:
		GameState.has_pending_spawn = false
		player.global_transform = GameState.pending_spawn
		player.reset_physics_interpolation()
	if GameState.pending_message != "":
		hud.show_message.call_deferred(GameState.pending_message)
		GameState.pending_message = ""
	# Die Arena kennt beide und verbindet sie. (_ready der Arena läuft erst,
	# wenn alle Kinder fertig sind.)
	hud.bind_player(player)

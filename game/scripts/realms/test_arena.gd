extends Node3D
## Testarena: verbindet HUD und Spielfigur. Hier wird später auch ausprobiert,
## was neu dazukommt (Gegner in M2, Ankerspiegel in M3 …).

@onready var player: Player = $Player
@onready var hud: HUD = $HUD


func _ready() -> void:
	# Die Arena kennt beide und verbindet sie. (_ready der Arena läuft erst,
	# wenn alle Kinder fertig sind.)
	hud.bind_player(player)

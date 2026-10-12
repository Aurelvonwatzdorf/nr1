class_name Interactable
extends Area3D
## Etwas, mit dem die Spielfigur per Taste E etwas tun kann
## (Ankerspiegel, Gegenstand aufheben, später NPCs ansprechen …).
##
## Eigene Interaktionen erben hiervon und überschreiben `interact()`.

signal interacted(player: Player)

## Text hinter „E:“ im HUD, z. B. „Rasten“.
@export var prompt: String = "Benutzen"


func _ready() -> void:
	collision_layer = PhysicsLayers.INTERACTABLE
	collision_mask = 0
	monitoring = false
	monitorable = true


## Darf die Figur gerade interagieren?
func can_interact(_player: Player) -> bool:
	return true


func interact(player: Player) -> void:
	interacted.emit(player)

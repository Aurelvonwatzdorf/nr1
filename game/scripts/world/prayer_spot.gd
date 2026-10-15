class_name PrayerSpot
extends Interactable
## Ort zum Beten (Kirche, Moschee, Synagoge) bzw. zur stillen Einkehr (Haus der
## Stille). Alle vier wirken gleich: Die Spiritualität wächst, der Fokus füllt
## sich. Jeder Ort einmal alle paar Minuten.

## Eindeutiger Ort (für die Wartezeit).
@export var spot_id: StringName = &""
## Was die Figur tut (erscheint als Meldung).
@export var action_text: String = "Du betest."
## Spiritualitäts-Erfahrung pro Gebet.
@export var experience: int = 40
## Wartezeit bis zum nächsten Gebet am selben Ort (Sekunden).
@export var cooldown: float = 180.0


func _ready() -> void:
	super._ready()
	var shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 2.2
	shape.shape = sphere
	shape.position = Vector3(0, 1.0, 0)
	add_child(shape)


func interact(player: Player) -> void:
	if get_tree().get_first_node_in_group(&"reality"):
		EventBus.message_requested.emit("Hier ist nichts Heiliges. Nur eine Kopie davon.")
		return
	var wait := GameState.get_prayer_wait(spot_id, cooldown)
	if wait > 0.0:
		EventBus.message_requested.emit("Du hast hier erst vor Kurzem Ruhe gefunden. (noch %d s)" % ceili(wait))
		return
	GameState.mark_prayer(spot_id)
	player.focus.refill()
	var leveled := GameState.add_spirit_experience(experience)
	if leveled:
		EventBus.message_requested.emit("%s\nSpiritualität steigt auf Stufe %d." % [action_text, GameState.stats.spirituality])
	else:
		EventBus.message_requested.emit("%s\nSpiritualität %d/%d" % [action_text, GameState.spirit_experience, GameState.get_spirit_experience_needed()])
	super.interact(player)

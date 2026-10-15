class_name SpiritualPressureSource
extends Node3D
## Ein spirituelles Wesen oder ein heiliger Ort strahlt Druck aus. Wer zu wenig
## Spiritualität hat, hält ihn nicht aus: Das Bild verschwimmt, man wird langsamer
## und verliert Leben. Je näher, desto stärker. Ab `required_spirituality` kein Effekt.

## Ab dieser Spiritualitäts-Stufe hält man den Druck aus.
@export var required_spirituality: int = 3
## Reichweite (Meter). Am Rand schwach, in der Mitte voll.
@export var radius: float = 25.0
@export var source_name: String = "Ein uralter Geist"


func _ready() -> void:
	add_to_group(&"pressure_sources")


## Wie stark der Druck an einer Stelle für eine Spiritualität wirkt (0–1).
func get_intensity(at: Vector3, spirituality: int) -> float:
	var deficit := required_spirituality - spirituality
	if deficit <= 0:
		return 0.0
	var distance := at.distance_to(global_position)
	if distance >= radius:
		return 0.0
	var falloff := 1.0 - distance / radius
	return clampf(falloff * (0.5 + 0.25 * deficit), 0.0, 1.0)


## Spürt man ihn, hält ihm aber stand? (Für Hinweise.)
func is_withstood(at: Vector3, spirituality: int) -> bool:
	return spirituality >= required_spirituality and at.distance_to(global_position) < radius

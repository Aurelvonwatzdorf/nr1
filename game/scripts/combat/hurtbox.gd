class_name Hurtbox
extends Area3D
## Trefferfläche: Hier kann eine Figur getroffen werden.
##
## Gibt Schaden an die HealthComponent weiter, außer die Figur ist gerade
## unverwundbar (z. B. I-Frames der Ausweichrolle). Über `hit_filter` kann der
## Besitzer Treffer abwandeln (Blocken, Parieren).

## Was aus einem Treffer wurde.
enum Result { IGNORED, HIT, BLOCKED, PARRIED }

signal hit_received(hit: HitData, result: Result)
## Ein Treffer prallte an der Unverwundbarkeit ab (z. B. Ausweichen im letzten Moment).
signal hit_evaded(hit: HitData)

@export var health: HealthComponent
## Treffer vom eigenen Team werden ignoriert (z. B. &"player", &"enemy").
@export var team: StringName = &""

## Solange true, prallen Treffer ab.
var invulnerable: bool = false
## Optional: func(hit: HitData) -> Result. Darf hit.damage verändern.
var hit_filter: Callable


func _ready() -> void:
	collision_layer = PhysicsLayers.HURTBOX
	collision_mask = 0
	monitoring = false
	monitorable = true


## Wird von einer Hitbox aufgerufen. Gibt zurück, was aus dem Treffer wurde.
func receive_hit(hit: HitData) -> Result:
	if health and health.is_dead:
		return Result.IGNORED
	if invulnerable:
		hit_evaded.emit(hit)
		return Result.IGNORED
	var result := Result.HIT
	if hit_filter.is_valid():
		result = hit_filter.call(hit)
		if result == Result.IGNORED:
			return result
	if result == Result.PARRIED:
		hit.damage = 0.0
	if health and hit.damage > 0.0:
		health.take_damage(hit.damage)
	hit_received.emit(hit, result)
	if hit.damage > 0.0:
		EventBus.damage_dealt.emit(owner, hit.damage)
	return result

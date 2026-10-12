class_name Hurtbox
extends Area3D
## Trefferfläche: Hier kann eine Figur getroffen werden.
##
## Gibt Schaden an die HealthComponent weiter, außer die Figur ist gerade
## unverwundbar (z. B. I-Frames der Ausweichrolle).

signal hit_received(hit: HitData)

@export var health: HealthComponent

## Solange true, prallen Treffer ab.
var invulnerable: bool = false


func _ready() -> void:
	collision_layer = PhysicsLayers.HURTBOX
	collision_mask = 0
	monitoring = false
	monitorable = true


## Wird von einer Hitbox aufgerufen. Gibt zurück, ob der Treffer zählte.
func receive_hit(hit: HitData) -> bool:
	if invulnerable:
		return false
	if health:
		if health.is_dead:
			return false
		health.take_damage(hit.damage)
	hit_received.emit(hit)
	EventBus.damage_dealt.emit(owner, hit.damage)
	return true

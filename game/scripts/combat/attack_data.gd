class_name AttackData
extends Resource
## Werte eines Angriffs. Liegt als Daten in einer CharacterData (oder später Waffe).
##
## Ablauf eines Angriffs: Ausholen (startup) → Trefferphase (active, Hitbox an)
## → Erholung (recovery). In der Erholung kann man den nächsten Angriff puffern
## oder per Ausweichrolle abbrechen.

@export var display_name: String = "Angriff"
## Name der Animation im AnimationTree (sobald echte Modelle da sind).
@export var animation_name: StringName = &"attack_light"
@export var damage: float = 10.0
@export var stamina_cost: float = 15.0
@export var startup_time: float = 0.15
@export var active_time: float = 0.15
@export var recovery_time: float = 0.3
## Kurzer Vorwärtsschub beim Zuschlagen (Meter pro Sekunde).
@export var lunge_speed: float = 3.0
@export var knockback: float = 2.0


func get_total_time() -> float:
	return startup_time + active_time + recovery_time

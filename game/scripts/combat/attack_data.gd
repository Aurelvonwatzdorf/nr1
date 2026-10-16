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

@export_group("Wucht (schwere Schläge)")
## Wie stark man sich beim Ausholen noch drehen kann (0 = gar nicht, 1 = normal).
@export_range(0.0, 1.0) var windup_turn_factor: float = 0.0
## Wucht: In diesem Teil des Schlags (Anteil 0–1 der Gesamtzeit) unterbrechen
## Treffer bis `poise_max_damage` den Schlag nicht. 0 = keine Wucht.
@export var poise_max_damage: float = 0.0
@export_range(0.0, 1.0) var poise_start: float = 0.3
@export_range(0.0, 1.0) var poise_end: float = 0.8
## Hitstop beim Treffen (Sekunden). 0 = automatisch nach Schaden.
@export var hitstop: float = 0.0
## Kamera-Ruck in Schlagrichtung beim Treffen (0 = keiner).
@export var kick_strength: float = 0.0
## Abbrechen schon beim Ausholen (Ausweichen) kostet so viel Ausdauer extra.
## Unter 0 = beim Ausholen nicht abbrechbar (nur in der Erholung, wie bisher).
@export var startup_cancel_cost: float = -1.0


func get_total_time() -> float:
	return startup_time + active_time + recovery_time


## Hält der Schlag zum Zeitpunkt `time` einen Treffer mit `damage` aus?
func withstands(time: float, damage: float) -> bool:
	if poise_max_damage <= 0.0 or damage > poise_max_damage:
		return false
	var progress := time / get_total_time()
	return progress >= poise_start and progress <= poise_end

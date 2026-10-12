class_name HitStop
## Hitstop: friert das Spiel bei einem Treffer für einen Augenblick fast ein.
## Das lässt Treffer „wuchtig“ wirken. Aufruf: `HitStop.apply(0.06)`.

## Zum Abschalten (z. B. in Tests oder in den Optionen).
static var enabled: bool = true
## Zählt Aufrufe. Nur der jeweils letzte stellt die Zeit wieder her.
static var _generation: int = 0


static func apply(duration: float, time_scale: float = 0.05) -> void:
	if not enabled or duration <= 0.0:
		return
	var tree := Engine.get_main_loop() as SceneTree
	_generation += 1
	var my_generation := _generation
	Engine.time_scale = time_scale
	# Echte Zeit abwarten (ignore_time_scale = true), nicht die verlangsamte.
	await tree.create_timer(duration, true, false, true).timeout
	if my_generation == _generation:
		Engine.time_scale = 1.0

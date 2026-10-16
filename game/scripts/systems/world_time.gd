class_name WorldTime
## Hilfen für das Welt-Tempo (`GameState.world_time_scale`, z. B. Nachhall).
## Gegner und NPCs rechnen ihr `delta` damit um und bewegen sich hierüber.


## move_and_slide() mit verlangsamter Geschwindigkeit. Danach steht die echte
## Geschwindigkeit wieder in `velocity` (inklusive Abbremsen an Wänden/Boden).
static func move_slowed(body: CharacterBody3D, world_speed: float) -> void:
	if world_speed >= 1.0 or world_speed <= 0.0:
		body.move_and_slide()
		return
	body.velocity *= world_speed
	body.move_and_slide()
	body.velocity /= world_speed

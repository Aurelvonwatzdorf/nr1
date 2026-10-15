class_name CitizenSpawner
extends Node3D
## Verteilt Einwohner auf die Viertel der Stadt. Jeder wohnt in einem Viertel
## und läuft meist dort herum. Gleicher Seed = gleiche Leute.

const CITIZEN_SCENE := preload("res://scenes/npcs/citizen.tscn")

@export var city: CityGenerator
## Wie viele Einwohner je Viertel (CityDistrict.id → Anzahl).
@export var counts: Dictionary[StringName, int] = {
	&"corporate": 6, &"market": 8, &"christian": 6, &"muslim": 6,
	&"jewish": 6, &"atheist": 6, &"slum": 8,
}
@export var seed: int = 11


func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	for quarter: StringName in counts:
		var spots: Array[int] = []
		for i in city.waypoints.size():
			if city.waypoint_districts[i] == quarter:
				spots.append(i)
		if spots.is_empty():
			continue
		for n in counts[quarter]:
			var citizen := CITIZEN_SCENE.instantiate() as Citizen
			citizen.setup(StringName("citizen_%s_%d" % [quarter, n]), quarter, rng)
			var point := city.waypoints[spots[rng.randi() % spots.size()]]
			citizen.position = Vector3(point.x + rng.randf_range(-1.0, 1.0), 0.1, point.y + rng.randf_range(-1.0, 1.0))
			add_child(citizen)

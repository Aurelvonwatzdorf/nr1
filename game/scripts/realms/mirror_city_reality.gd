class_name MirrorCityReality
extends RealityLevel
## Die Spiegelrealität der Spiegeljäger: eine Kopie genau des Ortes, an dem man
## gefangen wurde. Dieselben Häuser und Straßen (gleicher Stadt-Seed, gleiche
## freie Stellen), aber leer, farblos und von Nebel begrenzt. Wie sie sich
## anfühlt, hängt vom Viertel ab. Risse, Riss und ein Ankerspiegel liegen auf
## den Straßen in der Nähe. Nach dem Ausbruch wacht man am Fangort wieder auf.

## Radius der Kopie (dahinter Nebel und eine unsichtbare Mauer).
const AREA_RADIUS := 75.0
const CLUE_SCENE := preload("res://scenes/realms/reality_clue.tscn")
const RIFT_SCENE := preload("res://scenes/realms/reality_rift.tscn")
const MIRROR_SCENE := preload("res://scenes/world/anchor_mirror.tscn")
const NPC_SCENE := preload("res://scenes/npcs/npc.tscn")
const TALKER_SCRIPT := preload("res://scripts/npcs/talker.gd")

## Wie sich die Kopie je Viertel anfühlt: Name, Nebelfarbe, Begleiter-Zeilen,
## Sätze der Schattengestalten, Sätze an den Rissen.
const FLAVOR: Dictionary[StringName, Dictionary] = {
	&"corporate": {
		"name": "Der endlose Feierabend",
		"fog": Color(0.55, 0.42, 0.45),
		"intro": ["Die Türme sind still. Keiner geht nach Hause, keiner kommt an.", "Sie haben dich in ein Spiegelbild der Stadt gesperrt. Drück Q."],
		"phantoms": ["Mein Termin war um neun. Welcher Tag ist heute?", "Haben Sie die Zahlen? Wir brauchen die Zahlen."],
		"clues": ["Die Uhr an der Fassade zeigt keine Zeiger. Nur Spiegel.", "Dieselbe Wache, dreimal hintereinander. Dasselbe Gesicht."],
	},
	&"market": {
		"name": "Der Markt ohne Ende",
		"fog": Color(0.6, 0.52, 0.4),
		"intro": ["Der Markt … aber niemand verkauft etwas. Alles ist grau.", "Irgendwo hier ist eine Naht. Drück Q."],
		"phantoms": ["Frisches Obst … frisches Obst … frisches Obst …", "Haben Sie heute schon gekauft? Sie müssen kaufen."],
		"clues": ["Die Früchte sind aus Glas. Hinter dem Glas: nichts.", "Der alte Baum wirft keinen Schatten. Er war nie hier."],
	},
	&"slum": {
		"name": "Die Senke ohne Himmel",
		"fog": Color(0.4, 0.48, 0.42),
		"intro": ["Die Senke … aber der Himmel ist weg.", "Wer hier gefangen ist, wird vergessen. Drück Q, bevor du es auch tust."],
		"phantoms": ["Hier unten sucht uns keiner. Auch nicht im Traum.", "Die Ranken leuchten nicht mehr. Hast du das bemerkt?"],
		"clues": ["Diese Hütte steht doppelt. Einmal echt, einmal gemalt.", "Die Ranken wachsen rückwärts, zurück in die Wände."],
	},
}
## Für die Glaubensviertel und alles andere: eine stille Kopie der Straße.
const DEFAULT_FLAVOR := {
	"name": "Die stille Straße",
	"fog": Color(0.48, 0.52, 0.6),
	"intro": ["Deine Straße, nur ohne Menschen. Und ohne Zeit.", "Die Häuser sind genau kopiert, aber etwas fehlt. Drück Q."],
	"phantoms": ["Ich warte auf jemanden. Ich weiß nicht mehr, auf wen.", "Es ist so ruhig hier. Zu ruhig."],
	"clues": ["Die Fenster sind gemalt. Dahinter ist keine Wand, nur Licht.", "Deine Schritte machen kein Geräusch. Keines."],
}

@onready var city: CityGenerator = $City

var capture_point: Transform3D = Transform3D.IDENTITY
var _flavor: Dictionary = DEFAULT_FLAVOR


func _enter_tree() -> void:
	super._enter_tree()
	_flavor = FLAVOR.get(GameState.capture_district, DEFAULT_FLAVOR)
	reality_name = _flavor["name"]
	var lines: Array[String] = []
	lines.assign(_flavor["intro"])
	intro_lines = lines
	capture_point = GameState.return_transform
	# Spielfigur schon vor ihrem _ready an den Fangort stellen (auch der
	# Wiederbelebungsort richtet sich danach).
	(get_node("Player") as Node3D).transform = capture_point
	# Gleiche freie Stellen wie in der echten Stadt = gleiche Häuser.
	var generator := get_node("City") as CityGenerator
	generator.extra_clear_circles = GameState.capture_clear_circles
	generator.extra_clear_circles.append(Vector3(capture_point.origin.x, capture_point.origin.z, 3.0))


func _ready() -> void:
	_set_mood()
	_place_content()
	_build_fog_wall()
	super._ready()
	player.reset_physics_interpolation()


func _set_mood() -> void:
	var environment := ($WorldEnvironment as WorldEnvironment).environment
	environment.fog_light_color = _flavor["fog"]
	environment.adjustment_enabled = true
	environment.adjustment_saturation = 0.25
	environment.adjustment_contrast = 1.15


## Risse, Realitätsriss, Ankerspiegel und Schattengestalten auf den Straßen in
## der Nähe des Fangorts.
func _place_content() -> void:
	var origin := Vector2(capture_point.origin.x, capture_point.origin.z)
	var nearby := _waypoints_between(origin, 15.0, 55.0)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(origin.round())
	nearby.shuffle()
	var clue_lines: Array = _flavor["clues"]
	var used: Array[Vector2] = []
	clues_needed = 2
	var clues := Node3D.new()
	clues.name = "Clues"
	add_child(clues)
	for i in clues_needed:
		var at := _pick(nearby, used, 18.0)
		var clue := CLUE_SCENE.instantiate() as RealityClue
		clue.companion_line = clue_lines[i % clue_lines.size()]
		clue.position = Vector3(at.x, 0.0, at.y)
		clues.add_child(clue)
	var rift := RIFT_SCENE.instantiate() as RealityRift
	var rift_at := _pick(_waypoints_between(origin, 35.0, 65.0), used, 15.0)
	rift.name = "Rift"
	rift.position = Vector3(rift_at.x, 0.0, rift_at.y)
	add_child(rift)
	var mirror := MIRROR_SCENE.instantiate() as AnchorMirror
	var mirror_at := _pick(_waypoints_between(origin, 6.0, 20.0), used, 4.0)
	mirror.name = "AnchorMirror"
	mirror.position = Vector3(mirror_at.x, 0.0, mirror_at.y)
	add_child(mirror)
	var npcs := Node3D.new()
	npcs.name = "NPCs"
	add_child(npcs)
	var phantom_lines: Array[String] = []
	phantom_lines.assign(_flavor["phantoms"])
	for i in 3:
		var at := _pick(nearby, used, 6.0)
		var phantom := NPC_SCENE.instantiate() as NPC
		phantom.set_script(TALKER_SCRIPT)
		var talker := phantom as Talker
		talker.lines = phantom_lines
		talker.npc_id = StringName("phantom_%d" % i)
		talker.display_name = "Schattengestalt"
		talker.body_color = Color(0.3, 0.3, 0.34)
		talker.position = Vector3(at.x, 0.1, at.y)
		npcs.add_child(talker)


func _waypoints_between(origin: Vector2, near: float, far: float) -> Array[Vector2]:
	var result: Array[Vector2] = []
	for point in city.waypoints:
		var distance := point.distance_to(origin)
		if distance >= near and distance <= far:
			result.append(point)
	if result.is_empty():
		result.append(origin + Vector2(near, 0.0))
	return result


## Ein Punkt aus der Liste, der weit genug von schon benutzten Punkten liegt.
func _pick(candidates: Array[Vector2], used: Array[Vector2], spacing: float) -> Vector2:
	for point in candidates:
		var free := true
		for other in used:
			if point.distance_to(other) < spacing:
				free = false
				break
		if free:
			used.append(point)
			return point
	var fallback := candidates[0]
	used.append(fallback)
	return fallback


## Unsichtbare Mauer im Kreis um den Fangort; dahinter verschluckt der Nebel alles.
func _build_fog_wall() -> void:
	var center := capture_point.origin
	for i in 48:
		var a := TAU * i / 48.0
		var b := TAU * (i + 1) / 48.0
		var p1 := Vector3(cos(a), 0, sin(a)) * AREA_RADIUS + center
		var p2 := Vector3(cos(b), 0, sin(b)) * AREA_RADIUS + center
		var body := StaticBody3D.new()
		body.collision_layer = PhysicsLayers.WORLD
		body.position = (p1 + p2) / 2.0 + Vector3(0, 10, 0)
		body.rotation.y = -atan2(p2.z - p1.z, p2.x - p1.x)
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = Vector3(p1.distance_to(p2) + 1.0, 20.0, 1.0)
		shape.shape = box
		body.add_child(shape)
		add_child(body)

class_name SpiritWorld
extends Level
## Die Geisterwelt (erster Teil, M8.3): eine schwebende Lichtung hinter dem
## Schleier. Hier gibt es einen Ältesten zum Ansprechen und ein Tor zurück in die
## normale Welt (zum Ort, an dem man eingeladen wurde). In M8.4 wird sie größer:
## eigene Wesen, Wege, Orte.

const GROUND_COLOR := Color(0.2, 0.26, 0.34)
const STONE_COLOR := Color(0.5, 0.52, 0.6)
const BARK_COLOR := Color(0.78, 0.8, 0.86)
const SPIRIT_COLOR := Color(0.65, 0.92, 1.0)
const BLOSSOM_COLOR := Color(0.85, 0.6, 1.0)
const GATE_COLOR := Color(0.55, 0.12, 0.1)
const GROUND_RADIUS := 40.0
## Hierhin geht es, wenn kein Rückkehrort gespeichert ist.
const FALLBACK_SCENE := "res://scenes/levels/santo_santiago.tscn"

## Nach dem Zurückkehren die Welt wechseln? (Im Test aus.)
var change_scene_on_return: bool = true
var _elder_next: int = 0


func _enter_tree() -> void:
	super._enter_tree()
	_build_world()


func _ready() -> void:
	super._ready()
	GameState.set_story_flag(&"visited_spirit_world")
	_register_map()


## Zurück in die normale Welt, an den Ort der Einladung.
func return_to_world() -> void:
	var target := FALLBACK_SCENE
	if GameState.return_scene != "":
		target = GameState.return_scene
		GameState.has_pending_spawn = true
		GameState.pending_spawn = GameState.return_transform
		GameState.return_scene = ""
	GameState.pending_message = "Du stehst wieder vor dem Schrein. Die Zeit läuft, als wäre nichts geschehen."
	if change_scene_on_return:
		get_tree().change_scene_to_file.call_deferred(target)


## Sätze des Ältesten (für Tahirou zum Teil andere).
func get_elder_lines() -> Array[String]:
	var is_tahirou := GameState.selected_character != null and GameState.selected_character.id == &"tahirou"
	var lines: Array[String] = [
		"Willkommen hinter dem Schleier. Hier sieht man, was in deiner Welt verborgen bleibt.",
		"Wir rufen nur selten einen Menschen. Wer nicht eingeladen ist, braucht ein Ritual in den alten Bergtempeln. Der Weg dorthin ist schwer.",
		"Weit hinten, wo das Licht am hellsten ist, wohnt einer, dessen Druck selbst wir kaum ertragen. Stör ihn nicht ohne guten Grund.",
		"Das Tor hinter dir führt zurück in deine Welt. Dort ist kaum ein Augenblick vergangen.",
	]
	if is_tahirou:
		lines[0] = "Sohn der Rabenhüter. Deine Raben waren oft hier, lange bevor du geboren wurdest. Willkommen."
	return lines


func _on_elder_interacted(_player: Player) -> void:
	var dialogue := get_tree().get_first_node_in_group(&"dialogue_box") as DialogueBox
	if dialogue == null:
		return
	var lines := get_elder_lines()
	await dialogue.ask("Der Älteste", lines[_elder_next % lines.size()])
	_elder_next += 1
	dialogue.finish()


func _on_gate_interacted(_player: Player) -> void:
	return_to_world()


# --- Aufbau ---------------------------------------------------------------

func _build_world() -> void:
	var root := Node3D.new()
	root.name = "Glade"
	add_child(root)
	# Schwebende Insel als Boden.
	_cylinder(root, Vector3(0, -0.5, 0), GROUND_RADIUS, 1.0, GROUND_COLOR, true)
	_cylinder(root, Vector3(0, -3.0, 0), GROUND_RADIUS * 0.8, 4.0, STONE_COLOR.darkened(0.4), false)
	# Steinkreis um den Ältesten.
	for i in 8:
		var angle := TAU * float(i) / 8.0
		_box(root, Vector3(sin(angle) * 9.0, 1.2, -20.0 + cos(angle) * 9.0), Vector3(0.9, 2.4, 0.9), STONE_COLOR, true)
	# Geisterbäume entlang des Weges und am Rand.
	var rng := RandomNumberGenerator.new()
	rng.seed = 8031
	for i in 18:
		var angle := TAU * float(i) / 18.0 + rng.randf_range(-0.1, 0.1)
		var distance := rng.randf_range(24.0, 34.0)
		_spirit_tree(root, Vector3(sin(angle) * distance, 0.0, cos(angle) * distance), rng.randf_range(0.8, 1.4))
	for side: float in [-1.0, 1.0]:
		for i in 3:
			_spirit_tree(root, Vector3(side * 6.0, 0.0, 2.0 - i * 7.0), 0.8)
	# Schwebende Lichter.
	for i in 30:
		var at := Vector3(rng.randf_range(-30, 30), rng.randf_range(2.0, 9.0), rng.randf_range(-35, 25))
		_orb(root, at, rng.randf_range(0.15, 0.4), SPIRIT_COLOR if i % 3 else BLOSSOM_COLOR)
	# Kleinere schwebende Inseln in der Ferne.
	for i in 6:
		var angle := TAU * float(i) / 6.0 + 0.3
		_cylinder(root, Vector3(sin(angle) * 70.0, rng.randf_range(-6.0, 12.0), cos(angle) * 70.0), rng.randf_range(6.0, 12.0), 2.0, GROUND_COLOR.lightened(0.1), false)
	_build_elder(root, Vector3(0, 0, -20))
	_build_gate(root, Vector3(0, 0, 12))


func _build_elder(root: Node3D, at: Vector3) -> void:
	var elder := Node3D.new()
	elder.name = "Elder"
	elder.position = at
	root.add_child(elder)
	var material := _spirit_material(SPIRIT_COLOR, 0.6)
	var body := MeshInstance3D.new()
	var capsule := CapsuleMesh.new()
	capsule.radius = 0.8
	capsule.height = 4.0
	body.mesh = capsule
	body.material_override = material
	body.position = Vector3(0, 2.4, 0)
	elder.add_child(body)
	_orb(elder, Vector3(0, 4.9, 0), 0.6, SPIRIT_COLOR)
	var label := Label3D.new()
	label.text = "Der Älteste"
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.font_size = 48
	label.outline_size = 8
	label.modulate = SPIRIT_COLOR
	label.position = Vector3(0, 6.0, 0)
	elder.add_child(label)
	var talk := _interactable("Mit dem Ältesten sprechen", 3.5)
	talk.name = "TalkArea"
	talk.interacted.connect(_on_elder_interacted)
	elder.add_child(talk)
	var light := OmniLight3D.new()
	light.light_color = SPIRIT_COLOR
	light.light_energy = 2.0
	light.omni_range = 14.0
	light.position = Vector3(0, 3.0, 0)
	elder.add_child(light)
	var marker := MapMarker.new()
	marker.kind = MapMarker.Kind.SPIRIT_SHRINE
	marker.label = "Der Älteste"
	elder.add_child(marker)


func _build_gate(root: Node3D, at: Vector3) -> void:
	var gate := Node3D.new()
	gate.name = "ReturnGate"
	gate.position = at
	root.add_child(gate)
	_box(gate, Vector3(-2.2, 2.25, 0), Vector3(0.4, 4.5, 0.4), GATE_COLOR, true)
	_box(gate, Vector3(2.2, 2.25, 0), Vector3(0.4, 4.5, 0.4), GATE_COLOR, true)
	_box(gate, Vector3(0, 4.6, 0), Vector3(5.6, 0.4, 0.5), GATE_COLOR, false)
	var veil := MeshInstance3D.new()
	var plane := QuadMesh.new()
	plane.size = Vector2(4.0, 4.2)
	veil.mesh = plane
	veil.material_override = _spirit_material(SPIRIT_COLOR, 0.35)
	veil.position = Vector3(0, 2.2, 0)
	gate.add_child(veil)
	var use := _interactable("In deine Welt zurückkehren", 2.5)
	use.name = "UseArea"
	use.position = Vector3(0, 0, -1.0)
	use.interacted.connect(_on_gate_interacted)
	gate.add_child(use)
	var marker := MapMarker.new()
	marker.kind = MapMarker.Kind.SPIRIT_SHRINE
	marker.label = "Tor zurück"
	gate.add_child(marker)


func _register_map() -> void:
	var map_data := get_node_or_null("MapData") as MapData
	if map_data == null:
		return
	var points := PackedVector2Array()
	for i in 32:
		var angle := TAU * float(i) / 32.0
		points.append(Vector2(sin(angle), cos(angle)) * GROUND_RADIUS)
	map_data.add_polygon(points, GROUND_COLOR.lightened(0.15), "Lichtung der Geister", Vector2(0, 0))


# --- Bausteine -------------------------------------------------------------

func _spirit_material(color: Color, alpha: float) -> StandardMaterial3D:
	var material := ToonStyle.make(color, false)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = Color(color, alpha)
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = 1.6
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	return material


func _interactable(prompt_text: String, radius: float) -> Interactable:
	var area := Interactable.new()
	area.prompt = prompt_text
	var shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = radius
	shape.shape = sphere
	shape.position = Vector3(0, 1.2, 0)
	area.add_child(shape)
	return area


func _spirit_tree(root: Node3D, at: Vector3, scale_factor: float) -> void:
	var height := 7.0 * scale_factor
	_cylinder(root, at + Vector3(0, height / 2.0, 0), 0.35 * scale_factor, height, BARK_COLOR, true)
	var crown_color := BLOSSOM_COLOR if int(absf(at.x + at.z)) % 2 == 0 else SPIRIT_COLOR
	_orb(root, at + Vector3(0, height + 0.8, 0), 2.2 * scale_factor, crown_color)
	_orb(root, at + Vector3(1.2, height - 0.4, 0.6) * Vector3(scale_factor, 1, scale_factor), 1.3 * scale_factor, crown_color)


func _orb(root: Node3D, at: Vector3, radius: float, color: Color) -> void:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	var material := ToonStyle.make(color, false)
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = 1.4
	instance.material_override = material
	instance.position = at
	root.add_child(instance)


func _cylinder(root: Node3D, center: Vector3, radius: float, height: float, color: Color, solid: bool) -> void:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.material_override = ToonStyle.make(color)
	instance.position = center
	if solid:
		var body := StaticBody3D.new()
		body.collision_layer = PhysicsLayers.WORLD
		body.collision_mask = 0
		var shape := CollisionShape3D.new()
		var cylinder := CylinderShape3D.new()
		cylinder.radius = radius
		cylinder.height = height
		shape.shape = cylinder
		body.add_child(shape)
		instance.add_child(body)
	root.add_child(instance)


func _box(root: Node3D, center: Vector3, size: Vector3, color: Color, solid: bool) -> void:
	var mesh := BoxMesh.new()
	mesh.size = size
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.material_override = ToonStyle.make(color)
	instance.position = center
	if solid:
		var body := StaticBody3D.new()
		body.collision_layer = PhysicsLayers.WORLD
		body.collision_mask = 0
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = size
		shape.shape = box
		body.add_child(shape)
		instance.add_child(body)
	root.add_child(instance)

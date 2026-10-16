class_name TravelGate
extends Interactable
## Tor in eine andere Welt (z. B. Südtor von Santo Santiago ↔ Kontinent).
## E wechselt die Szene; man erscheint dort an `target_position`.

@export_file("*.tscn") var target_scene: String = ""
@export var target_position: Vector3 = Vector3.ZERO
## Blickrichtung beim Ankommen (Grad um die Hochachse, 0 = Norden/-z).
@export var target_yaw_degrees: float = 0.0
@export var arrival_message: String = ""
## Einen Torbogen als Bild bauen?
@export var build_arch: bool = true
## Szene wirklich wechseln? (Im Test aus.)
var change_scene: bool = true


func _ready() -> void:
	super._ready()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(6.0, 4.0, 4.0)
	shape.shape = box
	shape.position = Vector3(0, 2.0, 0)
	add_child(shape)
	if build_arch:
		_build_arch()


func interact(player: Player) -> void:
	GameState.has_pending_spawn = true
	GameState.pending_spawn = Transform3D(Basis(Vector3.UP, deg_to_rad(target_yaw_degrees)), target_position)
	GameState.pending_message = arrival_message
	super.interact(player)
	if change_scene and target_scene != "":
		get_tree().change_scene_to_file.call_deferred(target_scene)


func _build_arch() -> void:
	var stone := ToonStyle.make(Color(0.35, 0.36, 0.42))
	var glow := ToonStyle.make(Color(0.6, 0.8, 1.0), false)
	glow.emission_enabled = true
	glow.emission = Color(0.5, 0.75, 1.0)
	for side: float in [-1.0, 1.0]:
		_part(BoxMesh, Vector3(1.2, 7.0, 1.6), Vector3(side * 3.6, 3.5, 0), stone, true)
	_part(BoxMesh, Vector3(8.4, 1.4, 1.8), Vector3(0, 7.4, 0), stone, true)
	_part(BoxMesh, Vector3(6.0, 0.25, 0.3), Vector3(0, 6.5, 0.8), glow, false)


func _part(_mesh_type: Variant, size: Vector3, at: Vector3, material: Material, solid: bool) -> void:
	var mesh := BoxMesh.new()
	mesh.size = size
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.material_override = material
	instance.position = at
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
	add_child(instance)

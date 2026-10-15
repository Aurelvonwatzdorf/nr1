class_name PlayerAnimator
extends Node
## Einzige Verbindung zwischen Spiellogik und Animation.
##
## Die Zustände sagen nur „spiele Angriff“ oder „spiele Ausweichen“. Ist ein
## AnimationTree zugewiesen (echtes Modell), wird dessen State Machine benutzt
## („parameters/playback“, Knotennamen = Animationsnamen). Ohne AnimationTree
## gibt es einfache Platzhalter-Bewegungen, damit man im Test etwas sieht.

## Später zuweisen, sobald ein Modell mit Animationen da ist.
@export var animation_tree: AnimationTree
## Der Knoten, der bei Platzhalter-Animationen gestaucht und gedreht wird.
@export var visual_root: Node3D
## Drehpunkt der Platzhalter-Waffe.
@export var weapon_pivot: Node3D
@export var body_mesh: MeshInstance3D

var _tween: Tween


## Spielt eine benannte Animation (idle, move, dodge …).
func play(animation_name: StringName, duration: float = 0.3) -> void:
	if _travel(animation_name):
		return
	match animation_name:
		&"dodge":
			_placeholder_tween(Vector3(1.15, 0.6, 1.15), duration)
		&"jump":
			_placeholder_tween(Vector3(0.9, 1.15, 0.9), duration)
		&"use_item":
			_placeholder_tween(Vector3(0.95, 0.9, 0.95), duration)
		&"hurt":
			_placeholder_tween(Vector3(0.85, 1.1, 0.85), duration)
		&"death":
			_kill_tween()
			_tween = create_tween()
			_tween.tween_property(visual_root, "rotation:x", deg_to_rad(-90.0), 0.5)


## Doppelsprung: kurzer Lichtring unter den Füßen (Schub der Cyberbeine).
func play_double_jump() -> void:
	if visual_root == null:
		return
	var ring := MeshInstance3D.new()
	var mesh := TorusMesh.new()
	mesh.inner_radius = 0.35
	mesh.outer_radius = 0.5
	ring.mesh = mesh
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color(0.4, 0.9, 1.0)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ring.material_override = material
	var parent: Node = visual_root.get_tree().current_scene
	if parent == null:
		parent = visual_root
	parent.add_child(ring)
	ring.global_position = visual_root.global_position
	var tween := ring.create_tween().set_parallel()
	tween.tween_property(ring, "scale", Vector3(2.5, 1.0, 2.5), 0.3)
	tween.tween_property(material, "albedo_color:a", 0.0, 0.3)
	tween.chain().tween_callback(ring.queue_free)


## Schuss: kurzer Leuchtstrahl vom Lauf bis zum Einschlag, Mündungsblitz.
func play_shot(from: Vector3, to: Vector3) -> void:
	var length := from.distance_to(to)
	if length < 0.1 or visual_root == null:
		return
	var beam := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.04, 0.04, length)
	beam.mesh = mesh
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color(1.0, 0.85, 0.5)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	beam.material_override = material
	var parent: Node = visual_root.get_tree().current_scene
	if parent == null:
		parent = visual_root
	parent.add_child(beam)
	beam.global_position = from.lerp(to, 0.5)
	beam.look_at(to, Vector3.UP if absf((to - from).normalized().y) < 0.99 else Vector3.RIGHT)
	var tween := beam.create_tween()
	tween.tween_property(material, "albedo_color:a", 0.0, 0.12)
	tween.tween_callback(beam.queue_free)


## Spielt einen Angriff. Die Platzhalter-Waffe schwingt während der Trefferphase.
func play_attack(attack: AttackData) -> void:
	if _travel(attack.animation_name) or weapon_pivot == null:
		return
	_kill_tween()
	_tween = create_tween()
	weapon_pivot.rotation = Vector3(0.0, deg_to_rad(70.0), 0.0)
	_tween.tween_interval(attack.startup_time)
	_tween.tween_property(weapon_pivot, "rotation:y", deg_to_rad(-70.0), attack.active_time)
	_tween.tween_property(weapon_pivot, "rotation:y", 0.0, attack.recovery_time)


## Deckung: Platzhalter-Waffe quer vor den Körper halten.
func set_blocking(active: bool) -> void:
	if _travel(&"block" if active else &"idle") or weapon_pivot == null:
		return
	_kill_tween()
	weapon_pivot.rotation = Vector3(0.0, deg_to_rad(80.0), deg_to_rad(70.0)) if active else Vector3.ZERO


## Platzhalter-Effekt für Aurels Feuerwelle: wachsender, verblassender Ring.
func play_wildfire(radius: float) -> void:
	if visual_root == null:
		return
	var ring := MeshInstance3D.new()
	var mesh := TorusMesh.new()
	mesh.inner_radius = 0.8
	mesh.outer_radius = 1.0
	ring.mesh = mesh
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = Color(1.0, 0.5, 0.1, 0.9)
	ring.material_override = material
	visual_root.get_parent().add_child(ring)
	ring.top_level = true
	ring.global_position = visual_root.global_position + Vector3.UP * 0.3
	var tween := ring.create_tween().set_parallel()
	tween.tween_property(ring, "scale", Vector3.ONE * radius, 0.35)
	tween.tween_property(material, "albedo_color:a", 0.0, 0.35)
	tween.chain().tween_callback(ring.queue_free)


## Platzhalter-Effekt für Tahirous Rabenschwarm: schwarze Vögel fliegen zum Ziel.
func play_raven_swarm(target_point: Vector3) -> void:
	if visual_root == null:
		return
	var start := visual_root.global_position + Vector3.UP * 2.2
	for i in 7:
		var bird := MeshInstance3D.new()
		var mesh := PrismMesh.new()
		mesh.size = Vector3(0.35, 0.12, 0.25)
		bird.mesh = mesh
		var material := StandardMaterial3D.new()
		material.albedo_color = Color(0.05, 0.04, 0.08)
		material.emission_enabled = true
		material.emission = Color(0.35, 0.25, 0.6)
		bird.material_override = material
		visual_root.get_parent().add_child(bird)
		bird.top_level = true
		var offset := Vector3(randf_range(-1.2, 1.2), randf_range(0.0, 1.0), randf_range(-1.2, 1.2))
		bird.global_position = start + offset
		var tween := bird.create_tween()
		tween.tween_property(bird, "global_position", target_point + offset * 0.3, 0.35 + i * 0.03)
		tween.tween_property(bird, "global_position", target_point + offset * 2.0 + Vector3.UP * 3.0, 0.5)
		tween.tween_callback(bird.queue_free)


## Grundhaltung wiederherstellen (z. B. nach dem Respawn).
func reset_pose() -> void:
	_kill_tween()
	if visual_root:
		visual_root.rotation = Vector3.ZERO
	set_invulnerable_visual(false)


## Laufgeschwindigkeit 0 (stehen) bis 1 (sprinten) für den Blend-Space.
func set_locomotion_blend(ratio: float) -> void:
	if animation_tree:
		animation_tree.set(&"parameters/locomotion/blend_position", ratio)


## Zeigt die Unverwundbarkeit (I-Frames) beim Testen: Figur wird halbdurchsichtig.
func set_invulnerable_visual(active: bool) -> void:
	if body_mesh == null:
		return
	var material := body_mesh.material_override as StandardMaterial3D
	if material:
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA if active else BaseMaterial3D.TRANSPARENCY_DISABLED
		material.albedo_color.a = 0.35 if active else 1.0
		# Durchsichtig ohne Umriss, sonst sähe man nur noch den Umriss.
		material.next_pass = null if active else ToonStyle.make_outline()


func _travel(animation_name: StringName) -> bool:
	if animation_tree == null:
		return false
	var playback := animation_tree.get(&"parameters/playback") as AnimationNodeStateMachinePlayback
	if playback == null:
		return false
	playback.travel(animation_name)
	return true


func _placeholder_tween(squash: Vector3, duration: float) -> void:
	if visual_root == null:
		return
	_kill_tween()
	_tween = create_tween()
	_tween.tween_property(visual_root, "scale", squash, duration * 0.3)
	_tween.tween_property(visual_root, "scale", Vector3.ONE, duration * 0.7)


func _kill_tween() -> void:
	if _tween and _tween.is_valid():
		_tween.kill()
	_tween = null
	if visual_root:
		visual_root.scale = Vector3.ONE
	if weapon_pivot:
		weapon_pivot.rotation = Vector3.ZERO

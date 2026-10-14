class_name BloodEffect
## Blut bei Treffern: Spritzer in Schlagrichtung und ein Fleck auf dem Boden,
## der nach einer Weile verblasst. Aufruf: `BloodEffect.spawn(ziel, richtung, stärke)`.

const BLOOD_COLOR := Color(0.5, 0.02, 0.03)


## `target`: getroffene Figur. `strength`: 1 = normaler Treffer, 3 = Hinrichtung.
static func spawn(target: Node3D, direction: Vector3, strength: float = 1.0) -> void:
	var world := target.get_parent()
	if world == null:
		return
	var hit_point := target.global_position + Vector3.UP * 1.2
	_spawn_spray(world, hit_point, direction, strength)
	_spawn_stain(world, target.global_position, strength)


static func _spawn_spray(world: Node, at: Vector3, direction: Vector3, strength: float) -> void:
	var particles := CPUParticles3D.new()
	particles.one_shot = true
	particles.explosiveness = 0.9
	particles.amount = int(20 * strength)
	particles.lifetime = 0.7
	var mesh := SphereMesh.new()
	mesh.radius = 0.035
	mesh.height = 0.07
	var material := StandardMaterial3D.new()
	material.albedo_color = BLOOD_COLOR
	material.roughness = 0.3
	mesh.material = material
	particles.mesh = mesh
	particles.direction = (direction + Vector3.UP * 0.5).normalized()
	particles.spread = 35.0 + 10.0 * strength
	particles.initial_velocity_min = 2.0
	particles.initial_velocity_max = 4.0 + strength
	particles.gravity = Vector3(0.0, -9.8, 0.0)
	particles.scale_amount_min = 0.6
	particles.scale_amount_max = 1.2 + 0.3 * strength
	world.add_child(particles)
	particles.global_position = at
	particles.emitting = true
	particles.finished.connect(particles.queue_free)


static func _spawn_stain(world: Node, at: Vector3, strength: float) -> void:
	var stain := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.25 + 0.15 * strength + randf() * 0.15
	mesh.bottom_radius = mesh.top_radius
	mesh.height = 0.005
	var material := StandardMaterial3D.new()
	material.albedo_color = BLOOD_COLOR.darkened(0.3)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.roughness = 0.2
	mesh.material = material
	stain.mesh = mesh
	world.add_child(stain)
	stain.global_position = at + Vector3(randf_range(-0.3, 0.3), 0.01, randf_range(-0.3, 0.3))
	var tween := stain.create_tween()
	tween.tween_interval(10.0)
	tween.tween_property(material, "albedo_color:a", 0.0, 3.0)
	tween.tween_callback(stain.queue_free)

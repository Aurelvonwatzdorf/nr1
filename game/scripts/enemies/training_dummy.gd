class_name TrainingDummy
extends StaticBody3D
## Trainingspuppe: nimmt Schaden, zeigt Schadenszahlen und steht nach dem
## „Besiegen“ wieder auf. Greift nicht an (echte Gegner kommen in M2).

@export var respawn_delay: float = 2.0
@export var base_color: Color = Color(0.75, 0.6, 0.4)

@onready var health: HealthComponent = $HealthComponent
@onready var hurtbox: Hurtbox = $Hurtbox
@onready var body_mesh: MeshInstance3D = $Body
@onready var health_label: Label3D = $HealthLabel

var _material: StandardMaterial3D
var _flash_tween: Tween


func _ready() -> void:
	add_to_group(&"lock_on_targets")
	_material = StandardMaterial3D.new()
	_material.albedo_color = base_color
	body_mesh.material_override = _material
	hurtbox.hit_received.connect(_on_hit_received)
	health.value_changed.connect(_on_health_changed)
	health.died.connect(_on_died)
	_update_label()


## Für Lock-on: Die Puppe ist immer anvisierbar.
func is_targetable() -> bool:
	return true


## Für Lock-on: Punkt, auf den gezielt wird.
func get_lock_on_point() -> Vector3:
	return global_position + Vector3.UP * 1.3


func _on_hit_received(hit: HitData, _result: Hurtbox.Result) -> void:
	_spawn_damage_number(hit.damage)
	_flash()


func _on_health_changed(_current: float, _maximum: float) -> void:
	_update_label()


func _on_died() -> void:
	health_label.text = "Besiegt!"
	await get_tree().create_timer(respawn_delay).timeout
	health.revive()


func _update_label() -> void:
	health_label.text = "%d / %d" % [ceili(health.current), ceili(health.max_value)]


func _flash() -> void:
	if _flash_tween and _flash_tween.is_valid():
		_flash_tween.kill()
	_material.albedo_color = Color.WHITE
	_flash_tween = create_tween()
	_flash_tween.tween_property(_material, "albedo_color", base_color, 0.2)


func _spawn_damage_number(amount: float) -> void:
	var label := Label3D.new()
	label.text = str(roundi(amount))
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.font_size = 64
	label.outline_size = 12
	label.modulate = Color(1.0, 0.85, 0.3)
	add_child(label)
	label.position = Vector3(randf_range(-0.3, 0.3), 2.2, 0.0)
	var tween := label.create_tween().set_parallel()
	tween.tween_property(label, "position:y", label.position.y + 0.8, 0.8)
	tween.tween_property(label, "modulate:a", 0.0, 0.8).set_delay(0.3)
	tween.chain().tween_callback(label.queue_free)

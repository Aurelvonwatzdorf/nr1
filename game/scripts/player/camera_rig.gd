class_name CameraRig
extends Node3D
## Third-Person-Kamera: folgt der Figur, dreht mit Maus oder rechtem Stick.
##
## Aufbau: CameraRig (Drehung links/rechts) → PitchPivot (hoch/runter)
## → SpringArm3D (zieht die Kamera bei Wänden heran) → Camera3D.
## Das Rig ist „top_level“, damit es sich nicht mit der Figur mitdreht.

@export var mouse_sensitivity: float = 0.0025
@export var gamepad_sensitivity: float = 3.0
@export_range(-89.0, 0.0) var min_pitch_degrees: float = -65.0
@export_range(0.0, 89.0) var max_pitch_degrees: float = 35.0
## Wie schnell die Kamera beim Lock-on zum Ziel schwenkt.
@export var lock_on_turn_speed: float = 8.0
## Maximale Verschiebung beim Kamerawackeln (Meter).
@export var max_shake_offset: float = 0.35
## Wie schnell das Wackeln abklingt (pro Sekunde).
@export var shake_decay: float = 2.5
## Augenhöhe über dem Fuß der Figur.
@export var height_offset: float = 1.5
@export var follow_speed: float = 14.0

@onready var pitch_pivot: Node3D = $PitchPivot
@onready var spring_arm: SpringArm3D = $PitchPivot/SpringArm3D
@onready var camera: Camera3D = $PitchPivot/SpringArm3D/Camera3D

## true = Maus ist gefangen und steuert die Kamera (Spiel läuft).
var is_capturing: bool = false

var _target: Node3D
## Angevisiertes Ziel (Lock-on) oder null.
var _lock_target: Node3D
var _yaw: float = 0.0
var _pitch: float = deg_to_rad(-20.0)
## Aktuelle Wackelstärke 0 bis 1 („Trauma“).
var _trauma: float = 0.0
var _shake_time: float = 0.0


func _ready() -> void:
	_target = get_parent() as Node3D
	top_level = true
	# Das Rig wird in _process bewegt, daher keine Physik-Interpolation für es selbst.
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	if _target is CollisionObject3D:
		spring_arm.add_excluded_object((_target as CollisionObject3D).get_rid())
	_yaw = _target.global_rotation.y
	global_position = _target.global_position + Vector3.UP * height_offset
	set_capturing(true)
	EventBus.camera_shake_requested.connect(shake)
	EventBus.menu_state_changed.connect(func(is_open: bool) -> void: set_capturing(not is_open))


func _unhandled_input(event: InputEvent) -> void:
	if is_capturing and event is InputEventMouseMotion and _lock_target == null:
		var motion := event as InputEventMouseMotion
		_yaw -= motion.relative.x * mouse_sensitivity
		_pitch -= motion.relative.y * mouse_sensitivity
	elif not is_capturing and not GameState.is_menu_open() and event is InputEventMouseButton and event.is_pressed():
		set_capturing(true)
		get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	if _lock_target and is_instance_valid(_lock_target):
		# Kamera schwenkt automatisch hinter die Figur, Blick aufs Ziel.
		var to_target := _lock_target.global_position - global_position
		var desired_yaw := atan2(-to_target.x, -to_target.z)
		var blend := 1.0 - exp(-lock_on_turn_speed * delta)
		_yaw = lerp_angle(_yaw, desired_yaw, blend)
		_pitch = lerpf(_pitch, deg_to_rad(-18.0), blend)
	elif is_capturing:
		var look := Input.get_vector(&"look_left", &"look_right", &"look_up", &"look_down")
		_yaw -= look.x * gamepad_sensitivity * delta
		_pitch -= look.y * gamepad_sensitivity * delta
	_pitch = clampf(_pitch, deg_to_rad(min_pitch_degrees), deg_to_rad(max_pitch_degrees))
	rotation = Vector3(0.0, _yaw, 0.0)
	pitch_pivot.rotation = Vector3(_pitch, 0.0, 0.0)

	var target_position := _target.get_global_transform_interpolated().origin + Vector3.UP * height_offset
	global_position = global_position.lerp(target_position, 1.0 - exp(-follow_speed * delta))
	_update_shake(delta)


## Kamera sofort auf einen Punkt richten (z. B. für Screenshots und Szenen).
func look_at_point(point: Vector3, pitch_degrees: float = -12.0) -> void:
	var to_point := point - _target.global_position
	_yaw = atan2(-to_point.x, -to_point.z)
	_pitch = deg_to_rad(pitch_degrees)
	global_position = _target.global_position + Vector3.UP * height_offset


## Kamera wackeln lassen. Mehrere Aufrufe addieren sich (max. 1).
func shake(strength: float) -> void:
	_trauma = minf(_trauma + strength, 1.0)


func _update_shake(delta: float) -> void:
	# Echte Zeit nutzen, damit das Wackeln auch während des Hitstops läuft.
	var real_delta := delta / maxf(Engine.time_scale, 0.001)
	_trauma = maxf(_trauma - shake_decay * real_delta, 0.0)
	_shake_time += real_delta
	var amount := _trauma * _trauma * max_shake_offset
	camera.h_offset = sin(_shake_time * 47.0) * amount
	camera.v_offset = cos(_shake_time * 39.0) * amount


## Drehung links/rechts als Basis, um Eingaben relativ zur Kamera umzurechnen.
func get_yaw_basis() -> Basis:
	return Basis(Vector3.UP, _yaw)


func set_lock_target(target: Node3D) -> void:
	_lock_target = target


func set_capturing(value: bool) -> void:
	is_capturing = value
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if value else Input.MOUSE_MODE_VISIBLE

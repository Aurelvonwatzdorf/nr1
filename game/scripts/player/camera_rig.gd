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
## Augenhöhe über dem Fuß der Figur.
@export var height_offset: float = 1.5
@export var follow_speed: float = 14.0

@onready var pitch_pivot: Node3D = $PitchPivot
@onready var spring_arm: SpringArm3D = $PitchPivot/SpringArm3D
@onready var camera: Camera3D = $PitchPivot/SpringArm3D/Camera3D

## true = Maus ist gefangen und steuert die Kamera (Spiel läuft).
var is_capturing: bool = false

var _target: Node3D
var _yaw: float = 0.0
var _pitch: float = deg_to_rad(-20.0)


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


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"menu"):
		set_capturing(not is_capturing)
		get_viewport().set_input_as_handled()
	elif is_capturing and event is InputEventMouseMotion:
		var motion := event as InputEventMouseMotion
		_yaw -= motion.relative.x * mouse_sensitivity
		_pitch -= motion.relative.y * mouse_sensitivity
	elif not is_capturing and event is InputEventMouseButton and event.is_pressed():
		set_capturing(true)
		get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	if is_capturing:
		var look := Input.get_vector(&"look_left", &"look_right", &"look_up", &"look_down")
		_yaw -= look.x * gamepad_sensitivity * delta
		_pitch -= look.y * gamepad_sensitivity * delta
	_pitch = clampf(_pitch, deg_to_rad(min_pitch_degrees), deg_to_rad(max_pitch_degrees))
	rotation = Vector3(0.0, _yaw, 0.0)
	pitch_pivot.rotation = Vector3(_pitch, 0.0, 0.0)

	var target_position := _target.get_global_transform_interpolated().origin + Vector3.UP * height_offset
	global_position = global_position.lerp(target_position, 1.0 - exp(-follow_speed * delta))


## Drehung links/rechts als Basis, um Eingaben relativ zur Kamera umzurechnen.
func get_yaw_basis() -> Basis:
	return Basis(Vector3.UP, _yaw)


func set_capturing(value: bool) -> void:
	is_capturing = value
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if value else Input.MOUSE_MODE_VISIBLE

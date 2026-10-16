class_name RealitySightOverlay
extends CanvasLayer
## Bildschirm-Effekt des Realitätsblicks (liegt unter dem HUD).

const FADE_TIME := 0.35

var _rect: ColorRect
var _material: ShaderMaterial
var _tween: Tween
var _time_stop: float = 0.0
var _afterimage: float = 0.0


func _ready() -> void:
	layer = 1
	_material = ShaderMaterial.new()
	_material.shader = preload("res://assets/materials/reality_sight.gdshader")
	_material.set_shader_parameter(&"strength", 0.0)
	_material.set_shader_parameter(&"distortion", 0.0)
	_material.set_shader_parameter(&"pressure", 0.0)
	_material.set_shader_parameter(&"time_stop", 0.0)
	_material.set_shader_parameter(&"afterimage", 0.0)
	_rect = ColorRect.new()
	_rect.material = _material
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_rect)
	visible = false
	EventBus.reality_sight_changed.connect(_on_reality_sight_changed)


## Verankerung in Spiegelrealitäten verzerrt das Bild, auch ohne Realitätsblick.
func _process(delta: float) -> void:
	var reality := get_tree().get_first_node_in_group(&"reality") as RealityLevel
	var distortion := reality.get_fade() if reality else 0.0
	# Angehaltene Zeit blendet weich ein und aus.
	_time_stop = move_toward(_time_stop, 1.0 if GameState.time_stopped else 0.0, delta * 2.0)
	_material.set_shader_parameter(&"distortion", distortion)
	_material.set_shader_parameter(&"pressure", GameState.spiritual_pressure)
	_material.set_shader_parameter(&"time_stop", _time_stop)
	# Nachhall: schnell ein, weich aus.
	var slowed := GameState.world_time_scale < 1.0
	_afterimage = move_toward(_afterimage, 1.0 if slowed else 0.0, delta * (6.0 if slowed else 2.0))
	_material.set_shader_parameter(&"afterimage", _afterimage)
	if distortion > 0.0 or GameState.spiritual_pressure > 0.0 or _time_stop > 0.0 or _afterimage > 0.0:
		visible = true
	elif not GameState.reality_sight_active and (_tween == null or not _tween.is_valid()):
		visible = false


func _on_reality_sight_changed(active: bool) -> void:
	if _tween and _tween.is_valid():
		_tween.kill()
	if active:
		visible = true
	var start: float = _material.get_shader_parameter(&"strength") if _material.get_shader_parameter(&"strength") != null else 0.0
	_tween = create_tween()
	_tween.tween_method(func(value: float) -> void: _material.set_shader_parameter(&"strength", value),
		start, 1.0 if active else 0.0, FADE_TIME)
	if not active:
		_tween.tween_callback(func() -> void: visible = false)

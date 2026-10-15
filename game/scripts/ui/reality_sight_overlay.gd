class_name RealitySightOverlay
extends CanvasLayer
## Bildschirm-Effekt des Realitätsblicks (liegt unter dem HUD).

const FADE_TIME := 0.35

var _rect: ColorRect
var _material: ShaderMaterial
var _tween: Tween


func _ready() -> void:
	layer = 1
	_material = ShaderMaterial.new()
	_material.shader = preload("res://assets/materials/reality_sight.gdshader")
	_material.set_shader_parameter(&"strength", 0.0)
	_material.set_shader_parameter(&"distortion", 0.0)
	_material.set_shader_parameter(&"pressure", 0.0)
	_rect = ColorRect.new()
	_rect.material = _material
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_rect)
	visible = false
	EventBus.reality_sight_changed.connect(_on_reality_sight_changed)


## Verankerung in Spiegelrealitäten verzerrt das Bild, auch ohne Realitätsblick.
func _process(_delta: float) -> void:
	var reality := get_tree().get_first_node_in_group(&"reality") as RealityLevel
	var distortion := reality.get_fade() if reality else 0.0
	_material.set_shader_parameter(&"distortion", distortion)
	_material.set_shader_parameter(&"pressure", GameState.spiritual_pressure)
	if distortion > 0.0 or GameState.spiritual_pressure > 0.0:
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

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
	_rect = ColorRect.new()
	_rect.material = _material
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_rect)
	visible = false
	EventBus.reality_sight_changed.connect(_on_reality_sight_changed)


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

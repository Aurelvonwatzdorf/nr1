extends Node
## Grafikstufen „Akku / Ausgewogen / Schön“ (Mechanik-Studie 2, Detailstufen).
## Gilt pro Gerät, nicht pro Spielstand: gespeichert in `user://einstellungen.cfg`.
## Standard: Handy und Browser „Akku“, Mac „Schön“.
## Levels rufen `apply_to_scene(self)` in `Level._ready()` auf; beim Umschalten
## wird die laufende Szene neu angepasst. F3 zeigt Bildrate und Zeichenaufrufe.

signal tier_changed(tier: int)

enum Tier { BATTERY, BALANCED, BEAUTIFUL }

const SETTINGS_PATH := "user://einstellungen.cfg"
const NAMES: Array[String] = ["Akku", "Ausgewogen", "Schön"]
## Je Stufe: Renderauflösung, Bildrate (0 = frei), höchste Schattenweite,
## Umgebungsverdeckung (SSAO), Faktor für Detail-Sichtweiten.
const PRESETS: Array[Dictionary] = [
	{"scale": 0.7, "max_fps": 30, "shadow_distance": 25.0, "ssao": false, "detail": 0.6},
	{"scale": 0.85, "max_fps": 60, "shadow_distance": 50.0, "ssao": false, "detail": 0.8},
	{"scale": 1.0, "max_fps": 0, "shadow_distance": 1000.0, "ssao": true, "detail": 1.0},
]

var tier: int = Tier.BEAUTIFUL
var _stats_label: Label


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	tier = default_tier()
	var config := ConfigFile.new()
	if config.load(SETTINGS_PATH) == OK:
		tier = clampi(int(config.get_value("grafik", "stufe", tier)), 0, PRESETS.size() - 1)
	_apply_global()


static func default_tier() -> int:
	if OS.has_feature("mobile") or OS.has_feature("web"):
		return Tier.BATTERY
	return Tier.BEAUTIFUL


func get_tier_name() -> String:
	return NAMES[tier]


func set_tier(value: int, save: bool = true) -> void:
	tier = clampi(value, 0, PRESETS.size() - 1)
	if save:
		var config := ConfigFile.new()
		config.load(SETTINGS_PATH)
		config.set_value("grafik", "stufe", tier)
		config.save(SETTINGS_PATH)
	_apply_global()
	var scene := get_tree().current_scene
	if scene:
		apply_to_scene(scene)
	tier_changed.emit(tier)


## Nächste Stufe (für einen Knopf, der durchschaltet).
func cycle_tier() -> void:
	set_tier((tier + 1) % PRESETS.size())


func get_detail_factor() -> float:
	return PRESETS[tier]["detail"]


## Passt Schatten, Umgebung und Sichtweiten aller Knoten unter `root` an. Die
## Originalwerte merkt sich jeder Knoten (Meta), damit man zurückschalten kann.
func apply_to_scene(root: Node) -> void:
	var preset: Dictionary = PRESETS[tier]
	_apply_node(root, preset)


func _apply_node(node: Node, preset: Dictionary) -> void:
	var light := node as DirectionalLight3D
	if light:
		if not light.has_meta(&"base_shadow_distance"):
			light.set_meta(&"base_shadow_distance", light.directional_shadow_max_distance)
		light.directional_shadow_max_distance = minf(float(light.get_meta(&"base_shadow_distance")), preset["shadow_distance"])
	var world := node as WorldEnvironment
	if world and world.environment:
		var environment := world.environment
		if not world.has_meta(&"base_ssao"):
			world.set_meta(&"base_ssao", environment.ssao_enabled)
		environment.ssao_enabled = bool(world.get_meta(&"base_ssao")) and preset["ssao"]
	var geometry := node as GeometryInstance3D
	if geometry and (geometry.visibility_range_end > 0.0 or geometry.has_meta(&"base_range_end")):
		if not geometry.has_meta(&"base_range_end"):
			geometry.set_meta(&"base_range_end", geometry.visibility_range_end)
		geometry.visibility_range_end = float(geometry.get_meta(&"base_range_end")) * preset["detail"]
	for child: Node in node.get_children():
		_apply_node(child, preset)


func _apply_global() -> void:
	var preset: Dictionary = PRESETS[tier]
	Engine.max_fps = preset["max_fps"]
	var viewport := get_viewport()
	if viewport:
		viewport.scaling_3d_scale = preset["scale"]


## F3: kleine Anzeige mit Bildrate, Zeichenaufrufen und Stufe (zum Messen).
func _unhandled_key_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key and key.pressed and not key.echo and key.keycode == KEY_F3:
		_toggle_stats()


func _toggle_stats() -> void:
	if _stats_label:
		_stats_label.get_parent().queue_free()
		_stats_label = null
		return
	var layer := CanvasLayer.new()
	layer.layer = 100
	_stats_label = Label.new()
	_stats_label.position = Vector2(8, 8)
	_stats_label.add_theme_color_override(&"font_shadow_color", Color.BLACK)
	layer.add_child(_stats_label)
	add_child(layer)


func _process(_delta: float) -> void:
	if _stats_label == null:
		return
	_stats_label.text = "%d Bilder/s · %d Zeichenaufrufe · %d Objekte · Grafik: %s" % [
		Engine.get_frames_per_second(),
		RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME),
		RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_OBJECTS_IN_FRAME),
		get_tier_name()]

class_name RealityLayerObject
extends Node3D
## Etwas, das nur in einer Ebene existiert: entweder nur in der wahren Welt
## (sichtbar und begehbar nur mit Realitätsblick, z. B. versteckte Wege, Risse)
## oder nur in der Illusion (verschwindet beim Realitätsblick, z. B. falsche Wände).
## Einfach als Elternknoten um Meshes und Kollisionen legen.

enum Layer {
	TRUE_WORLD, ## nur mit Realitätsblick da
	ILLUSION, ## nur ohne Realitätsblick da
}

@export var exists_in: Layer = Layer.TRUE_WORLD

var _collision_layers: Dictionary[CollisionObject3D, int] = {}


func _ready() -> void:
	add_to_group(&"reality_layer_objects")
	for node in find_children("*", "CollisionObject3D", true, false):
		var body := node as CollisionObject3D
		_collision_layers[body] = body.collision_layer
	EventBus.reality_sight_changed.connect(_apply)
	_apply(GameState.reality_sight_active)


## Ist das Ding gerade da (sichtbar und anfassbar)?
func is_present() -> bool:
	return visible


func _apply(sight_active: bool) -> void:
	var present := sight_active == (exists_in == Layer.TRUE_WORLD)
	visible = present
	for body in _collision_layers:
		if is_instance_valid(body):
			body.collision_layer = _collision_layers[body] if present else 0
			if body is Area3D:
				(body as Area3D).set_deferred(&"monitorable", present)

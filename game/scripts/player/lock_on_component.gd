class_name LockOnComponent
extends Node
## Anvisieren (Lock-on): wählt das beste Ziel vor der Kamera.
##
## Ziele sind Knoten in der Gruppe „lock_on_targets“ mit den Methoden
## `is_targetable() -> bool` und `get_lock_on_point() -> Vector3`.

signal target_changed(target: Node3D)

## Maximale Entfernung zum Anvisieren.
@export var max_distance: float = 15.0
## Ab dieser Entfernung wird das Ziel automatisch losgelassen.
@export var break_distance: float = 22.0
## Markierung über dem Ziel (wird an den Zielpunkt gesetzt).
@export var marker: Node3D

var target: Node3D


func _ready() -> void:
	if marker:
		marker.top_level = true
		marker.visible = false


func _physics_process(_delta: float) -> void:
	if target == null:
		return
	if not _is_valid(target) or _origin().distance_to(target.global_position) > break_distance:
		set_target(null)


func _process(_delta: float) -> void:
	if marker and target:
		marker.global_position = target.call(&"get_lock_on_point")


## Anvisieren ein/aus. `view_direction` ist die Blickrichtung der Kamera.
func toggle(view_direction: Vector3) -> void:
	if target:
		set_target(null)
	else:
		set_target(find_best_target(view_direction))


## Bestes Ziel: nah und möglichst mittig im Blick.
func find_best_target(view_direction: Vector3) -> Node3D:
	var best: Node3D = null
	var best_score := -INF
	var flat_view := Vector3(view_direction.x, 0.0, view_direction.z).normalized()
	for node: Node in get_tree().get_nodes_in_group(&"lock_on_targets"):
		var candidate := node as Node3D
		if candidate == null or not _is_valid(candidate):
			continue
		var offset := candidate.global_position - _origin()
		offset.y = 0.0
		var distance := offset.length()
		if distance > max_distance or distance < 0.01:
			continue
		var alignment := flat_view.dot(offset / distance)
		if alignment < 0.0:
			continue  # Hinter der Kamera
		var score := alignment * 2.0 - distance / max_distance
		if score > best_score:
			best_score = score
			best = candidate
	return best


func set_target(new_target: Node3D) -> void:
	if new_target == target:
		return
	target = new_target
	if marker:
		marker.visible = target != null
	target_changed.emit(target)


func _is_valid(node: Node3D) -> bool:
	return is_instance_valid(node) and node.is_inside_tree() and bool(node.call(&"is_targetable"))


func _origin() -> Vector3:
	return (owner as Node3D).global_position

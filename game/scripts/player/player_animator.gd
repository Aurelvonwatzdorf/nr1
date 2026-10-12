class_name PlayerAnimator
extends Node
## Einzige Verbindung zwischen Spiellogik und Animation.
##
## Die Zustände sagen nur „spiele Angriff“ oder „spiele Ausweichen“. Ist ein
## AnimationTree zugewiesen (echtes Modell), wird dessen State Machine benutzt
## („parameters/playback“, Knotennamen = Animationsnamen). Ohne AnimationTree
## gibt es einfache Platzhalter-Bewegungen, damit man im Test etwas sieht.

## Später zuweisen, sobald ein Modell mit Animationen da ist.
@export var animation_tree: AnimationTree
## Der Knoten, der bei Platzhalter-Animationen gestaucht und gedreht wird.
@export var visual_root: Node3D
## Drehpunkt der Platzhalter-Waffe.
@export var weapon_pivot: Node3D
@export var body_mesh: MeshInstance3D

var _tween: Tween


## Spielt eine benannte Animation (idle, move, dodge …).
func play(animation_name: StringName, duration: float = 0.3) -> void:
	if _travel(animation_name):
		return
	match animation_name:
		&"dodge":
			_placeholder_tween(Vector3(1.15, 0.6, 1.15), duration)
		&"hurt":
			_placeholder_tween(Vector3(0.85, 1.1, 0.85), duration)
		&"death":
			_kill_tween()
			_tween = create_tween()
			_tween.tween_property(visual_root, "rotation:x", deg_to_rad(-90.0), 0.5)


## Spielt einen Angriff. Die Platzhalter-Waffe schwingt während der Trefferphase.
func play_attack(attack: AttackData) -> void:
	if _travel(attack.animation_name) or weapon_pivot == null:
		return
	_kill_tween()
	_tween = create_tween()
	weapon_pivot.rotation = Vector3(0.0, deg_to_rad(70.0), 0.0)
	_tween.tween_interval(attack.startup_time)
	_tween.tween_property(weapon_pivot, "rotation:y", deg_to_rad(-70.0), attack.active_time)
	_tween.tween_property(weapon_pivot, "rotation:y", 0.0, attack.recovery_time)


## Deckung: Platzhalter-Waffe quer vor den Körper halten.
func set_blocking(active: bool) -> void:
	if _travel(&"block" if active else &"idle") or weapon_pivot == null:
		return
	_kill_tween()
	weapon_pivot.rotation = Vector3(0.0, deg_to_rad(80.0), deg_to_rad(70.0)) if active else Vector3.ZERO


## Grundhaltung wiederherstellen (z. B. nach dem Respawn).
func reset_pose() -> void:
	_kill_tween()
	if visual_root:
		visual_root.rotation = Vector3.ZERO
	set_invulnerable_visual(false)


## Laufgeschwindigkeit 0 (stehen) bis 1 (sprinten) für den Blend-Space.
func set_locomotion_blend(ratio: float) -> void:
	if animation_tree:
		animation_tree.set(&"parameters/locomotion/blend_position", ratio)


## Zeigt die Unverwundbarkeit (I-Frames) beim Testen: Figur wird halbdurchsichtig.
func set_invulnerable_visual(active: bool) -> void:
	if body_mesh == null:
		return
	var material := body_mesh.material_override as StandardMaterial3D
	if material:
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA if active else BaseMaterial3D.TRANSPARENCY_DISABLED
		material.albedo_color.a = 0.35 if active else 1.0


func _travel(animation_name: StringName) -> bool:
	if animation_tree == null:
		return false
	var playback := animation_tree.get(&"parameters/playback") as AnimationNodeStateMachinePlayback
	if playback == null:
		return false
	playback.travel(animation_name)
	return true


func _placeholder_tween(squash: Vector3, duration: float) -> void:
	if visual_root == null:
		return
	_kill_tween()
	_tween = create_tween()
	_tween.tween_property(visual_root, "scale", squash, duration * 0.3)
	_tween.tween_property(visual_root, "scale", Vector3.ONE, duration * 0.7)


func _kill_tween() -> void:
	if _tween and _tween.is_valid():
		_tween.kill()
	_tween = null
	if visual_root:
		visual_root.scale = Vector3.ONE
	if weapon_pivot:
		weapon_pivot.rotation = Vector3.ZERO

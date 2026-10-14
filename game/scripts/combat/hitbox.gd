class_name Hitbox
extends Area3D
## Angriffsfläche: trifft Hurtboxes, solange sie aktiv ist.
##
## Jede Hurtbox wird pro Schlag höchstens einmal getroffen. Die eigene Hurtbox
## (gleicher Szenen-Besitzer) und Hurtboxes des eigenen Teams werden ignoriert.

## Ein Treffer kam an. `result` sagt, ob er geblockt oder pariert wurde.
signal hit_landed(hurtbox: Hurtbox, hit: HitData, result: Hurtbox.Result)

## Team des Angreifers (z. B. &"player", &"enemy").
@export var team: StringName = &""

## Optional: func(ziel: Hurtbox, schaden: float) -> float. Passt den Schaden je
## Ziel an (z. B. Bonus gegen bestimmte Gegner).
var damage_modifier: Callable

var _active: bool = false
var _damage: float = 0.0
var _knockback: float = 0.0
var _already_hit: Array[Hurtbox] = []


func _ready() -> void:
	collision_layer = PhysicsLayers.HITBOX
	collision_mask = PhysicsLayers.HURTBOX
	monitoring = true
	monitorable = false


func activate(damage: float, knockback: float) -> void:
	_active = true
	_damage = damage
	_knockback = knockback
	_already_hit.clear()


func deactivate() -> void:
	_active = false


func is_active() -> bool:
	return _active


func _physics_process(_delta: float) -> void:
	if not _active:
		return
	for area in get_overlapping_areas():
		var hurtbox := area as Hurtbox
		if hurtbox == null or hurtbox.owner == owner or _already_hit.has(hurtbox):
			continue
		if team != &"" and hurtbox.team == team:
			continue
		_already_hit.append(hurtbox)
		var hit := HitData.new()
		hit.damage = damage_modifier.call(hurtbox, _damage) if damage_modifier.is_valid() else _damage
		hit.knockback = _knockback
		hit.source = owner as Node3D
		var to_target := hurtbox.global_position - global_position
		to_target.y = 0.0
		hit.direction = to_target.normalized()
		var result := hurtbox.receive_hit(hit)
		if result != Hurtbox.Result.IGNORED:
			hit_landed.emit(hurtbox, hit, result)

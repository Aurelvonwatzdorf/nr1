class_name Enemy
extends CharacterBody3D
## Ein Gegner mit eigener State Machine. Werte kommen aus EnemyData.
##
## Gegner gehören zur Gruppe „enemies“ (für Zurücksetzen nach dem Tod der
## Spielfigur) und „lock_on_targets“ (anvisierbar).

signal died(enemy: Enemy)

@export var data: EnemyData

@onready var health: HealthComponent = $HealthComponent
@onready var hurtbox: Hurtbox = $Hurtbox
@onready var hitbox: Hitbox = $Model/AttackHitbox
@onready var model: Node3D = $Model
@onready var body_mesh: MeshInstance3D = $Model/Body
@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var health_label: Label3D = $HealthLabel
@onready var state_machine: StateMachine = $StateMachine

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
## Wohin der Gegner zurückkehrt und wo er nach einem Reset steht.
var home_transform: Transform3D
## Zeit bis zum nächsten erlaubten Angriff.
var attack_cooldown_left: float = 0.0
## Der zuletzt erlittene Treffer (für Rückstoß im Taumel-Zustand).
var last_hit: HitData

var _material: StandardMaterial3D
var _pose_tween: Tween
## Brennen (z. B. durch Aurels „Glutnarben“): Schaden pro Sekunde und Restzeit.
var _burn_damage_per_second: float = 0.0
var _burn_time_left: float = 0.0
## Rabenmal (Tahirous Schwarm): so viele Treffer machen erhöhten Schaden.
var raven_mark_hits_left: int = 0
var raven_mark_multiplier: float = 2.0


func _ready() -> void:
	assert(data != null, "Enemy braucht EnemyData (Inspector).")
	add_to_group(&"enemies")
	add_to_group(&"lock_on_targets")
	home_transform = global_transform
	health.set_max_value(data.max_health)
	_material = StandardMaterial3D.new()
	_material.albedo_color = data.placeholder_color
	body_mesh.material_override = _material
	hurtbox.hit_received.connect(_on_hit_received)
	hitbox.hit_landed.connect(_on_hit_landed)
	health.died.connect(_on_died)
	health.value_changed.connect(func(_c: float, _m: float) -> void: _update_health_label())
	_update_health_label()
	state_machine.start(self)


func _physics_process(delta: float) -> void:
	# Nachhall: Die Welt läuft langsamer, die Spielfigur nicht.
	var world_speed := GameState.world_time_scale
	delta *= world_speed
	attack_cooldown_left = maxf(attack_cooldown_left - delta, 0.0)
	_update_burn(delta)
	if not is_on_floor():
		velocity.y -= gravity * delta
	state_machine.physics_update(delta)
	WorldTime.move_slowed(self, world_speed)


## Die Spielfigur, falls sie lebt und da ist.
func get_player() -> Player:
	var player := get_tree().get_first_node_in_group(&"player") as Player
	if player == null or player.health.is_dead:
		return null
	return player


func distance_to_node(node: Node3D) -> float:
	var offset := node.global_position - global_position
	offset.y = 0.0
	return offset.length()


func direction_to_node(node: Node3D) -> Vector3:
	var offset := node.global_position - global_position
	offset.y = 0.0
	return offset.normalized()


func accelerate_to(target_velocity: Vector3, delta: float) -> void:
	var horizontal := Vector3(velocity.x, 0.0, velocity.z)
	horizontal = horizontal.move_toward(target_velocity, data.acceleration * delta)
	velocity.x = horizontal.x
	velocity.z = horizontal.z


func turn_towards(direction: Vector3, delta: float) -> void:
	if direction.length_squared() < 0.0001:
		return
	var target_angle := atan2(-direction.x, -direction.z)
	rotation.y = lerp_angle(rotation.y, target_angle, 1.0 - exp(-data.turn_speed * delta))


## Sichtweite, angepasst an Fähigkeiten der Spielfigur (z. B. „Firmenausweis“).
func get_detection_radius() -> float:
	if data.faction == &"corporate" and GameState.has_skill(&"aurel_badge"):
		return data.detection_radius * 0.6
	return data.detection_radius


## Rabenschwarm: unterbricht den Gegner und markiert eine Schwachstelle.
func hit_by_raven_swarm(stun_time: float, mark_hits: int, mark_multiplier: float) -> void:
	if health.is_dead:
		return
	raven_mark_hits_left = mark_hits
	raven_mark_multiplier = mark_multiplier
	health_label.visible = true
	state_machine.transition_to(&"stagger", {"time": stun_time, "parried": true})


## Verbraucht das Rabenmal für einen Treffer und gibt den Schadens-Faktor zurück.
func consume_raven_mark() -> float:
	if raven_mark_hits_left <= 0:
		return 1.0
	raven_mark_hits_left -= 1
	return raven_mark_multiplier


func is_defenseless() -> bool:
	return state_machine.get_current_state_name() == &"stagger"


## Zögern (z. B. aus Furcht): nächster Angriff kommt später.
func hesitate(seconds: float) -> void:
	attack_cooldown_left += seconds


## In Brand setzen: Schaden über Zeit, ohne Taumeln.
func apply_burn(damage_per_second: float, duration: float) -> void:
	_burn_damage_per_second = damage_per_second
	_burn_time_left = duration


func is_burning() -> bool:
	return _burn_time_left > 0.0


func _update_burn(delta: float) -> void:
	if _burn_time_left <= 0.0:
		return
	_burn_time_left -= delta
	if health.is_dead:
		_burn_time_left = 0.0
	else:
		health.take_damage(_burn_damage_per_second * delta)
	_material.emission_enabled = _burn_time_left > 0.0
	_material.emission = Color(1.0, 0.45, 0.1)
	_material.emission_energy_multiplier = 1.2


func get_facing_direction() -> Vector3:
	return -global_basis.z


## Für Lock-on: Kann man ihn gerade anvisieren?
func is_targetable() -> bool:
	return not health.is_dead


## Für Lock-on: Punkt, auf den gezielt wird (Brusthöhe).
func get_lock_on_point() -> Vector3:
	return global_position + Vector3.UP * 1.2


## Warnfarbe beim Ausholen, damit man den Angriff kommen sieht.
func set_telegraph(active: bool) -> void:
	_material.emission_enabled = active
	_material.emission = Color(1.0, 0.25, 0.1)
	_material.emission_energy_multiplier = 1.5


## Kurzes Aufblitzen bei einem Treffer.
func flash() -> void:
	_material.albedo_color = Color.WHITE
	create_tween().tween_property(_material, "albedo_color", data.placeholder_color, 0.15)


## Platzhalter-Animation: Körper kippt um `lean_degrees` und richtet sich wieder auf.
func play_lean(lean_degrees: float, recover_time: float) -> void:
	_kill_pose_tween()
	_pose_tween = create_tween()
	_pose_tween.tween_property(model, "rotation:x", deg_to_rad(lean_degrees), 0.08)
	_pose_tween.tween_property(model, "rotation:x", 0.0, recover_time)


## Platzhalter-Animation: umfallen und nach kurzer Zeit verschwinden.
func play_death() -> void:
	_kill_pose_tween()
	_pose_tween = create_tween()
	_pose_tween.tween_property(model, "rotation:x", deg_to_rad(-90.0), 0.4)
	_pose_tween.tween_interval(1.5)
	_pose_tween.tween_callback(hide)


## Zurück an den Startpunkt, volles Leben (nach dem Tod der Spielfigur).
func reset_enemy() -> void:
	global_transform = home_transform
	velocity = Vector3.ZERO
	attack_cooldown_left = 0.0
	_burn_time_left = 0.0
	raven_mark_hits_left = 0
	health.revive()
	visible = true
	collision_shape.set_deferred(&"disabled", false)
	hurtbox.set_deferred(&"monitorable", true)
	_kill_pose_tween()
	model.rotation = Vector3.ZERO
	set_telegraph(false)
	state_machine.transition_to(&"idle")


func _on_hit_received(hit: HitData, result: Hurtbox.Result) -> void:
	if health.is_dead or result == Hurtbox.Result.IGNORED:
		return
	last_hit = hit
	if hit.source is Player:
		EventBus.enemy_hit_by_player.emit(self)
	flash()
	if result == Hurtbox.Result.HIT:
		BloodEffect.spawn(self, hit.direction, clampf(hit.damage / 15.0, 0.6, 2.0))
	state_machine.transition_to(&"stagger", {"time": data.stagger_time})


func _on_hit_landed(_hurtbox: Hurtbox, _hit: HitData, result: Hurtbox.Result) -> void:
	if result == Hurtbox.Result.PARRIED and not health.is_dead:
		var stun := data.parried_stun_time
		if data.faction == &"corporate" and GameState.has_skill(&"aurel_takeover"):
			stun *= 2.0
		state_machine.transition_to(&"stagger", {"time": stun, "parried": true})


func _on_died() -> void:
	GameState.memories += data.memories_reward
	GameState.money += data.money_reward
	state_machine.transition_to(&"dead")
	died.emit(self)
	EventBus.enemy_killed.emit(self)


func _kill_pose_tween() -> void:
	if _pose_tween and _pose_tween.is_valid():
		_pose_tween.kill()


func _update_health_label() -> void:
	var ratio := health.get_ratio()
	var filled := roundi(ratio * 10.0)
	var mark := "  ◆ Rabenmal" if raven_mark_hits_left > 0 else ""
	health_label.text = "%s%s\n%s" % [data.display_name, mark, "■".repeat(filled) + "□".repeat(10 - filled)]
	health_label.visible = not health.is_dead and ratio < 1.0

class_name Player
extends CharacterBody3D
## Die Spielfigur. Gleicher Controller für Aurel und Tahirou.
##
## Dieses Skript hält nur Gemeinsames (Bewegungshilfen, Daten anwenden). Was die
## Figur gerade tut, entscheiden die Zustände unter „StateMachine“.

## Wird genutzt, wenn GameState keine Figur gewählt hat (z. B. beim Testen).
@export var character_data: CharacterData

@onready var health: HealthComponent = $HealthComponent
@onready var stamina: StaminaComponent = $StaminaComponent
@onready var focus: FocusComponent = $FocusComponent
@onready var hurtbox: Hurtbox = $Hurtbox
@onready var hitbox: Hitbox = $Model/WeaponHitbox
@onready var model: Node3D = $Model
@onready var body_mesh: MeshInstance3D = $Model/Body
@onready var animator: PlayerAnimator = $PlayerAnimator
@onready var state_machine: StateMachine = $StateMachine
@onready var camera_rig: CameraRig = $CameraRig
@onready var lock_on: LockOnComponent = $LockOnComponent
@onready var interaction_detector: InteractionDetector = $InteractionDetector

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
## Der zuletzt erlittene Treffer (für Rückstoß im Getroffen-Zustand).
var last_hit: HitData


func _ready() -> void:
	if GameState.selected_character:
		character_data = GameState.selected_character
	assert(character_data != null, "Player braucht eine CharacterData (Inspector).")
	add_to_group(&"player")
	_apply_character_data()
	GameState.stats.changed.connect(_apply_stats)
	health.died.connect(_on_died)
	hurtbox.hit_received.connect(_on_hit_received)
	lock_on.target_changed.connect(camera_rig.set_lock_target)
	hitbox.hit_landed.connect(_on_hit_landed)
	hurtbox.hit_filter = _filter_incoming_hit
	state_machine.start(self)
	EventBus.player_spawned.emit(self)


func _physics_process(delta: float) -> void:
	if is_input_enabled() and Input.is_action_just_pressed(&"lock_on"):
		lock_on.toggle(-camera_rig.camera.global_basis.z)
	if is_input_enabled() and Input.is_action_just_pressed(&"interact") and can_interact():
		interaction_detector.current.interact(self)
	state_machine.physics_update(delta)
	move_and_slide()


## Darf der Spieler gerade steuern? (Nein, solange das Menü offen ist.)
func is_input_enabled() -> bool:
	return camera_rig.is_capturing and not health.is_dead and not GameState.is_menu_open()


## Eingaberichtung relativ zur Kamera, flach auf dem Boden (Länge 0 bis 1).
func get_move_direction() -> Vector3:
	if not is_input_enabled():
		return Vector3.ZERO
	var input := Input.get_vector(&"move_left", &"move_right", &"move_forward", &"move_back")
	var direction := camera_rig.get_yaw_basis() * Vector3(input.x, 0.0, input.y)
	return direction.limit_length(1.0)


## Angevisiertes Ziel oder null.
func get_lock_target() -> Node3D:
	return lock_on.target


## Richtung zum angevisierten Ziel (flach) oder Vector3.ZERO ohne Ziel.
func get_direction_to_lock_target() -> Vector3:
	if lock_on.target == null:
		return Vector3.ZERO
	var offset := lock_on.target.global_position - global_position
	offset.y = 0.0
	return offset.normalized()


## Blickrichtung der Figur (Godot: vorne ist -Z).
func get_facing_direction() -> Vector3:
	return -global_basis.z


func apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta


## Beschleunigt die waagerechte Geschwindigkeit sanft auf das Ziel.
func accelerate_to(target_velocity: Vector3, delta: float) -> void:
	var horizontal := Vector3(velocity.x, 0.0, velocity.z)
	horizontal = horizontal.move_toward(target_velocity, character_data.acceleration * delta)
	velocity.x = horizontal.x
	velocity.z = horizontal.z


## Dreht die Figur sanft in eine Richtung.
func turn_towards(direction: Vector3, delta: float) -> void:
	if direction.length_squared() < 0.0001:
		return
	var target_angle := atan2(-direction.x, -direction.z)
	rotation.y = lerp_angle(rotation.y, target_angle, 1.0 - exp(-character_data.turn_speed * delta))


## Dreht die Figur sofort (z. B. beim Start eines Angriffs).
func snap_towards(direction: Vector3) -> void:
	if direction.length_squared() > 0.0001:
		rotation.y = atan2(-direction.x, -direction.z)


## Schaden-Faktor aus den Stats (Stärke).
func get_damage_multiplier() -> float:
	return GameState.stats.get_damage_multiplier()


## Tempo-Faktor aus den Stats (Schnelligkeit).
func get_speed_multiplier() -> float:
	return GameState.stats.get_speed_multiplier()


func _apply_character_data() -> void:
	var data := character_data
	stamina.regen_delay = data.stamina_regen_delay
	_apply_stats(true)
	if data.model_scene:
		# Später: echtes Modell statt Kapsel einsetzen.
		body_mesh.visible = false
		model.add_child(data.model_scene.instantiate())
	else:
		var material := StandardMaterial3D.new()
		material.albedo_color = data.placeholder_color
		body_mesh.material_override = material


## Interagieren nur im Stehen oder Gehen, nicht mitten im Angriff.
func can_interact() -> bool:
	return interaction_detector.current != null \
		and state_machine.get_current_state_name() in [&"idle", &"move"]


## Rasten (Ankerspiegel): alle Werte voll.
func rest() -> void:
	health.refill()
	stamina.refill()
	focus.refill()


## Wiederbeleben an einer Stelle (Checkpoint): volle Werte, Zustand Idle.
func respawn(at: Transform3D) -> void:
	global_transform = at
	velocity = Vector3.ZERO
	health.revive()
	stamina.refill()
	animator.reset_pose()
	state_machine.transition_to(&"idle")
	reset_physics_interpolation()
	EventBus.player_respawned.emit(self)


## Entscheidet über Blocken und Parieren, bevor der Schaden ankommt.
func _filter_incoming_hit(hit: HitData) -> Hurtbox.Result:
	var block_state := state_machine.current_state as PlayerBlockState
	if block_state == null:
		return Hurtbox.Result.HIT
	# Nur Treffer von vorne lassen sich abwehren.
	if get_facing_direction().dot(-hit.direction) < 0.2:
		return Hurtbox.Result.HIT
	if block_state.is_in_parry_window():
		return Hurtbox.Result.PARRIED
	var data := character_data
	var absorbed := hit.damage * data.block_damage_reduction
	hit.damage -= absorbed
	stamina.consume(absorbed * data.block_stamina_per_damage)
	return Hurtbox.Result.BLOCKED


## Rechnet Leben, Ausdauer und Fokus aus Grundwerten und Stats neu aus.
func _apply_stats(refill: bool = false) -> void:
	var data := character_data
	var stats := GameState.stats
	health.set_max_value(stats.get_max_health(data.max_health), refill)
	stamina.set_max_value(stats.get_max_stamina(data.max_stamina), refill)
	stamina.regen_per_second = stats.get_stamina_regen(data.stamina_regen_per_second)
	focus.set_max_value(stats.get_max_focus(data.max_focus), refill)


func _on_hit_received(hit: HitData, result: Hurtbox.Result) -> void:
	if health.is_dead:
		return
	if result == Hurtbox.Result.PARRIED:
		EventBus.camera_shake_requested.emit(0.3)
		HitStop.apply(0.12)
		return
	if result == Hurtbox.Result.BLOCKED:
		EventBus.camera_shake_requested.emit(0.2)
		if stamina.is_empty():
			# Deckung gebrochen: lange wehrlos.
			last_hit = hit
			state_machine.transition_to(&"hurt", {"time": character_data.guard_break_time})
		else:
			var push := hit.direction * hit.knockback * 0.6
			velocity.x = push.x
			velocity.z = push.z
		return
	if result != Hurtbox.Result.HIT:
		return
	last_hit = hit
	EventBus.camera_shake_requested.emit(0.5)
	HitStop.apply(0.08)
	state_machine.transition_to(&"hurt")


## Eigener Treffer: kurzer Hitstop und leichtes Wackeln, stärker bei viel Schaden.
func _on_hit_landed(_target: Hurtbox, hit: HitData, _result: Hurtbox.Result) -> void:
	var heavy := hit.damage >= 20.0
	HitStop.apply(0.09 if heavy else 0.05)
	EventBus.camera_shake_requested.emit(0.3 if heavy else 0.15)


func _on_died() -> void:
	lock_on.set_target(null)
	state_machine.transition_to(&"dead")
	EventBus.player_died.emit(self)

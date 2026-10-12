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

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
## Der zuletzt erlittene Treffer (für Rückstoß im Getroffen-Zustand).
var last_hit: HitData


func _ready() -> void:
	if GameState.selected_character:
		character_data = GameState.selected_character
	assert(character_data != null, "Player braucht eine CharacterData (Inspector).")
	add_to_group(&"player")
	_apply_character_data()
	health.died.connect(_on_died)
	hurtbox.hit_received.connect(_on_hit_received)
	state_machine.start(self)
	EventBus.player_spawned.emit(self)


func _physics_process(delta: float) -> void:
	state_machine.physics_update(delta)
	move_and_slide()


## Darf der Spieler gerade steuern? (Nein, solange das Menü offen ist.)
func is_input_enabled() -> bool:
	return camera_rig.is_capturing and not health.is_dead


## Eingaberichtung relativ zur Kamera, flach auf dem Boden (Länge 0 bis 1).
func get_move_direction() -> Vector3:
	if not is_input_enabled():
		return Vector3.ZERO
	var input := Input.get_vector(&"move_left", &"move_right", &"move_forward", &"move_back")
	var direction := camera_rig.get_yaw_basis() * Vector3(input.x, 0.0, input.y)
	return direction.limit_length(1.0)


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


func _apply_character_data() -> void:
	var data := character_data
	health.set_max_value(data.max_health)
	stamina.set_max_value(data.max_stamina)
	stamina.regen_per_second = data.stamina_regen_per_second
	stamina.regen_delay = data.stamina_regen_delay
	focus.set_max_value(data.max_focus)
	if data.model_scene:
		# Später: echtes Modell statt Kapsel einsetzen.
		body_mesh.visible = false
		model.add_child(data.model_scene.instantiate())
	else:
		var material := StandardMaterial3D.new()
		material.albedo_color = data.placeholder_color
		body_mesh.material_override = material


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


func _on_hit_received(hit: HitData, result: Hurtbox.Result) -> void:
	if health.is_dead or result != Hurtbox.Result.HIT:
		return
	last_hit = hit
	state_machine.transition_to(&"hurt")


func _on_died() -> void:
	state_machine.transition_to(&"dead")
	EventBus.player_died.emit(self)

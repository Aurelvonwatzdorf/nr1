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
## Zeitlich begrenzter Schadens-Bonus (z. B. Kraftampulle).
var damage_buff: float = 0.0
var damage_buff_time_left: float = 0.0
## Eigene Ressource der Figur (Aurel: AmbitionComponent) oder null.
var special_resource: StatPoolComponent
## Nummer des aktuellen Schlags in einer Kombo (1, 2, 3 …).
var combo_count: int = 0


func _ready() -> void:
	if GameState.selected_character:
		character_data = GameState.selected_character
	assert(character_data != null, "Player braucht eine CharacterData (Inspector).")
	add_to_group(&"player")
	_apply_character_data()
	GameState.stats.changed.connect(_apply_stats)
	GameState.inventory.changed.connect(_apply_stats)
	health.died.connect(_on_died)
	hurtbox.hit_received.connect(_on_hit_received)
	lock_on.target_changed.connect(camera_rig.set_lock_target)
	hitbox.hit_landed.connect(_on_hit_landed)
	hurtbox.hit_filter = _filter_incoming_hit
	hitbox.damage_modifier = _modify_outgoing_damage
	state_machine.start(self)
	EventBus.player_spawned.emit(self)


func _physics_process(delta: float) -> void:
	if is_input_enabled() and Input.is_action_just_pressed(&"lock_on"):
		lock_on.toggle(-camera_rig.camera.global_basis.z)
	if is_input_enabled() and Input.is_action_just_pressed(&"interact") and can_interact():
		interaction_detector.current.interact(self)
	if is_input_enabled() and Input.is_action_just_pressed(&"heal"):
		var potion := GameState.inventory.find_healing_item()
		if potion:
			use_item(potion)
		else:
			EventBus.message_requested.emit("Keine Heiltränke")
	if damage_buff_time_left > 0.0:
		damage_buff_time_left -= delta
		if damage_buff_time_left <= 0.0:
			damage_buff = 0.0
			EventBus.message_requested.emit("Die Wirkung lässt nach")
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


## Schaden-Faktor aus Stats (Stärke), dauerhaften Artefakten und Buffs.
func get_damage_multiplier() -> float:
	return GameState.stats.get_damage_multiplier() \
		+ GameState.inventory.get_permanent_bonus(&"bonus_damage") + damage_buff \
		+ (get_ambition().get_damage_bonus() if get_ambition() else 0.0)


## Aurels Ehrgeiz (oder null bei anderen Figuren).
func get_ambition() -> AmbitionComponent:
	return special_resource as AmbitionComponent


## Benutzt einen Gegenstand. Verbrauchbares wird erst getrunken (kurze Pause).
## Gibt false zurück, wenn es gerade nicht geht.
func use_item(item: ItemData) -> bool:
	if not item.is_consumable() or not GameState.inventory.has(item.id):
		return false
	if not state_machine.get_current_state_name() in [&"idle", &"move"]:
		return false
	state_machine.transition_to(&"use_item", {"item": item})
	return true


## Wirkung eines verbrauchbaren Gegenstands anwenden und ihn abziehen.
func apply_item_effect(item: ItemData) -> void:
	if not GameState.inventory.remove(item.id):
		return
	health.heal(item.heal_amount)
	focus.add(item.focus_amount)
	stamina.add(item.stamina_amount)
	if item.buff_damage_bonus > 0.0:
		damage_buff = item.buff_damage_bonus
		damage_buff_time_left = item.buff_duration
		EventBus.message_requested.emit("+%d %% Schaden für %d s" % [roundi(item.buff_damage_bonus * 100.0), roundi(item.buff_duration)])


## Tempo-Faktor aus den Stats (Schnelligkeit).
func get_speed_multiplier() -> float:
	return GameState.stats.get_speed_multiplier()


## Andere Figur übernehmen (z. B. nach der Charakterauswahl).
func apply_character(data: CharacterData) -> void:
	character_data = data
	_apply_character_data()
	EventBus.character_changed.emit(data)


func _apply_character_data() -> void:
	var data := character_data
	stamina.regen_delay = data.stamina_regen_delay
	_apply_stats(true)
	_setup_special_resource()
	if data.model_scene:
		# Später: echtes Modell statt Kapsel einsetzen.
		body_mesh.visible = false
		model.add_child(data.model_scene.instantiate())
		return
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
	damage_buff = 0.0
	damage_buff_time_left = 0.0
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


## Erzeugt die eigene Ressource der Figur (z. B. Aurels Ehrgeiz).
func _setup_special_resource() -> void:
	if special_resource:
		special_resource.queue_free()
		special_resource = null
	match character_data.special_resource:
		&"ambition":
			special_resource = AmbitionComponent.new()
			special_resource.name = "Ambition"
			add_child(special_resource)
	EventBus.special_resource_changed.emit(special_resource, character_data.special_resource)


## Schaden je Ziel anpassen (Kombo, Funken, Schwachstellen).
func _modify_outgoing_damage(target: Hurtbox, damage: float) -> float:
	var ambition := get_ambition()
	var attack_state := state_machine.current_state as PlayerAttackState
	if GameState.has_skill(&"aurel_chain_strikes") and attack_state and not attack_state.is_heavy():
		damage *= 1.0 + 0.1 * clampi(combo_count - 1, 0, 3)
	if GameState.has_skill(&"aurel_sparks") and ambition and ambition.get_ratio() >= 0.5:
		damage += 5.0
	var enemy := target.owner as Enemy
	if enemy and enemy.data.faction == &"corporate" and GameState.has_skill(&"aurel_weak_spots"):
		damage *= 1.15
	return damage


## Feuerwelle („Lauffeuer“): Schaden an allen Gegnern im Umkreis.
func release_wildfire(radius: float = 3.0, damage: float = 25.0) -> void:
	for node: Node in get_tree().get_nodes_in_group(&"enemies"):
		var enemy := node as Enemy
		if enemy and not enemy.health.is_dead and enemy.global_position.distance_to(global_position) <= radius:
			var hit := HitData.new()
			hit.damage = damage
			hit.knockback = 4.0
			hit.source = self
			hit.direction = (enemy.global_position - global_position).normalized()
			enemy.hurtbox.receive_hit(hit)
	get_ambition().spend_all()
	EventBus.camera_shake_requested.emit(0.6)
	animator.play_wildfire(radius)


## Rechnet Leben, Ausdauer und Fokus aus Grundwerten und Stats neu aus.
func _apply_stats(refill: bool = false) -> void:
	var data := character_data
	var stats := GameState.stats
	var inventory := GameState.inventory
	health.set_max_value(stats.get_max_health(data.max_health) + inventory.get_permanent_bonus(&"bonus_max_health"), refill)
	stamina.set_max_value(stats.get_max_stamina(data.max_stamina) + inventory.get_permanent_bonus(&"bonus_max_stamina"), refill)
	stamina.regen_per_second = stats.get_stamina_regen(data.stamina_regen_per_second)
	focus.set_max_value(stats.get_max_focus(data.max_focus) + inventory.get_permanent_bonus(&"bonus_max_focus"), refill)


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
	if get_ambition():
		get_ambition().on_got_hit()
	EventBus.camera_shake_requested.emit(0.5)
	HitStop.apply(0.08)
	state_machine.transition_to(&"hurt")


## Eigener Treffer: kurzer Hitstop und leichtes Wackeln, stärker bei viel Schaden.
func _on_hit_landed(target: Hurtbox, hit: HitData, _result: Hurtbox.Result) -> void:
	if get_ambition():
		get_ambition().on_hit_landed()
	var enemy := target.owner as Enemy
	if enemy and GameState.has_skill(&"aurel_embers"):
		enemy.apply_burn(3.0, 3.0)
	var heavy := hit.damage >= 20.0
	HitStop.apply(0.09 if heavy else 0.05)
	EventBus.camera_shake_requested.emit(0.3 if heavy else 0.15)


func _on_died() -> void:
	lock_on.set_target(null)
	state_machine.transition_to(&"dead")
	EventBus.player_died.emit(self)

class_name SpiritInvitation
extends Node3D
## Einladung in die Geisterwelt (Kind einer `SpiritualPressureSource`).
## Wer den Druck des Ortes aushält und nahe genug kommt, dem erscheinen Geister.
## Die Zeit bleibt stehen: Menschen und Gegner erstarren, nur die Spielfigur
## bewegt sich noch. Spricht man die Geister an (E), laden sie einen ein.
## Annehmen → Wechsel in die Geisterwelt; Ablehnen → die Zeit läuft weiter, und
## die Geister erscheinen erst wieder, wenn man den Ort verlassen hat.

## So nah muss man kommen, damit die Geister erscheinen (Meter).
@export var trigger_radius: float = 14.0
## Wer sich so weit entfernt, lässt die Geister zurück (die Zeit läuft weiter).
@export var leave_radius: float = 30.0
@export_file("*.tscn") var spirit_world_scene: String = "res://scenes/levels/spirit_world.tscn"
## Nach dem Annehmen die Welt wechseln? (Im Test aus.)
var change_scene_on_accept: bool = true

const SPIRIT_COLOR := Color(0.65, 0.92, 1.0)
const ENVOY_NAME := "Die Geister"

## Wartet nach einem „Noch nicht“, bis man den Ort verlassen hat.
var _waiting_for_leave: bool = false
var _envoys: Array[Node3D] = []
var _frozen: Dictionary[Node, ProcessMode] = {}
var _talking: bool = false
var _checked_start: bool = false


func _physics_process(_delta: float) -> void:
	var player := get_tree().get_first_node_in_group(&"player") as Player
	if player == null:
		return
	var distance := player.global_position.distance_to(global_position)
	# Wer hier schon steht (z. B. zurück aus der Geisterwelt), wird erst nach
	# dem Weggehen wieder eingeladen.
	if not _checked_start:
		_checked_start = true
		_waiting_for_leave = distance < leave_radius
	if GameState.time_stopped and is_active():
		if distance > leave_radius and not _talking:
			EventBus.message_requested.emit("Du gehst fort. Die Geister verblassen, und die Zeit läuft weiter.")
			_end_invitation()
		return
	if _waiting_for_leave:
		if distance > leave_radius:
			_waiting_for_leave = false
		return
	if distance < trigger_radius and _can_invite(player):
		_begin_invitation()


## Sind die Geister gerade erschienen?
func is_active() -> bool:
	return not _envoys.is_empty()


## Nur wer den Druck aushält, wird eingeladen. Nicht in Spiegelrealitäten.
func _can_invite(player: Player) -> bool:
	if GameState.time_stopped or GameState.is_menu_open() or player.health.is_dead:
		return false
	if get_tree().get_first_node_in_group(&"reality"):
		return false
	var source := get_parent() as SpiritualPressureSource
	var needed := source.required_spirituality if source else 1
	return GameState.stats.spirituality >= needed


## Die Zeit bleibt stehen, und die Geister erscheinen vor dem Schrein.
func _begin_invitation() -> void:
	_freeze_world(true)
	for i in 3:
		var angle := (float(i) - 1.0) * 0.6
		var at := Vector3(sin(angle) * 5.0, 0.0, 6.0 + cos(angle) * 1.5 - 1.5)
		_envoys.append(_make_envoy(at, i == 1))
	EventBus.message_requested.emit("Die Welt hält den Atem an. Alles steht still, nur du nicht.\nGeister erscheinen vor dem Schrein.")
	EventBus.companion_spoke.emit(_companion_line())


## Spricht die Spielfigur die Geister an (E am mittleren Geist).
func _on_envoy_interacted(player: Player) -> void:
	if _talking:
		return
	var dialogue := get_tree().get_first_node_in_group(&"dialogue_box") as DialogueBox
	if dialogue == null:
		return
	_talking = true
	var is_tahirou := GameState.selected_character != null and GameState.selected_character.id == &"tahirou"
	await dialogue.ask(ENVOY_NAME, "Du hast unseren Druck ausgehalten, Menschenkind. Für uns hält deine Welt den Atem an.")
	var question := "Hinter dem Schleier liegt unsere Welt. Wir laden dich ein. Kommst du mit?"
	if is_tahirou:
		question = "Die Raben deines Clans kennen den Weg zu uns seit vielen Generationen. Nun laden wir dich selbst ein. Kommst du mit?"
	var choice := await dialogue.ask(ENVOY_NAME, question, ["Mit ihnen gehen", "Noch nicht"])
	dialogue.finish()
	_talking = false
	if choice == 0:
		_accept(player)
	else:
		EventBus.message_requested.emit("Die Geister weichen zurück. „Wir warten.“\nDie Zeit läuft weiter.")
		_waiting_for_leave = true
		_end_invitation()


func _accept(player: Player) -> void:
	GameState.set_story_flag(&"spirit_invitation_accepted")
	GameState.return_scene = GameState.current_scene
	# Zurück kommt man ein paar Schritte vor dem Schrein heraus.
	var back := to_global(Vector3(0, 0.1, 9.0))
	GameState.return_transform = Transform3D(player.global_basis, back)
	GameState.pending_message = "Die Geisterwelt. Alles ist still, und doch ist alles lebendig."
	_waiting_for_leave = true
	_end_invitation()
	if change_scene_on_accept and spirit_world_scene != "":
		get_tree().change_scene_to_file.call_deferred(spirit_world_scene)


## Geister weg, Zeit läuft weiter.
func _end_invitation() -> void:
	for envoy in _envoys:
		if is_instance_valid(envoy):
			envoy.queue_free()
	_envoys.clear()
	_freeze_world(false)


## Hält Menschen und Gegner an (oder lässt sie weiterlaufen). Die Spielfigur
## bewegt sich weiter; die Physik läuft, darum kein Pausieren des Baums.
func _freeze_world(stop: bool) -> void:
	if stop == GameState.time_stopped:
		return
	GameState.time_stopped = stop
	if stop:
		for group: StringName in [&"npcs", &"enemies"]:
			for node: Node in get_tree().get_nodes_in_group(group):
				if not _frozen.has(node):
					_frozen[node] = node.process_mode
					node.process_mode = Node.PROCESS_MODE_DISABLED
	else:
		for node: Node in _frozen:
			if is_instance_valid(node):
				node.process_mode = _frozen[node]
		_frozen.clear()
	EventBus.time_stop_changed.emit(stop)


func _exit_tree() -> void:
	if is_active():
		_end_invitation()


func _companion_line() -> String:
	var is_tahirou := GameState.selected_character != null and GameState.selected_character.id == &"tahirou"
	if is_tahirou:
		return "Twin … die Raben werden ganz still. Das sind keine Fremden. Hör sie an."
	return "Aurel, die Zeit … sie steht. Das ist kein Trick der Konzerne. Sprich mit ihnen."


## Ein leuchtender Geist. Der mittlere lässt sich ansprechen.
func _make_envoy(at: Vector3, speaker: bool) -> Node3D:
	var envoy := Node3D.new()
	envoy.name = "SpiritEnvoy"
	envoy.position = at
	var material := ToonStyle.make(SPIRIT_COLOR, false)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = Color(SPIRIT_COLOR, 0.55)
	material.emission_enabled = true
	material.emission = SPIRIT_COLOR
	material.emission_energy_multiplier = 1.8
	var body_mesh := CapsuleMesh.new()
	body_mesh.radius = 0.45 if speaker else 0.35
	body_mesh.height = 2.4 if speaker else 1.9
	var body := MeshInstance3D.new()
	body.mesh = body_mesh
	body.material_override = material
	body.position = Vector3(0, 1.6, 0)
	envoy.add_child(body)
	var head_mesh := SphereMesh.new()
	head_mesh.radius = 0.3
	head_mesh.height = 0.6
	var head := MeshInstance3D.new()
	head.mesh = head_mesh
	head.material_override = material
	head.position = Vector3(0, 3.1 if speaker else 2.8, 0)
	envoy.add_child(head)
	if speaker:
		var label := Label3D.new()
		label.text = ENVOY_NAME
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.font_size = 40
		label.outline_size = 8
		label.modulate = SPIRIT_COLOR
		label.position = Vector3(0, 3.8, 0)
		envoy.add_child(label)
		var talk := Interactable.new()
		talk.name = "TalkArea"
		talk.prompt = "Den Geistern antworten"
		var shape := CollisionShape3D.new()
		var sphere := SphereShape3D.new()
		sphere.radius = 2.5
		shape.shape = sphere
		shape.position = Vector3(0, 1.2, 0)
		talk.add_child(shape)
		talk.interacted.connect(_on_envoy_interacted)
		envoy.add_child(talk)
	add_child(envoy)
	# Sanftes Schweben (die Geister stehen nicht still, die Welt schon).
	var tween := envoy.create_tween().set_loops()
	tween.tween_property(envoy, ^"position:y", 0.35, 1.4).set_trans(Tween.TRANS_SINE)
	tween.tween_property(envoy, ^"position:y", 0.0, 1.4).set_trans(Tween.TRANS_SINE)
	return envoy

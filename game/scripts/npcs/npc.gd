class_name NPC
extends CharacterBody3D
## Nicht-Spieler-Figur. Mit E ansprechen (TalkArea). Eigene NPCs erben hiervon und
## überschreiben `talk()` für ihr Gespräch und `_npc_physics()` für Bewegung.

## Eindeutige ID (für Speichern und Moral-Taten).
@export var npc_id: StringName = &""
@export var display_name: String = "Fremder"
@export var body_color: Color = Color(0.7, 0.65, 0.55)
@export var walk_speed: float = 1.5

@onready var talk_area: Interactable = $TalkArea
@onready var body_mesh: MeshInstance3D = $Model/Body
@onready var model: Node3D = $Model
@onready var name_label: Label3D = $NameLabel

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var _material: StandardMaterial3D
var _talking: bool = false


func _ready() -> void:
	add_to_group(&"npcs")
	_material = StandardMaterial3D.new()
	_material.albedo_color = body_color
	body_mesh.material_override = _material
	name_label.text = display_name
	talk_area.prompt = "Mit %s sprechen" % display_name
	talk_area.interacted.connect(_on_talk_requested)


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta
	_npc_physics(delta)
	move_and_slide()


## Für Unterklassen: Bewegung pro Physik-Frame (Standard: stehen bleiben).
func _npc_physics(delta: float) -> void:
	var horizontal := Vector3(velocity.x, 0.0, velocity.z).move_toward(Vector3.ZERO, 10.0 * delta)
	velocity.x = horizontal.x
	velocity.z = horizontal.z


## Für Unterklassen: das Gespräch. Immer `await dialogue.ask(...)` benutzen.
func talk(_player: Player, dialogue: DialogueBox) -> void:
	await dialogue.ask(display_name, "…")


func is_talking() -> bool:
	return _talking


## Läuft in Richtung eines Ziels (flach), dreht sich dabei.
func walk_towards(target: Vector3, speed: float, delta: float) -> void:
	var offset := target - global_position
	offset.y = 0.0
	var desired := offset.normalized() * speed if offset.length() > 0.1 else Vector3.ZERO
	var horizontal := Vector3(velocity.x, 0.0, velocity.z).move_toward(desired, 10.0 * delta)
	velocity.x = horizontal.x
	velocity.z = horizontal.z
	if desired != Vector3.ZERO:
		rotation.y = lerp_angle(rotation.y, atan2(-desired.x, -desired.z), 1.0 - exp(-8.0 * delta))


func _on_talk_requested(player: Player) -> void:
	if _talking:
		return
	var dialogue := get_tree().get_first_node_in_group(&"dialogue_box") as DialogueBox
	if dialogue == null:
		return
	_talking = true
	var to_player := player.global_position - global_position
	rotation.y = atan2(-to_player.x, -to_player.z)
	await talk(player, dialogue)
	dialogue.finish()
	_talking = false

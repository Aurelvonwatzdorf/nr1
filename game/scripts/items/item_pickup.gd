class_name ItemPickup
extends Interactable
## Ein Gegenstand, der in der Welt liegt. E hebt ihn auf.
## Jeder Fundort braucht eine eindeutige `pickup_id`, damit er nach dem Laden
## nicht wieder auftaucht.

@export var item: ItemData
@export var amount: int = 1
## Eindeutiger Name dieses Fundorts (z. B. &"arena_potion_1").
@export var pickup_id: StringName = &""

@onready var visual: MeshInstance3D = $Visual


func _ready() -> void:
	super._ready()
	if GameState.collected_pickups.has(pickup_id):
		queue_free()
		return
	prompt = "%s aufheben" % item.display_name
	var material := StandardMaterial3D.new()
	material.albedo_color = item.color
	material.emission_enabled = true
	material.emission = item.color
	material.emission_energy_multiplier = 1.2
	visual.material_override = material


func _process(delta: float) -> void:
	visual.rotate_y(delta * 1.5)


func interact(player: Player) -> void:
	GameState.inventory.add(item.id, amount)
	if pickup_id != &"":
		GameState.collected_pickups.append(pickup_id)
	var suffix := " ×%d" % amount if amount > 1 else ""
	EventBus.message_requested.emit("%s%s erhalten" % [item.display_name, suffix])
	super.interact(player)
	queue_free()

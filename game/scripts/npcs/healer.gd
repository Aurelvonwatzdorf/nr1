class_name Healer
extends NPC
## Heilerin (Service): behandelt Verletzungen gegen Geld.

@export var price: int = 20


func talk(player: Player, dialogue: DialogueBox) -> void:
	if player.health.current >= player.health.max_value - 0.5:
		await dialogue.ask(display_name, "Du bist gesund. Pass auf dich auf da draußen.")
		return
	var choice := await dialogue.ask(display_name,
		"Du bist verletzt. Für %d Geld behandle ich dich.\n\nDein Geld: %d" % [price, GameState.money],
		["Behandeln lassen (%d Geld)" % price, "Nein danke"])
	if choice != 0:
		return
	if GameState.try_spend_money(price):
		player.health.refill()
		await dialogue.ask(display_name, "So. Das hält wieder.")
	else:
		await dialogue.ask(display_name, "Das reicht nicht. Komm wieder, wenn du es dir leisten kannst.")

class_name Merchant
extends NPC
## Händler: verkauft Gegenstände gegen Geld.

## Was er verkauft und zu welchem Preis (gleiche Reihenfolge).
@export var stock: Array[ItemData] = []
@export var prices: Array[int] = []
## Begrüßung im Gespräch.
@export var greeting: String = "Willkommen. Was darf es sein?"


func talk(_player: Player, dialogue: DialogueBox) -> void:
	var text := greeting
	while true:
		var options: Array[String] = []
		for i in stock.size():
			if _is_sold_out(stock[i]):
				options.append("%s (schon gekauft)" % stock[i].display_name)
			else:
				options.append("%s kaufen (%d Geld)" % [stock[i].display_name, prices[i]])
		options.append("Tschüss")
		var choice := await dialogue.ask(display_name, "%s\n\nDein Geld: %d" % [text, GameState.money], options)
		if choice >= stock.size():
			return
		if _is_sold_out(stock[choice]):
			text = "Das hast du doch schon."
		else:
			text = "Bitte sehr." if buy(choice) else "Das reicht leider nicht."


## Kauft Eintrag Nummer `index`. Gibt false zurück, wenn das Geld nicht reicht.
func buy(index: int) -> bool:
	var item := stock[index]
	if _is_sold_out(item) or not GameState.try_spend_money(prices[index]):
		return false
	GameState.inventory.add(item.id, item.buy_amount)
	# Gekaufte Waffen gleich ausrüsten, wenn noch keine da ist.
	if item.kind == ItemData.Kind.WEAPON and GameState.equipped_weapon == &"" \
			or item.kind == ItemData.Kind.FIREARM and GameState.equipped_firearm == &"":
		GameState.toggle_equip(item)
	return true


## Dauerhaftes (Waffen, Implantate, Radar) kauft man nur einmal.
func _is_sold_out(item: ItemData) -> bool:
	return item.kind in [ItemData.Kind.PERMANENT, ItemData.Kind.WEAPON, ItemData.Kind.FIREARM] \
		and GameState.inventory.has(item.id)

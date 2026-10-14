class_name Merchant
extends NPC
## Händler: verkauft Gegenstände gegen Geld.

## Was er verkauft und zu welchem Preis (gleiche Reihenfolge).
@export var stock: Array[ItemData] = []
@export var prices: Array[int] = []


func talk(_player: Player, dialogue: DialogueBox) -> void:
	var text := "Willkommen. Was darf es sein?"
	while true:
		var options: Array[String] = []
		for i in stock.size():
			options.append("%s kaufen (%d Geld)" % [stock[i].display_name, prices[i]])
		options.append("Tschüss")
		var choice := await dialogue.ask(display_name, "%s\n\nDein Geld: %d" % [text, GameState.money], options)
		if choice >= stock.size():
			return
		text = "Bitte sehr." if buy(choice) else "Das reicht leider nicht."


## Kauft Eintrag Nummer `index`. Gibt false zurück, wenn das Geld nicht reicht.
func buy(index: int) -> bool:
	if not GameState.try_spend_money(prices[index]):
		return false
	GameState.inventory.add(stock[index].id)
	return true

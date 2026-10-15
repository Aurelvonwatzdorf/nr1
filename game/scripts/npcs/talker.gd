class_name Talker
extends NPC
## NPC mit festen Sätzen (z. B. Kollegen im Konzernturm). Jedes Gespräch sagt den
## nächsten Satz. Für Tahirou kann es eigene Sätze geben.

@export_multiline var lines: Array[String] = ["…"]
@export_multiline var lines_tahirou: Array[String] = []

var _next: int = 0


func talk(_player: Player, dialogue: DialogueBox) -> void:
	var chosen := RealityLevel.get_lines(lines, lines_tahirou)
	if chosen.is_empty():
		return
	await dialogue.ask(display_name, chosen[_next % chosen.size()])
	_next += 1

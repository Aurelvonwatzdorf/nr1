class_name Citizen
extends NPC
## Einwohner von Santo Santiago. Läuft durch die Straßen, meist in seinem
## eigenen Viertel, und sagt ein paar Sätze aus seinem Alltag.

## Sätze je Viertel (CityDistrict.id). Alltag, kein Klischee.
const LINES: Dictionary[StringName, Array] = {
	&"corporate": [
		"Ich habe keine Zeit. Die Zahlen müssen bis heute Abend stimmen.",
		"Siehst du die Zitadelle? Wer dort oben arbeitet, kommt nie wieder herunter.",
		"Pass auf, was du hier sagst. Die Wachen hören mit.",
	],
	&"market": [
		"Der Baum in der Mitte war schon hier, bevor es die Stadt gab.",
		"Auf dem Markt treffen sich alle Viertel. Nur hier, sonst nirgends.",
		"Die Preise steigen jede Woche. Die Konzerne wollen es so.",
	],
	&"christian": [
		"Nach der Messe gibt es heute Suppe für alle, die Hunger haben.",
		"Die Glocken haben früher den ganzen Tag geläutet. Jetzt dürfen sie nur noch abends.",
		"Pass auf dich auf, Fremder. Gott schütze dich.",
	],
	&"muslim": [
		"Bald ist Gebetszeit, dann wird es hier ganz still.",
		"Komm nach dem Freitagsgebet wieder, dann ist der Platz voller Menschen.",
		"Friede sei mit dir.",
	],
	&"jewish": [
		"Am Freitagabend beginnt der Schabbat. Dann ruhen hier die Läden.",
		"Meine Familie lebt seit Generationen in diesen Gassen.",
		"Schalom. Suchst du jemanden?",
	],
	&"atheist": [
		"Im Haus der Stille liest heute jemand aus alten Büchern vor.",
		"Wir glauben an das, was wir sehen. Aber in letzter Zeit sehe ich seltsame Dinge.",
		"Die Leute hier helfen sich gegenseitig. Mehr braucht es nicht.",
	],
	&"slum": [
		"Hier unten vergessen uns alle. Die Konzerne zuerst.",
		"Wasser gibt es nur morgens. Wer zu spät kommt, hat Pech.",
		"Die Ranken wachsen hier schneller als irgendwo sonst. Manche sagen, sie beschützen uns.",
	],
}

## Kleidungsfarben je Viertel.
const COLORS: Dictionary[StringName, Array] = {
	&"corporate": [Color(0.16, 0.17, 0.22), Color(0.25, 0.25, 0.3), Color(0.35, 0.33, 0.38), Color(0.5, 0.15, 0.18)],
	&"market": [Color(0.8, 0.5, 0.3), Color(0.4, 0.6, 0.8), Color(0.75, 0.7, 0.4), Color(0.6, 0.4, 0.6)],
	&"christian": [Color(0.55, 0.42, 0.3), Color(0.7, 0.6, 0.45), Color(0.4, 0.45, 0.55), Color(0.6, 0.3, 0.25)],
	&"muslim": [Color(0.9, 0.9, 0.85), Color(0.35, 0.55, 0.5), Color(0.3, 0.4, 0.6), Color(0.75, 0.65, 0.5)],
	&"jewish": [Color(0.2, 0.25, 0.4), Color(0.85, 0.85, 0.82), Color(0.45, 0.45, 0.5), Color(0.55, 0.45, 0.35)],
	&"atheist": [Color(0.5, 0.55, 0.6), Color(0.3, 0.6, 0.65), Color(0.75, 0.75, 0.78), Color(0.4, 0.35, 0.5)],
	&"slum": [Color(0.4, 0.35, 0.3), Color(0.35, 0.38, 0.35), Color(0.5, 0.4, 0.3), Color(0.3, 0.3, 0.35)],
}

const NAMES: Dictionary[StringName, Array] = {
	&"corporate": ["Konzernangestellte", "Konzernangestellter"],
	&"market": ["Marktbesucherin", "Marktbesucher"],
	&"slum": ["Bewohnerin der Senke", "Bewohner der Senke"],
}


## Aussehen und Name passend zum Viertel festlegen (vor dem Einfügen aufrufen).
func setup(id: StringName, quarter: StringName, rng: RandomNumberGenerator) -> void:
	npc_id = id
	home_quarter = quarter
	roam = Roam.CITY
	home_loyalty = 0.9
	walk_speed = rng.randf_range(1.2, 1.8)
	var colors: Array = COLORS.get(quarter, COLORS[&"market"])
	body_color = colors[rng.randi() % colors.size()]
	var names: Array = NAMES.get(quarter, ["Anwohnerin", "Anwohner"])
	display_name = names[rng.randi() % names.size()]


func talk(_player: Player, dialogue: DialogueBox) -> void:
	var lines: Array = LINES.get(home_quarter, LINES[&"market"])
	await dialogue.ask(display_name, lines[_roam_rng.randi() % lines.size()])

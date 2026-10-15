class_name MapMarker
extends Node3D
## Markiert einen Ort auf Minimap und großer Karte. Einfach als Kind an ein
## Objekt hängen (Händler, Ankerspiegel, Gebäude …) und die Art wählen.

enum Kind {
	MARKET, MERCHANT, SERVICE, CORPORATE_TOWER, BARRACKS, ANCHOR_MIRROR,
	CHURCH, MOSQUE, SYNAGOGUE, HOUSE_OF_SILENCE, MISSION, MEMORY_REMNANT,
}

## Symbol (kurzer Text), Farbe und Name in der Legende je Art.
const STYLE: Dictionary[Kind, Array] = {
	Kind.MARKET: ["M", Color(0.95, 0.75, 0.3), "Marktplatz"],
	Kind.MERCHANT: ["$", Color(1.0, 0.85, 0.35), "Händler"],
	Kind.SERVICE: ["+", Color(0.4, 0.9, 0.55), "Service"],
	Kind.CORPORATE_TOWER: ["▲", Color(0.95, 0.3, 0.3), "Konzern-Wolkenkratzer"],
	Kind.BARRACKS: ["■", Color(0.75, 0.2, 0.25), "Kaserne"],
	Kind.ANCHOR_MIRROR: ["◆", Color(0.5, 0.85, 1.0), "Ankerspiegel"],
	Kind.CHURCH: ["Ki", Color(0.9, 0.9, 1.0), "Kirche"],
	Kind.MOSQUE: ["Mo", Color(0.6, 1.0, 0.85), "Moschee"],
	Kind.SYNAGOGUE: ["Sy", Color(0.75, 0.85, 1.0), "Synagoge"],
	Kind.HOUSE_OF_SILENCE: ["St", Color(0.85, 0.85, 0.85), "Haus der Stille"],
	Kind.MISSION: ["!", Color(1.0, 0.95, 0.4), "Mission"],
	Kind.MEMORY_REMNANT: ["✦", Color(0.75, 0.55, 1.0), "Deine Erinnerungen"],
}

@export var kind: Kind = Kind.SERVICE
## Name des Ortes (z. B. „Händler am Markt“).
@export var label: String = ""
## Nur bei Missionen: Marker verschwindet, wenn die Mission erledigt ist.
@export var mission_id: StringName = &""


func _ready() -> void:
	add_to_group(&"map_markers")


func is_shown() -> bool:
	if mission_id != &"" and GameState.get_mission_status(mission_id) in [GameState.MissionStatus.COMPLETED, GameState.MissionStatus.FAILED]:
		return false
	return is_visible_in_tree()


func get_symbol() -> String:
	return STYLE[kind][0]


func get_color() -> Color:
	return STYLE[kind][1]


static func get_kind_name(marker_kind: Kind) -> String:
	return STYLE[marker_kind][2]

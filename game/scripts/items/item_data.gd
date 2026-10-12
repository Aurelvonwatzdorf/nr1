class_name ItemData
extends Resource
## Ein Gegenstand: Trank oder Artefakt. Neue Gegenstände = neue .tres-Datei
## in resources/items/ plus Eintrag in ItemDatabase.

enum Kind {
	## Wirkt einmal und ist dann weg (Tränke, verbrauchbare Artefakte).
	CONSUMABLE,
	## Wirkt dauerhaft, solange man es besitzt.
	PERMANENT,
}

@export var id: StringName = &""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var kind: Kind = Kind.CONSUMABLE
## Farbe des Platzhalters in der Welt.
@export var color: Color = Color(0.9, 0.3, 0.3)

@export_group("Sofort-Wirkung (verbrauchbar)")
@export var heal_amount: float = 0.0
@export var focus_amount: float = 0.0
@export var stamina_amount: float = 0.0
## Zeitlich begrenzter Schadens-Bonus (0.25 = +25 %).
@export var buff_damage_bonus: float = 0.0
@export var buff_duration: float = 0.0
## Wie lange das Benutzen dauert (Trinken). In der Zeit ist man verwundbar.
@export var use_time: float = 0.7

@export_group("Dauer-Wirkung (permanent)")
@export var bonus_max_health: float = 0.0
@export var bonus_max_stamina: float = 0.0
@export var bonus_max_focus: float = 0.0
@export var bonus_damage: float = 0.0


func is_consumable() -> bool:
	return kind == Kind.CONSUMABLE

class_name ItemData
extends Resource
## Ein Gegenstand: Trank oder Artefakt. Neue Gegenstände = neue .tres-Datei
## in resources/items/ plus Eintrag in ItemDatabase.

enum Kind {
	## Wirkt einmal und ist dann weg (Tränke, verbrauchbare Artefakte).
	CONSUMABLE,
	## Wirkt dauerhaft, solange man es besitzt (Artefakte, Implantate, Radar).
	PERMANENT,
	## Nahkampfwaffe, wird im Inventar ausgerüstet.
	WEAPON,
	## Schusswaffe, wird im Inventar ausgerüstet, schießt mit Taste V.
	FIREARM,
	## Munition (Anzahl = Schuss).
	AMMO,
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
## So viele Stück bekommt man beim Kauf (z. B. 12 Schuss Munition).
@export var buy_amount: int = 1

@export_group("Dauer-Wirkung (permanent)")
@export var bonus_max_health: float = 0.0
@export var bonus_max_stamina: float = 0.0
@export var bonus_max_focus: float = 0.0
@export var bonus_damage: float = 0.0
## Tempo-Bonus (0.1 = +10 %).
@export var bonus_speed: float = 0.0
## Erlittener Schaden wird um diesen Anteil kleiner (0.15 = −15 %).
@export var damage_reduction: float = 0.0
## Mehr Ausdauer-Regeneration pro Sekunde.
@export var bonus_stamina_regen: float = 0.0
## Zeigt Gegner auf Minimap und Karte.
@export var grants_radar: bool = false

@export_group("Nahkampfwaffe")
@export var light_attack: AttackData
@export var heavy_attack: AttackData
## Länge der Klinge (Platzhalter-Modell, Meter).
@export var weapon_length: float = 1.1

@export_group("Schusswaffe")
@export var shot_damage: float = 14.0
## Sekunden zwischen zwei Schüssen.
@export var fire_cooldown: float = 0.45
@export var shot_range: float = 40.0
## ID der passenden Munition.
@export var ammo_id: StringName = &""


func is_consumable() -> bool:
	return kind == Kind.CONSUMABLE

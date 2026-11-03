class_name HackProgramData
extends Resource
## Ein Programm für Aurels Fernzugriff (Insider-Ast). Daten statt Code: Ladezeit,
## Kosten und Wirkung stehen hier; die Wirkung selbst steckt in `Enemy.receive_program()`.

enum Effect {
	DISRUPT, ## taumeln (mit „Waffensperre“ zusätzlich halber Schaden)
	BLIND, ## Augenimplantate fallen aus: verliert die Spielfigur aus der Sicht
	OVERHEAT, ## Implantate glühen: Brandschaden
}

@export var id: StringName = &""
@export var display_name: String = ""
@export var effect: Effect = Effect.DISRUPT
## Diese Fähigkeit muss gelernt sein.
@export var required_skill: StringName = &""
@export var upload_time: float = 1.0
@export var ambition_cost: float = 40.0
@export var focus_cost: float = 10.0
## Dauer der Wirkung (Sekunden).
@export var effect_time: float = 1.5
## Nur Überhitzung: Schaden pro Sekunde.
@export var damage_per_second: float = 0.0
## Sperre für dieses Ziel danach (Sekunden).
@export var target_cooldown: float = 12.0

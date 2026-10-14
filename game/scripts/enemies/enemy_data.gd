class_name EnemyData
extends Resource
## Alle Werte eines Gegnertyps. Neue Gegner = neue .tres-Datei, kein neuer Code.

@export var display_name: String = "Gegner"
## Zugehörigkeit, z. B. &"corporate" (Konzern). Manche Fähigkeiten wirken nur
## gegen bestimmte Gruppen.
@export var faction: StringName = &""

@export_group("Werte")
@export var max_health: float = 80.0
## Erinnerungen, die man für einen Sieg bekommt.
@export var memories_reward: int = 50
## Geld, das er beim Sieg fallen lässt.
@export var money_reward: int = 15

@export_group("Bewegung")
@export var walk_speed: float = 2.0
@export var chase_speed: float = 4.0
@export var acceleration: float = 20.0
@export var turn_speed: float = 8.0

@export_group("Wahrnehmung")
## Ab dieser Entfernung bemerkt der Gegner die Spielfigur.
@export var detection_radius: float = 10.0
## Ist die Spielfigur weiter weg als das, gibt er auf und kehrt zurück.
@export var lose_radius: float = 18.0

@export_group("Kampf")
@export var attack: AttackData
## Ab dieser Entfernung greift er an.
@export var attack_range: float = 1.8
## Mindestpause zwischen zwei Angriffen.
@export var attack_cooldown: float = 1.2
## Wie lange er nach einem Treffer taumelt.
@export var stagger_time: float = 0.4
## Wie lange er nach einer Parade wehrlos ist.
@export var parried_stun_time: float = 1.5

@export_group("Darstellung")
@export var placeholder_color: Color = Color(0.35, 0.38, 0.45)

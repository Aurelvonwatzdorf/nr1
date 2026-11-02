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
## Sichtkegel nach vorn (ganzer Winkel in Grad). Dahinter sieht er nichts.
@export var view_angle: float = 110.0
## So nah merkt er es immer, auch von hinten (stehend / geduckt: erst bei
## Berührung, damit man sich zum lautlosen Erledigen anschleichen kann).
@export var near_radius: float = 2.5
@export var near_radius_crouched: float = 0.7
## Geduckt sieht er die Spielfigur nur auf diesen Anteil der Sichtweite.
@export_range(0.0, 1.0) var crouch_sight_factor: float = 0.6
## So lange dauert das Bemerken ganz nah bzw. am Rand der Sichtweite (Sekunden).
@export var notice_time_near: float = 0.3
@export var notice_time_far: float = 1.5
## So lange braucht der Verdacht, um ganz zu verschwinden.
@export var forget_time: float = 4.0
## So lange sucht er an der letzten bekannten Stelle, bevor er zurückgeht.
@export var search_time: float = 8.0
## Rennen hört er in diesem Umkreis.
@export var hear_running_radius: float = 6.0

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

## Spiegeljäger: Wer von ihm besiegt wird, stirbt nicht, sondern wird in eine
## Spiegelrealität gesperrt.
@export var captures: bool = false
## Lässt er sich von hinten lautlos erledigen (betäuben/töten)?
@export var can_be_taken_down: bool = true

@export_group("Darstellung")
@export var placeholder_color: Color = Color(0.35, 0.38, 0.45)

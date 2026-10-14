class_name MissionData
extends Resource
## Eine Mission (Haupt- oder Nebenmission). Neue Missionen = neue .tres-Datei in
## resources/missions/ plus Eintrag in MissionDatabase.

@export var id: StringName = &""
@export var title: String = ""
## Kurzer Auftrag für die Missionsanzeige.
@export var objective: String = ""

@export_group("Belohnung")
@export var reward_money: int = 0
@export var reward_memories: int = 0

@export_group("Moral (unsichtbar)")
## Tugend aus MoralMemory.VIRTUES. Leer = zählt nicht fürs Moral-Gedächtnis.
@export var moral_virtue: StringName = &""
@export var moral_value: int = 0
@export var moral_text: String = ""

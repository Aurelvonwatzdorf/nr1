class_name SkillData
extends Resource
## Eine Fähigkeit im Fähigkeitenbaum einer Figur.
## Die Wirkung steht im Code (abgefragt mit `GameState.has_skill(id)`).

@export var id: StringName = &""
@export var display_name: String = ""
@export_multiline var description: String = ""
## Name des Astes, z. B. „Aufstieg“.
@export var branch: String = ""
## Fähigkeitspunkte, die das Freischalten kostet.
@export var cost: int = 1
## Diese Fähigkeiten muss man vorher haben.
@export var requires: Array[StringName] = []
## Story-Fortschritt, der nötig ist (leer = keiner).
@export var story_flag: StringName = &""
## Hinweis, wann der Story-Fortschritt kommt („Nach dem ersten Bosssieg“).
@export var story_hint: String = ""

class_name MapData
extends Node
## Was die Karte als Grundriss zeichnet: Flächen (Bezirke, Straßen, Gebäude) in
## Weltkoordinaten (x, z). Ein Level hat höchstens einen MapData-Knoten.

## Ausdehnung der Welt (für die große Karte).
@export var bounds: Rect2 = Rect2(-50, -50, 100, 100)
## Name der Gegend, wird auf der großen Karte angezeigt.
@export var area_name: String = ""

## Flächen: {"rect": Rect2, "color": Color, "label": String}. Spätere zuerst
## gezeichnet = unten, also Bezirke vor Gebäuden eintragen.
var shapes: Array[Dictionary] = []


func _enter_tree() -> void:
	add_to_group(&"map_data")


func add_rect(rect: Rect2, color: Color, label: String = "") -> void:
	shapes.append({"rect": rect, "color": color, "label": label})

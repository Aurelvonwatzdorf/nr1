class_name MapData
extends Node
## Was die Karte als Grundriss zeichnet: Flächen (Bezirke, Plätze, Gebäude) und
## Linien (Straßen) in Weltkoordinaten (x, z). Ein Level hat höchstens einen
## MapData-Knoten.

## Ausdehnung der Welt (für die große Karte).
@export var bounds: Rect2 = Rect2(-50, -50, 100, 100)
## Name der Gegend, wird auf der großen Karte angezeigt.
@export var area_name: String = ""
## Maßstab der Minimap (Pixel pro Meter). 0 = Standard der Minimap.
@export var minimap_scale: float = 0.0

## Flächen: {"points": PackedVector2Array, "color": Color, "label": String,
## "center": Vector2, "radius": float}. Früher eingetragen = weiter unten
## gezeichnet, also Bezirke vor Straßen und Gebäuden eintragen.
var shapes: Array[Dictionary] = []


func _enter_tree() -> void:
	add_to_group(&"map_data")


## Alles entfernen (z. B. um die Karte nach einer Entdeckung neu einzutragen).
func clear() -> void:
	shapes.clear()


func add_rect(rect: Rect2, color: Color, label: String = "") -> void:
	add_polygon(PackedVector2Array([rect.position, Vector2(rect.end.x, rect.position.y), rect.end,
		Vector2(rect.position.x, rect.end.y)]), color, label)


## Beliebige Fläche (z. B. gedrehtes Haus, Bezirk).
func add_polygon(points: PackedVector2Array, color: Color, label: String = "", label_at: Variant = null) -> void:
	var center := Vector2.ZERO
	for point in points:
		center += point
	center /= maxf(points.size(), 1)
	var radius := 0.0
	for point in points:
		radius = maxf(radius, point.distance_to(center))
	shapes.append({"points": points, "color": color, "label": label,
		"center": label_at if label_at is Vector2 else center, "radius": radius, "width": 0.0})


## Linie mit Breite in Metern (Straßen).
func add_line(points: PackedVector2Array, width: float, color: Color) -> void:
	var center := Vector2.ZERO
	for point in points:
		center += point
	center /= maxf(points.size(), 1)
	var radius := 0.0
	for point in points:
		radius = maxf(radius, point.distance_to(center))
	shapes.append({"points": points, "color": color, "label": "", "center": center,
		"radius": radius + width, "width": width})

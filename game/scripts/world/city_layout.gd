class_name CityLayout
extends Resource
## Bauplan einer Stadt: Bezirke und Straßen. Der CityGenerator baut daraus die Stadt.

@export var city_name: String = ""
@export var districts: Array[CityDistrict] = []
## Straßen als Rechtecke (x, z, Breite, Tiefe). Hier steht nie ein Haus.
@export var roads: Array[Rect2] = []
## Wo die Spielfigur startet (falls kein Ankerspiegel gespeichert ist).
@export var spawn_point: Vector3 = Vector3.ZERO
## Gesamtfläche der Stadt. Am Rand stehen unsichtbare Mauern.
@export var bounds: Rect2 = Rect2(-100, -100, 200, 200)

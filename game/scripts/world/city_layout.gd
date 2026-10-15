class_name CityLayout
extends Resource
## Bauplan einer Stadt: Bezirke, Hauptstraßen, Plätze und der Umriss.
## Der CityGenerator baut daraus die Stadt (Nebenstraßen und Häuser erzeugt er
## selbst, gleicher Seed = gleiche Stadt).

@export var city_name: String = ""
@export var districts: Array[CityDistrict] = []

@export_group("Umriss")
## Mittlerer Radius der bebauten Stadt (Meter).
@export var radius: float = 150.0
## So viel weiter reicht die Stadt nach Norden (Konzernviertel).
@export var north_bulge: float = 50.0
## Wie unregelmäßig der Stadtrand ist (0 = Kreis).
@export_range(0.0, 0.5) var roughness: float = 0.2
## Breite des wilden Rands außerhalb der Stadt bis zur unsichtbaren Mauer.
@export var wild_margin: float = 30.0

@export_group("Straßen und Plätze")
## Hauptstraßen als Punktfolgen (x, z). Inhalte (NPCs, Spiegel …) stehen meist hier.
@export var main_roads: Array[PackedVector2Array] = []
## Breite je Hauptstraße (gleiche Reihenfolge).
@export var main_road_widths: PackedFloat32Array = PackedFloat32Array()
## Plätze: x, z = Mitte, Länge 3 im dritten Wert … als Vector3(x, z, Radius).
@export var plazas: Array[Vector3] = []
## Name je Platz (für die Karte).
@export var plaza_names: PackedStringArray = PackedStringArray()

@export_group("Start")
## Wo die Spielfigur startet (falls kein Ankerspiegel gespeichert ist).
@export var spawn_point: Vector3 = Vector3.ZERO

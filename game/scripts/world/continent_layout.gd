class_name ContinentLayout
extends Resource
## Bauplan des Kontinents: Größe, Küste, Regionen, Straßen, Fluss.
## Gleicher Seed = gleicher Kontinent.

@export var continent_name: String = "Aurion"
@export var seed: int = 4207
## Halbe Kantenlänge des Geländes (Meter). Gelände reicht von -half bis +half.
@export var half_size: float = 1100.0
## Abstand der Gitterpunkte des Geländes (Meter).
@export var cell_size: float = 8.0
## Ungefähre Entfernung der Küste von der Mitte.
@export var coast_radius: float = 960.0
@export var regions: Array[ContinentRegion] = []
## Landstraßen (Punkte in x, z).
@export var roads: Array[PackedVector2Array] = []
## Flussläufe (Punkte in x, z, von der Quelle zum Meer).
@export var rivers: Array[PackedVector2Array] = []
## Wo man ankommt, wenn man Santo Santiago durch das Südtor verlässt.
@export var city_gate_spawn: Vector3 = Vector3(0, 0, 252)

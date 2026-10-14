class_name CityDistrict
extends Resource
## Ein Bezirk von Santo Santiago: Fläche, Art, Aussehen, Höhe der Häuser.

enum Kind { CORPORATE, MARKET, QUARTER, SLUM }
enum Worship { NONE, CHURCH, MOSQUE, SYNAGOGUE, HOUSE_OF_SILENCE }

@export var display_name: String = ""
@export var kind: Kind = Kind.QUARTER
## Fläche in Weltkoordinaten: x (Ost) und z (Süd), in Metern.
@export var rect: Rect2 = Rect2(0, 0, 50, 50)

@export_group("Aussehen")
@export var ground_color: Color = Color(0.3, 0.3, 0.32)
## Wandfarben (zufällig gewählt).
@export var wall_colors: PackedColorArray = PackedColorArray([Color(0.6, 0.6, 0.62)])
@export var roof_color: Color = Color(0.3, 0.3, 0.32)
## Spitzdächer (true) oder Flachdächer (false).
@export var pitched_roofs: bool = false

@export_group("Häuser")
## Größe eines Grundstücks in Metern.
@export var lot_size: float = 14.0
## Höhe der Häuser am reichen (nördlichen) Rand …
@export var height_rich: Vector2 = Vector2(10, 18)
## … und am armen (südlichen) Rand des Bezirks.
@export var height_poor: Vector2 = Vector2(5, 9)
## Anteil leerer Grundstücke (Höfe, Plätze).
@export_range(0.0, 1.0) var empty_chance: float = 0.1
## Anteil Ruinen.
@export_range(0.0, 1.0) var ruin_chance: float = 0.0
## Leuchtstreifen an Hochhäusern (Cyberpunk).
@export var neon: bool = false

@export_group("Natur")
## Wie viele leuchtende Ranken pro Haus (Durchschnitt).
@export var vines_per_building: float = 2.0

@export_group("Wahrzeichen")
@export var worship: Worship = Worship.NONE

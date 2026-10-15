class_name CityDistrict
extends Resource
## Ein Bezirk von Santo Santiago. Bezirke haben keine geraden Grenzen: Jeder
## Punkt der Stadt gehört zu dem Bezirk, dessen Mitte (gewichtet mit `reach`)
## am nächsten liegt. Rauschen lässt die Grenzen natürlich ausfransen.

enum Kind { CORPORATE, MARKET, QUARTER, SLUM }
enum Worship { NONE, CHURCH, MOSQUE, SYNAGOGUE, HOUSE_OF_SILENCE }
## Bauweise der Häuser.
enum Style { IMPERIAL, MARKET, CHRISTIAN, MUSLIM, JEWISH, MODERN, SLUM }

## Kurzer Name für Code und Daten (z. B. &"muslim"); NPCs nutzen ihn als Zuhause.
@export var id: StringName = &""
@export var display_name: String = ""
@export var kind: Kind = Kind.QUARTER
@export var style: Style = Style.MODERN
## Mitte des Bezirks: x (Ost) und z (Süd), in Metern.
@export var center: Vector2 = Vector2.ZERO
## Wie weit der Bezirk reicht (größer = größerer Bezirk).
@export var reach: float = 1.0

@export_group("Aussehen")
@export var ground_color: Color = Color(0.3, 0.3, 0.32)
## Wandfarben (zufällig gewählt).
@export var wall_colors: PackedColorArray = PackedColorArray([Color(0.6, 0.6, 0.62)])
@export var roof_color: Color = Color(0.3, 0.3, 0.32)

@export_group("Häuser")
## Höhe der Häuser in reichen (nördlichen) Straßen …
@export var height_rich: Vector2 = Vector2(10, 18)
## … und in armen (südlichen) Straßen.
@export var height_poor: Vector2 = Vector2(5, 9)
## Abstand zwischen Nachbarhäusern (von … bis, Meter).
@export var gap: Vector2 = Vector2(0.5, 2.5)
## Abstand der Häuser von der Straße (von … bis, Meter).
@export var setback: Vector2 = Vector2(0.5, 2.5)
## Anteil Ruinen.
@export_range(0.0, 1.0) var ruin_chance: float = 0.0
## Anteil Lücken (Höfe, Gärten, kleine Plätze).
@export_range(0.0, 1.0) var empty_chance: float = 0.1
## Leuchtstreifen an Hochhäusern (Cyberpunk).
@export var neon: bool = false

@export_group("Straßen")
## Breite der Nebenstraßen und Gassen.
@export var street_width: float = 5.0
## Wie stark Gassen sich winden (0 = schnurgerade).
@export var street_wiggle: float = 0.25
## Abstand der Abzweigungen an Hauptstraßen.
@export var branch_spacing: float = 45.0

@export_group("Natur")
## Wie viele leuchtende Ranken pro Haus (Durchschnitt).
@export var vines_per_building: float = 2.0

@export_group("Wahrzeichen")
@export var worship: Worship = Worship.NONE
## Lage des Gotteshauses (Weltkoordinaten x, z).
@export var landmark_position: Vector2 = Vector2.ZERO

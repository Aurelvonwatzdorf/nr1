class_name ContinentRegion
extends Resource
## Eine Region (Zeitinsel) des Kontinents: Lage, Epoche, Stil, Farben,
## Gelände, Bewohner. Der ContinentGenerator baut daraus Gelände, Pflanzen und
## Wahrzeichen. Neue Region = neuer Eintrag in `continent.tres`.

## Bauweise und Wahrzeichen (siehe ContinentGenerator._build_landmarks).
enum Style {
	CITY, ## Hauptstadt (Skyline, Stadtmauer, Tor)
	WASTELAND, ## verwüstete Zukunft (Krater, Bohrtürme, Schrott)
	MOUNTAINS, ## Gebirge mit Schreinen und Bergtempel (japanisch inspiriert)
	STEPPE, ## Grasland der Reiterclans (mongolisch inspiriert)
	MEDIEVAL, ## Mittelalter (Burg, Dorf, Windmühle, Kapelle)
	MYSTIC_FOREST, ## leuchtender Geisterwald
	DESERT, ## Wüstenreich mit Fluss (altägyptisch inspiriert)
	PRESENT, ## Gegenwart (Vorstadt, Tankstelle, Stadion)
	FUTURE, ## ferne Zukunft (weiße Türme, Glaskuppeln, Schwebebahn)
}

@export var id: StringName = &""
@export var region_name: String = ""
## Epoche, erscheint unter dem Namen (Titelkarte).
@export var epoch: String = ""
@export_multiline var description: String = ""
@export var style: Style = Style.STEPPE
## Mitte (x, z) und ungefährer Radius in Metern.
@export var center: Vector2 = Vector2.ZERO
@export var radius: float = 300.0

@export_group("Gelände")
## Grundhöhe und Stärke der Hügel (Meter).
@export var base_height: float = 4.0
@export var relief: float = 10.0
## Wie fein die Hügel sind (größer = mehr kleine Hügel).
@export var relief_frequency: float = 0.004
@export var ground_color: Color = Color(0.4, 0.5, 0.3)
@export var accent_color: Color = Color(0.6, 0.6, 0.5)
## Wegfarbe in dieser Region.
@export var road_color: Color = Color(0.45, 0.38, 0.3)

@export_group("Leben")
## Anzahl Bäume/Pflanzen (wird auf die Fläche verteilt).
@export var plant_count: int = 200
@export var npc_count: int = 3
## Bewohner-Name (z. B. „Hirtin“, „Bauer“) und Sätze.
@export var npc_names: PackedStringArray = PackedStringArray()
@export_multiline var npc_lines: Array[String] = []
@export var npc_colors: Array[Color] = []

@export_group("Stimmung")
@export var fog_color: Color = Color(0.7, 0.75, 0.85)
@export var fog_density: float = 0.002

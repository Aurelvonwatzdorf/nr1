class_name CharacterData
extends Resource
## Alle Daten einer spielbaren Figur (Aurel, Tahirou …).
##
## Die Spielfigur (Player) liest beim Start nur diese Daten. Deshalb nutzen alle
## Figuren denselben Controller. Neue Werte hier ergänzen, nicht im Code verteilen.

@export var id: StringName = &""
@export var display_name: String = ""
@export_multiline var description: String = ""

@export_group("Werte")
@export var max_health: float = 100.0
@export var max_stamina: float = 100.0
@export var max_focus: float = 50.0
@export var stamina_regen_per_second: float = 35.0
@export var stamina_regen_delay: float = 0.8
## Fokus kommt langsam von selbst zurück (pro Sekunde).
@export var focus_regen_per_second: float = 1.5
## Leben regeneriert sich, wenn man so lange keinen Schaden genommen hat (Sekunden).
@export var health_regen_delay: float = 10.0
## Leben pro Sekunde während der Regeneration (in Schritten, einmal pro Sekunde).
@export var health_regen_per_second: float = 20.0

@export_group("Bewegung")
@export var walk_speed: float = 4.5
@export var sprint_speed: float = 7.5
@export var sprint_stamina_per_second: float = 18.0
@export var acceleration: float = 30.0
## Wie schnell sich die Figur zur Laufrichtung dreht.
@export var turn_speed: float = 12.0
## Startgeschwindigkeit nach oben beim Springen (Leertaste).
@export var jump_velocity: float = 6.0
@export var jump_stamina_cost: float = 8.0

@export_group("Ausweichrolle")
@export var dodge_speed: float = 9.0
@export var dodge_duration: float = 0.5
@export var dodge_stamina_cost: float = 20.0
## Unverwundbar von … bis … Sekunden nach Rollbeginn (I-Frames).
@export var dodge_iframe_start: float = 0.05
@export var dodge_iframe_end: float = 0.35

@export_group("Realitätsblick")
## Fokus-Kosten und Dauer des Realitätsblicks (Taste Q).
@export var reality_sight_cost: float = 15.0
@export var reality_sight_duration: float = 5.0

@export_group("Treffer")
## Wie lange die Figur nach einem Treffer taumelt.
@export var hurt_stagger_time: float = 0.35

@export_group("Blocken")
@export var block_move_speed: float = 2.0
## Anteil des Schadens, der beim Blocken abgefangen wird (0.8 = 80 %).
@export_range(0.0, 1.0) var block_damage_reduction: float = 0.8
## Ausdauerkosten pro Punkt abgefangenen Schadens.
@export var block_stamina_per_damage: float = 1.5
## So lange nach Blockbeginn zählt ein Treffer als Parade (Sekunden).
@export var parry_window: float = 0.2
## Taumelzeit, wenn die Deckung bricht (Ausdauer leer).
@export var guard_break_time: float = 0.9

@export_group("Angriffe")
@export var light_attack: AttackData
@export var heavy_attack: AttackData

@export_group("Besonderheit")
## Eigene Ressource der Figur: &"ambition" (Aurels Ehrgeiz), &"ravens" (Tahirous
## Rabenbund), leer = keine.
@export var special_resource: StringName = &""

@export_group("Darstellung")
## Farbe der Platzhalter-Kapsel, solange es kein Modell gibt.
@export var placeholder_color: Color = Color(0.8, 0.8, 0.8)
## Echtes Modell (später, z. B. aus Mixamo/Blender). Leer = Platzhalter-Kapsel.
@export var model_scene: PackedScene

@export_group("Ausrüstung")
## IDs der Startausrüstung (Inventar kommt in M3).
@export var starting_equipment: Array[StringName] = []

@export_group("Geschichte")
## Kurze Zeilen des Begleiters zu Spielbeginn (Dialogsystem kommt in M8).
@export var intro_lines: Array[String] = []
## Fähigkeitenbaum der Figur.
@export var skill_tree: SkillTreeData

extends Node
## Spielzustand über Szenen hinweg (Autoload „GameState“).
##
## Hier liegt alles, was ein Szenenwechsel nicht löschen darf: gewählte Figur,
## Währung, später Story-Fortschritt und freigeschaltete Fähigkeiten.

## Alle spielbaren Figuren als Daten-Resources (Schlüssel = CharacterData.id).
const CHARACTER_PATHS: Dictionary[StringName, String] = {
	&"aurel": "res://resources/characters/aurel.tres",
	&"tahirou": "res://resources/characters/tahirou.tres",
}

## Gewählte Figur. `null` heißt: Die Spielfigur nimmt die im Inspector eingestellte.
var selected_character: CharacterData = null

## Wo die Spielfigur nach dem Tod wiederbelebt wird.
var checkpoint_transform: Transform3D = Transform3D.IDENTITY
var has_checkpoint: bool = false

## Währung „Erinnerungen“.
var memories: int = 0:
	set(value):
		memories = maxi(value, 0)
		EventBus.memories_changed.emit(memories)


## Wählt eine Figur anhand ihrer ID (wird ab M4 vom Auswahlbildschirm genutzt).
func select_character(id: StringName) -> bool:
	if not CHARACTER_PATHS.has(id):
		push_warning("Unbekannte Figur: %s" % id)
		return false
	selected_character = load(CHARACTER_PATHS[id]) as CharacterData
	return selected_character != null


func set_checkpoint(at: Transform3D) -> void:
	checkpoint_transform = at
	has_checkpoint = true


## Speicherbare Daten als Dictionary (wird von SaveSystem genutzt).
func to_dict() -> Dictionary:
	return {
		"character_id": String(selected_character.id) if selected_character else "",
		"memories": memories,
	}


func from_dict(data: Dictionary) -> void:
	var character_id := StringName(str(data.get("character_id", "")))
	if character_id != &"":
		select_character(character_id)
	memories = int(data.get("memories", 0))

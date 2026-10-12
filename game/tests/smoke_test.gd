extends Node
## Automatischer Rauchtest ohne Bildschirm. Starten mit:
##   godot --headless --path game res://tests/smoke_test.tscn
## Lädt die Testarena, steuert die Figur per simulierter Eingabe und prüft,
## ob die Grundmechaniken funktionieren. Beendet Godot mit Code 0 (ok) oder 1.

const ARENA := preload("res://scenes/levels/test_arena.tscn")
const PLAYER_SCENE := preload("res://scenes/player/player.tscn")

var _failures: int = 0


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	var arena := ARENA.instantiate()
	add_child(arena)
	var player: Player = arena.get_node("Player")
	var dummy: TrainingDummy = arena.get_node("Dummies/TrainingDummy1")

	# Figur direkt vor die Puppe stellen (Puppe steht bei z = -4, Blick nach -Z).
	player.global_position = Vector3(0.0, 0.05, -2.5)
	player.rotation = Vector3.ZERO
	await _frames(20)
	_check(player.is_on_floor(), "Figur steht auf dem Boden")
	_check(player.state_machine.get_current_state_name() == &"idle", "Startzustand ist Idle")

	# Leichter Angriff
	var stamina_before := player.stamina.current
	await _tap(&"attack_light")
	_check(player.state_machine.get_current_state_name() == &"attack", "Angriff startet")
	await _frames(45)
	_check(is_equal_approx(dummy.health.current, 188.0), "Leichter Angriff macht 12 Schaden (ist: %s)" % dummy.health.current)
	_check(player.stamina.current < stamina_before, "Angriff kostet Ausdauer")

	# Schwerer Angriff (Shift + Linksklick)
	await _frames(60)
	player.global_position = Vector3(0.0, 0.05, -2.5)
	player.rotation = Vector3.ZERO
	Input.action_press(&"sprint")
	await _tap(&"attack_light")
	Input.action_release(&"sprint")
	await _frames(80)
	_check(is_equal_approx(dummy.health.current, 160.0), "Schwerer Angriff macht 28 Schaden (ist: %s)" % dummy.health.current)

	# Ausweichrolle mit I-Frames
	await _frames(60)
	var saw_iframes := false
	await _tap(&"dodge")
	_check(player.state_machine.get_current_state_name() == &"dodge", "Ausweichen startet")
	for i in 40:
		await get_tree().physics_frame
		saw_iframes = saw_iframes or player.hurtbox.invulnerable
	_check(saw_iframes, "Ausweichrolle hat I-Frames")
	_check(not player.hurtbox.invulnerable, "I-Frames enden wieder")

	# Treffer während I-Frames prallen ab
	player.hurtbox.invulnerable = true
	var hit := HitData.new()
	hit.damage = 50.0
	_check(player.hurtbox.receive_hit(hit) == Hurtbox.Result.IGNORED, "Treffer in I-Frames zählt nicht")
	player.hurtbox.invulnerable = false
	var result := player.hurtbox.receive_hit(hit)
	_check(result == Hurtbox.Result.HIT and is_equal_approx(player.health.current, 50.0), "Treffer ohne I-Frames macht Schaden")
	await _frames(2)
	_check(player.state_machine.get_current_state_name() == &"hurt", "Getroffene Figur taumelt")

	# Ausdauer regeneriert
	var low := player.stamina.current
	await _frames(120)
	_check(player.stamina.current > low, "Ausdauer regeneriert sich")

	# Gegner bemerkt, verfolgt und greift an
	var guard: Enemy = arena.get_node("Enemies/Guard1")
	player.health.revive()
	player.global_position = guard.global_position + Vector3(0.0, 0.05, 3.0)
	player.rotation = Vector3.ZERO
	await _frames(10)
	_check(guard.state_machine.get_current_state_name() in [&"chase", &"attack"], "Gegner bemerkt die Spielfigur")
	var hp_before := player.health.current
	var saw_attack := false
	for i in 300:
		await get_tree().physics_frame
		saw_attack = saw_attack or guard.state_machine.get_current_state_name() == &"attack"
		if player.health.current < hp_before:
			break
	_check(saw_attack, "Gegner holt zum Angriff aus")
	_check(player.health.current < hp_before, "Gegnerangriff macht Schaden (Leben: %s)" % player.health.current)

	# Spielfigur trifft den Gegner, er taumelt
	await _frames(30)
	player.snap_towards(player.global_position.direction_to(guard.global_position))
	var guard_hp := guard.health.current
	await _tap(&"attack_light")
	var saw_stagger := false
	for i in 30:
		await get_tree().physics_frame
		saw_stagger = saw_stagger or guard.state_machine.get_current_state_name() == &"stagger"
	_check(guard.health.current < guard_hp, "Spielfigur trifft den Gegner")
	_check(saw_stagger, "Getroffener Gegner taumelt")

	# Gegner besiegen: Erinnerungen, tot, nicht mehr anvisierbar
	var memories_before := GameState.memories
	guard.health.take_damage(1000.0)
	await _frames(2)
	_check(guard.state_machine.get_current_state_name() == &"dead", "Gegner stirbt")
	_check(GameState.memories == memories_before + 50, "Sieg bringt 50 Erinnerungen")
	_check(not guard.is_targetable(), "Toter Gegner ist nicht anvisierbar")
	guard.reset_enemy()
	await _frames(2)
	_check(guard.state_machine.get_current_state_name() in [&"idle", &"chase"] and guard.health.current == guard.health.max_value, "Gegner lässt sich zurücksetzen")
	player.global_position = Vector3(0.0, 0.05, 2.0)
	await _frames(5)

	# Figur aus Daten laden (Tahirou)
	_check(GameState.select_character(&"tahirou"), "Tahirou kann gewählt werden")
	var tahirou: Player = PLAYER_SCENE.instantiate()
	add_child(tahirou)
	_check(tahirou.character_data.display_name == "Tahirou", "Spielfigur lädt Tahirous Daten")
	GameState.selected_character = null

	print("")
	print("RAUCHTEST: %s" % ("BESTANDEN" if _failures == 0 else "%d FEHLER" % _failures))
	get_tree().quit(0 if _failures == 0 else 1)


## Drückt eine Taste kurz. Die Figur sieht den Druck im nächsten Physik-Frame,
## deshalb zwei Frames halten, bevor losgelassen wird.
func _tap(action: StringName) -> void:
	await get_tree().physics_frame
	Input.action_press(action)
	await _frames(2)
	Input.action_release(action)


func _frames(count: int) -> void:
	for i in count:
		await get_tree().physics_frame


func _check(condition: bool, description: String) -> void:
	print("%s %s" % ["[OK]  " if condition else "[FEHLER]", description])
	if not condition:
		_failures += 1

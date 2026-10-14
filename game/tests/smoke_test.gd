extends Node
## Automatischer Rauchtest ohne Bildschirm. Starten mit:
##   godot --headless --path game res://tests/smoke_test.tscn
## Lädt die Testarena, steuert die Figur per simulierter Eingabe und prüft,
## ob die Grundmechaniken funktionieren. Beendet Godot mit Code 0 (ok) oder 1.

const ARENA := preload("res://scenes/levels/test_arena.tscn")
const PLAYER_SCENE := preload("res://scenes/player/player.tscn")

var _failures: int = 0


func _ready() -> void:
	# Hitstop verlangsamt die Zeit, das würde die Frame-Zählung im Test verfälschen.
	HitStop.enabled = false
	# Eigener Spielstand für den Test, nichts automatisch laden.
	SaveSystem.auto_load_enabled = false
	GameState.ask_character_on_new_game = false
	SaveSystem.save_path = "user://smoke_test_save.json"
	SaveSystem.delete_save()
	GameState.reset()
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
	player.get_ambition().spend_all()
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

	# Ausweichen nach rechts: Richtung kurz NACH der Leertaste gedrückt
	await _frames(60)
	player.stamina.refill()
	player.rotation = Vector3.ZERO
	var dodge_start := player.global_position
	await get_tree().physics_frame
	Input.action_press(&"dodge")
	await _frames(3)
	Input.action_press(&"move_right")
	await _frames(2)
	Input.action_release(&"dodge")
	await _frames(20)
	Input.action_release(&"move_right")
	var moved := player.global_position - dodge_start
	_check(moved.x > 1.0 and absf(moved.z) < 0.5, "D kurz nach Leertaste: Rolle nach rechts (x %.1f, z %.1f)" % [moved.x, moved.z])
	await _frames(30)

	# Blocken und Parieren (Treffer kommt von vorne)
	player.health.revive()
	player.stamina.refill()
	player.rotation = Vector3.ZERO
	await _frames(2)
	Input.action_press(&"block")
	await _frames(2)
	_check(player.state_machine.get_current_state_name() == &"block", "Rechtsklick halten blockt")
	var front_hit := HitData.new()
	front_hit.damage = 20.0
	front_hit.direction = Vector3(0.0, 0.0, 1.0)
	_check(player.hurtbox.receive_hit(front_hit) == Hurtbox.Result.PARRIED and player.health.current == player.health.max_value, "Treffer direkt nach Blockbeginn wird pariert")
	await _frames(20)
	var stamina_before_block := player.stamina.current
	front_hit = HitData.new()
	front_hit.damage = 20.0
	front_hit.direction = Vector3(0.0, 0.0, 1.0)
	_check(player.hurtbox.receive_hit(front_hit) == Hurtbox.Result.BLOCKED, "Späterer Treffer wird geblockt")
	_check(is_equal_approx(player.health.current, player.health.max_value - 4.0), "Block fängt 80 %% Schaden ab (Leben: %s)" % player.health.current)
	_check(player.stamina.current < stamina_before_block, "Blocken kostet Ausdauer")
	var back_hit := HitData.new()
	back_hit.damage = 10.0
	back_hit.direction = Vector3(0.0, 0.0, -1.0)
	_check(player.hurtbox.receive_hit(back_hit) == Hurtbox.Result.HIT, "Treffer von hinten geht durch den Block")
	Input.action_release(&"block")
	await _frames(30)
	player.health.revive()
	player.stamina.refill()

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
	var blood_found := not arena.find_children("*", "CPUParticles3D", true, false).is_empty()
	_check(blood_found, "Treffer auf die Wache lässt Blut spritzen")
	_check(saw_stagger, "Getroffener Gegner taumelt")

	# Parierter Gegner ist lange wehrlos
	await _frames(40)
	guard._on_hit_landed(player.hurtbox, HitData.new(), Hurtbox.Result.PARRIED)
	await _frames(45)
	_check(guard.state_machine.get_current_state_name() == &"stagger", "Parierter Gegner ist nach 0,75 s noch wehrlos")

	# Gegner besiegen: Erinnerungen, tot, nicht mehr anvisierbar
	var memories_before := GameState.memories
	var money_before := GameState.money
	guard.health.take_damage(1000.0)
	await _frames(2)
	_check(GameState.money == money_before + 15, "Sieg bringt 15 Geld")
	_check(guard.state_machine.get_current_state_name() == &"dead", "Gegner stirbt")
	_check(GameState.memories == memories_before + 50, "Sieg bringt 50 Erinnerungen")
	_check(not guard.is_targetable(), "Toter Gegner ist nicht anvisierbar")
	guard.reset_enemy()
	await _frames(2)
	_check(guard.state_machine.get_current_state_name() in [&"idle", &"chase"] and guard.health.current == guard.health.max_value, "Gegner lässt sich zurücksetzen")
	player.global_position = Vector3(0.0, 0.05, 2.0)
	await _frames(5)

	# Hitstop: verlangsamt kurz und stellt die Zeit wieder her
	HitStop.enabled = true
	HitStop.apply(0.05)
	_check(Engine.time_scale < 1.0, "Hitstop verlangsamt die Zeit")
	await get_tree().create_timer(0.1, true, false, true).timeout
	_check(is_equal_approx(Engine.time_scale, 1.0), "Nach dem Hitstop läuft die Zeit normal")
	HitStop.enabled = false

	# Lock-on: nächstes Ziel vor der Kamera, zweiter Druck löst
	await _tap(&"lock_on")
	_check(player.get_lock_target() == dummy, "Lock-on wählt die Puppe direkt vor der Kamera")
	await _frames(30)
	var cam_forward := -player.camera_rig.camera.global_basis.z
	var to_dummy := player.camera_rig.camera.global_position.direction_to(dummy.global_position)
	_check(cam_forward.dot(to_dummy) > 0.9, "Kamera schaut beim Lock-on aufs Ziel")
	await _tap(&"lock_on")
	_check(player.get_lock_target() == null, "Zweiter Druck löst den Lock-on")

	# Tod: Erinnerungen bleiben liegen, Wiederbelebung am Checkpoint
	var manager: RespawnManager = arena.get_node("RespawnManager")
	manager.respawn_delay = 0.5
	var start_checkpoint := GameState.checkpoint_transform
	GameState.memories = 120
	player.global_position = Vector3(5.0, 0.05, 0.0)
	await _frames(5)
	player.health.take_damage(1000.0)
	await _frames(3)
	_check(player.state_machine.get_current_state_name() == &"dead", "Figur stirbt")
	var remnant := manager.get_remnant()
	_check(remnant != null and remnant.amount == 120 and GameState.memories == 0, "120 Erinnerungen bleiben an der Todesstelle liegen")
	await get_tree().create_timer(0.8).timeout
	_check(not player.health.is_dead and player.state_machine.get_current_state_name() == &"idle", "Figur wird wiederbelebt")
	_check(player.global_position.distance_to(start_checkpoint.origin) < 0.5, "Wiederbelebung am Checkpoint")
	_check(guard.state_machine.get_current_state_name() == &"idle" and guard.global_position.distance_to(guard.home_transform.origin) < 0.5, "Gegner werden zurückgesetzt")

	# Erinnerungen zurückholen
	player.global_position = remnant.global_position - Vector3.UP * 0.6
	await _frames(5)
	_check(GameState.memories == 120 and manager.get_remnant() == null, "Erinnerungen an der Todesstelle zurückgeholt")

	# Zweimal sterben: die alten Erinnerungen sind weg
	GameState.memories = 30
	player.global_position = Vector3(5.0, 0.05, 0.0)
	await _frames(3)
	player.health.take_damage(1000.0)
	await get_tree().create_timer(0.8).timeout
	player.health.take_damage(1000.0)
	await _frames(3)
	_check(manager.get_remnant() == null and GameState.memories == 0, "Erneuter Tod: alte Erinnerungen endgültig verloren")
	_check(GameState.money > 0, "Geld bleibt beim Tod erhalten")
	await get_tree().create_timer(0.8).timeout

	# Ankerspiegel: E zeigt „Rasten“, Rasten heilt und setzt Wiederbelebungsort
	var mirror: AnchorMirror = arena.get_node("AnchorMirrors/MirrorWest")
	player.global_position = mirror.spawn_point.global_position
	player.health.take_damage(30.0)
	await _frames(30)
	_check(player.interaction_detector.current == mirror, "Ankerspiegel ist in Reichweite")
	await _tap(&"interact")
	await _frames(2)
	_check(mirror.is_active(), "Rasten macht den Spiegel zum Wiederbelebungsort")
	_check(is_equal_approx(player.health.current, player.health.max_value), "Rasten heilt voll")
	var rest_menu: RestMenu = arena.get_node("RestMenu")
	_check(rest_menu.is_open and get_tree().paused, "Rast-Menü öffnet sich, Spiel pausiert")
	GameState.memories = 150
	_check(rest_menu.try_increase(&"endurance") and GameState.stats.endurance == 2, "Im Rast-Menü Ausdauer erhöhen")
	_check(not rest_menu.try_increase(&"endurance"), "Zweite Stufe zu teuer (50 übrig, 112 nötig)")
	rest_menu.close()
	_check(not get_tree().paused and player.is_input_enabled(), "Menü schließen: Spiel läuft weiter")
	GameState.stats.from_dict({})
	GameState.memories = 0
	var pause_menu: PauseMenu = arena.get_node("PauseMenu")
	pause_menu.open()
	_check(get_tree().paused and not player.is_input_enabled(), "Pausenmenü pausiert, keine Steuerung")
	pause_menu.close()
	player.global_position = Vector3(0.0, 0.05, 2.0)
	await _frames(10)
	_check(player.interaction_detector.current == null, "Weit weg: keine Interaktion")

	# Stats: Leveln mit Erinnerungen, abgeleitete Werte
	player.get_ambition().spend_all()
	var stats := GameState.stats
	_check(stats.get_level() == 1 and stats.get_level_up_cost() == 100, "Start: Stufe 1, nächste Stufe kostet 100")
	GameState.memories = 50
	_check(not GameState.try_level_up(&"strength"), "Zu wenig Erinnerungen: kein Level-Up")
	GameState.memories = 1000
	_check(GameState.try_level_up(&"resistance") and GameState.memories == 900, "Level-Up kostet 100 Erinnerungen")
	_check(is_equal_approx(player.health.max_value, 108.0), "Widerstand +1 gibt +8 Leben (max: %s)" % player.health.max_value)
	_check(stats.get_level_up_cost() == 112, "Nächste Stufe ist teurer (112)")
	_check(not GameState.try_level_up(&"spirituality"), "Spiritualität lässt sich nicht mit Erinnerungen leveln")
	GameState.try_level_up(&"strength")
	dummy.health.revive()
	player.global_position = Vector3(0.0, 0.05, -2.5)
	player.rotation = Vector3.ZERO
	await _frames(10)
	await _tap(&"attack_light")
	await _frames(45)
	_check(is_equal_approx(dummy.health.current, 200.0 - 12.6), "Stärke +1 gibt +5 %% Schaden (Puppe: %s)" % dummy.health.current)
	GameState.stats.from_dict({})
	GameState.memories = 0
	player.global_position = Vector3(0.0, 0.05, 2.0)
	await _frames(3)

	# Gegenstände: aufheben, Heiltrank trinken, Artefakte
	var inventory := GameState.inventory
	var potion_pickup: ItemPickup = arena.get_node("Pickups/PotionsNearStart")
	player.global_position = potion_pickup.global_position + Vector3(0.0, 0.05, 0.8)
	await _frames(10)
	_check(player.interaction_detector.current == potion_pickup, "Heiltränke in Reichweite")
	await _tap(&"interact")
	await _frames(3)
	_check(inventory.get_count(&"healing_potion") == 2, "2 Heiltränke aufgehoben")
	_check(GameState.collected_pickups.has(&"arena_potions_start"), "Fundort gilt als eingesammelt")
	player.health.take_damage(60.0)
	await _frames(25)
	var hp_before_potion := player.health.current
	await _tap(&"heal")
	_check(player.state_machine.get_current_state_name() == &"use_item", "R: Figur trinkt")
	await _frames(50)
	_check(is_equal_approx(player.health.current, hp_before_potion + 50.0) and inventory.get_count(&"healing_potion") == 1, "Heiltrank heilt 50 und wird verbraucht")
	var max_hp := player.health.max_value
	inventory.add(&"heart_amulet")
	_check(is_equal_approx(player.health.max_value, max_hp + 15.0), "Dauerhaftes Artefakt: +15 maximales Leben")
	inventory.remove(&"heart_amulet")
	player.get_ambition().spend_all()
	var multiplier := player.get_damage_multiplier()
	inventory.add(&"power_ampoule")
	player.use_item(ItemDatabase.get_item(&"power_ampoule"))
	await _frames(40)
	_check(is_equal_approx(player.get_damage_multiplier(), multiplier + 0.25), "Kraftampulle: +25 % Schaden")
	_check(not inventory.has(&"power_ampoule"), "Verbrauchbares Artefakt ist danach weg")
	player.damage_buff_time_left = 0.01
	await _frames(3)
	_check(is_equal_approx(player.get_damage_multiplier(), multiplier), "Buff läuft ab")
	var inventory_menu: InventoryMenu = arena.get_node("InventoryMenu")
	await _send_action(&"inventory")
	_check(inventory_menu.is_open, "I öffnet das Inventar")
	inventory_menu.close()
	player.global_position = Vector3(0.0, 0.05, 2.0)
	await _frames(3)

	# Händler: ansprechen, Tränke kaufen
	var merchant: Merchant = arena.get_node("NPCs/Merchant")
	var dialogue: DialogueBox = arena.get_node("DialogueBox")
	GameState.money = 0
	var potions_before := GameState.inventory.get_count(&"healing_potion")
	player.global_position = merchant.global_position + Vector3(0.0, 0.05, -1.5)
	await _frames(10)
	_check(player.interaction_detector.current == merchant.talk_area, "Händler in Reichweite")
	await _tap(&"interact")
	await _frames(2)
	_check(dialogue.is_open and get_tree().paused, "Gespräch öffnet sich, Spiel pausiert")
	dialogue.choose(0)
	await _frames(2)
	_check(GameState.inventory.get_count(&"healing_potion") == potions_before, "Ohne Geld kein Kauf")
	GameState.money = 100
	dialogue.choose(0)
	await _frames(2)
	_check(GameState.inventory.get_count(&"healing_potion") == potions_before + 1 and GameState.money == 60, "Heiltrank für 40 Geld gekauft")
	dialogue.choose(2)
	await _frames(2)
	_check(not dialogue.is_open and not get_tree().paused, "„Tschüss“ beendet das Gespräch")
	player.global_position = Vector3(0.0, 0.05, 2.0)
	await _frames(3)

	# Mission: alte Frau über die Straße
	var woman: OldWoman = arena.get_node("NPCs/OldWoman")
	var charity_before := GameState.moral.get_virtue_score(&"charity")
	var money_before_mission := GameState.money
	player.global_position = woman.global_position + Vector3(0.0, 0.05, -1.5)
	await _frames(10)
	await _tap(&"interact")
	await _frames(2)
	dialogue.choose(0)
	await _frames(2)
	dialogue.choose(0)
	await _frames(2)
	_check(GameState.get_mission_status(&"help_old_woman") == GameState.MissionStatus.ACTIVE, "Mission angenommen")
	_check(woman.mode == OldWoman.Mode.FOLLOWING and GameState.get_active_missions().size() == 1, "Alte Frau folgt, Mission wird angezeigt")
	var destination: Area3D = arena.get_node("Street/WomanDestination")
	player.global_position = destination.global_position + Vector3(0.0, 0.05, 0.5)
	for i in 400:
		await get_tree().physics_frame
		if woman.mode == OldWoman.Mode.ARRIVED:
			break
	_check(GameState.get_mission_status(&"help_old_woman") == GameState.MissionStatus.COMPLETED, "Alte Frau kommt an, Mission erfüllt")
	_check(GameState.money == money_before_mission + 10, "Belohnung: 10 Geld")
	_check(GameState.moral.get_virtue_score(&"charity") == charity_before + 2, "Gute Tat im Moral-Gedächtnis")

	# Mission: kranker Mann (erst ohne Trank, dann mit)
	var sick: SickMan = arena.get_node("NPCs/SickMan")
	var potions_owned := GameState.inventory.get_count(&"healing_potion")
	GameState.inventory.remove(&"healing_potion", potions_owned)
	player.global_position = sick.global_position + Vector3(0.0, 0.05, -1.5)
	await _frames(10)
	await _tap(&"interact")
	await _frames(2)
	dialogue.choose(0)
	await _frames(2)
	dialogue.choose(0)
	await _frames(2)
	_check(GameState.get_mission_status(&"heal_sick_man") == GameState.MissionStatus.ACTIVE, "Ohne Trank: Mission „später wiederkommen“")
	GameState.inventory.add(&"healing_potion", potions_owned)
	await _frames(5)
	await _tap(&"interact")
	await _frames(2)
	dialogue.choose(0)
	await _frames(2)
	dialogue.choose(0)
	await _frames(2)
	_check(GameState.get_mission_status(&"heal_sick_man") == GameState.MissionStatus.COMPLETED, "Heiltrank gegeben, Mission erfüllt")
	_check(GameState.inventory.get_count(&"healing_potion") == potions_owned - 1, "Der Trank ist weg")
	_check(GameState.get_active_missions().is_empty() and not dialogue.is_open, "Keine offenen Missionen mehr")
	player.global_position = Vector3(0.0, 0.05, 2.0)
	await _frames(3)

	# Unschuldige NPCs verletzen: Moral sinkt, Tote bleiben tot
	var mercy_before := GameState.moral.get_virtue_score(&"mercy")
	var attack := HitData.new()
	attack.damage = 10.0
	attack.source = player
	merchant.hurtbox.receive_hit(attack)
	await _frames(2)
	_check(merchant.is_fleeing(), "Angegriffener NPC flieht")
	_check(GameState.moral.get_virtue_score(&"mercy") == mercy_before - 3, "Angriff auf Unschuldigen senkt die Barmherzigkeit")
	var second := HitData.new()
	second.damage = 10.0
	second.source = player
	merchant.hurtbox.receive_hit(second)
	_check(GameState.moral.get_virtue_score(&"mercy") == mercy_before - 3, "Weitere Schläge auf denselben NPC zählen nur einmal")
	var guard_hit := HitData.new()
	guard_hit.damage = 5.0
	guard_hit.source = guard
	var protection_before := GameState.moral.get_virtue_score(&"protection")
	sick.hurtbox.receive_hit(guard_hit)
	_check(GameState.moral.get_virtue_score(&"protection") == protection_before and not GameState.moral.has_deed(&"hurt_test_sick_man"), "Treffer von Gegnern zählen nicht gegen die Spielfigur")
	var fatal := HitData.new()
	fatal.damage = 100.0
	fatal.source = player
	merchant.hurtbox.receive_hit(fatal)
	await _frames(2)
	_check(GameState.dead_npcs.has(&"test_merchant"), "Getöteter NPC wird gemerkt")
	_check(GameState.moral.get_virtue_score(&"protection") == protection_before - 10, "Töten zählt schwer (-10)")

	# Moral-Gedächtnis
	var moral := GameState.moral
	_check(moral.record(&"test_helped_elder", &"charity", 2, "Einer alten Frau geholfen"), "Gute Tat wird gemerkt")
	_check(not moral.record(&"test_helped_elder", &"charity", 2, "doppelt"), "Dieselbe Tat zählt nur einmal")
	moral.record(&"test_cruelty", &"mercy", -3, "Wehrlosen verletzt")
	_check(moral.get_score() == 5 - 3 - 10 + 2 - 3, "Moral-Werte werden zusammengezählt (%d)" % moral.get_score())

	# Speichern und Laden
	_check(SaveSystem.has_save(), "Rasten am Ankerspiegel hat automatisch gespeichert")
	GameState.memories = 77
	GameState.money = 123
	GameState.stats.set_stat(&"strength", 3)
	GameState.inventory.add(&"heart_amulet")
	var saved_checkpoint := GameState.checkpoint_transform
	var saved_potions := GameState.inventory.get_count(&"healing_potion")
	_check(SaveSystem.save_game(), "Speichern klappt")
	GameState.reset()
	_check(GameState.memories == 0 and GameState.stats.strength == 1, "Zurücksetzen löscht alles")
	_check(SaveSystem.load_game(), "Laden klappt")
	_check(GameState.memories == 77 and GameState.stats.strength == 3, "Erinnerungen und Stats geladen")
	_check(GameState.money == 123, "Geld geladen")
	_check(GameState.inventory.has(&"heart_amulet") and GameState.inventory.get_count(&"healing_potion") == saved_potions, "Inventar geladen")
	_check(GameState.collected_pickups.has(&"arena_potions_start"), "Aufgehobene Gegenstände bleiben weg")
	_check(GameState.has_checkpoint and GameState.checkpoint_transform.is_equal_approx(saved_checkpoint), "Ankerspiegel-Ort geladen")
	_check(GameState.moral.get_score() == -9, "Moral-Gedächtnis geladen")
	_check(GameState.dead_npcs.has(&"test_merchant"), "Tote NPCs geladen")
	_check(GameState.get_mission_status(&"help_old_woman") == GameState.MissionStatus.COMPLETED, "Missionsstand geladen")
	SaveSystem.delete_save()
	GameState.reset()

	# Charakterauswahl
	var select_menu: CharacterSelectMenu = arena.get_node("CharacterSelectMenu")
	select_menu.open()
	_check(select_menu.is_open and get_tree().paused, "Charakterauswahl öffnet sich")
	select_menu.choose(&"tahirou")
	await _frames(2)
	_check(not select_menu.is_open and player.character_data.id == &"tahirou", "Tahirou gewählt, Spielfigur übernimmt ihn")
	_check(SaveSystem.has_save(), "Wahl wird sofort gespeichert")
	select_menu.choose(&"aurel")
	select_menu.open()
	select_menu.choose(&"aurel")
	await _frames(2)
	_check(player.character_data.id == &"aurel", "Wechsel zurück zu Aurel")
	SaveSystem.delete_save()

	# Fähigkeiten: Punkte durch Level-Up, Reihenfolge, Story-Sperre
	var tree_data := player.character_data.skill_tree
	_check(tree_data != null and tree_data.branches.size() == 3 and tree_data.skills.size() == 9, "Aurel hat einen Baum mit 3 Ästen und 9 Fähigkeiten")
	var hunger := tree_data.get_skill(&"aurel_hunger")
	var chain := tree_data.get_skill(&"aurel_chain_strikes")
	var summit := tree_data.get_skill(&"aurel_summit")
	_check(not GameState.try_unlock_skill(hunger), "Ohne Punkte nichts lernen")
	GameState.memories = 1000
	GameState.try_level_up(&"strength")
	GameState.try_level_up(&"strength")
	GameState.try_level_up(&"strength")
	_check(GameState.skill_points == 3, "3 Level-Ups geben 3 Fähigkeitspunkte")
	_check(not GameState.try_unlock_skill(chain), "Zweite Fähigkeit braucht die erste")
	var skill_menu: SkillTreeMenu = arena.get_node("SkillTreeMenu")
	await _send_action(&"skills")
	_check(skill_menu.is_open, "K öffnet den Fähigkeitenbaum")
	_check(skill_menu.try_unlock(hunger) and GameState.has_skill(&"aurel_hunger"), "„Hunger“ gelernt")
	_check(skill_menu.try_unlock(chain), "„Kettenschläge“ danach lernbar")
	_check(GameState.get_skill_status(summit) == GameState.SkillStatus.STORY_LOCKED, "„Gipfelsturm“ ist an die Story gebunden")
	GameState.set_story_flag(&"first_boss_defeated")
	_check(skill_menu.try_unlock(summit) and GameState.skill_points == 0, "Nach dem Story-Fortschritt lernbar")
	skill_menu.close()
	var saved_skills := GameState.to_dict()
	GameState.reset()
	GameState.from_dict(saved_skills)
	_check(GameState.has_skill(&"aurel_summit") and GameState.has_story_flag(&"first_boss_defeated"), "Fähigkeiten und Story werden gespeichert")
	GameState.reset()
	await _frames(3)

	# Aurels Ehrgeiz
	var ambition := player.get_ambition()
	_check(ambition != null and is_equal_approx(ambition.current, 0.0), "Aurel hat Ehrgeiz, startet bei 0")
	dummy.health.revive()
	player.stamina.refill()
	player.global_position = Vector3(0.0, 0.05, -2.5)
	player.rotation = Vector3.ZERO
	await _frames(10)
	await _tap(&"attack_light")
	await _frames(40)
	_check(is_equal_approx(ambition.current, 12.0), "Treffer gibt 12 Ehrgeiz (%.1f)" % ambition.current)
	ambition.add(100.0)
	var mult_full := player.get_damage_multiplier()
	_check(is_equal_approx(mult_full, 1.2), "Voller Ehrgeiz: +20 %% Schaden (%.2f)" % mult_full)
	var hp_ambition := player.health.current
	var hit_on_aurel := HitData.new()
	hit_on_aurel.damage = 5.0
	player.hurtbox.receive_hit(hit_on_aurel)
	_check(is_equal_approx(ambition.current, 75.0), "Getroffen: -25 Ehrgeiz")
	await _frames(30)
	ambition._time_since_hit = 10.0
	var before_decay := ambition.current
	await _frames(30)
	_check(ambition.current < before_decay, "Ohne Angriffe schwindet der Ehrgeiz")
	player.health.revive()

	# Aurels Fähigkeiten im Kampf
	GameState.unlocked_skills.append_array([&"aurel_sparks", &"aurel_embers", &"aurel_badge", &"aurel_weak_spots", &"aurel_wildfire", &"aurel_summit"])
	_check(is_equal_approx(guard.get_detection_radius(), 6.0), "Firmenausweis: Wachen sehen nur noch 6 statt 10 Meter")
	var weak_spot := player._modify_outgoing_damage(guard.hurtbox, 10.0)
	ambition.spend_all()
	_check(is_equal_approx(player._modify_outgoing_damage(guard.hurtbox, 10.0), 11.5), "Schwachstellenwissen: +15 %% gegen Konzern")
	ambition.add(60.0)
	_check(is_equal_approx(player._modify_outgoing_damage(dummy.hurtbox, 10.0), 15.0), "Funkenschlag: +5 ab halbem Ehrgeiz")
	_check(weak_spot >= 11.5, "Boni addieren sich")
	guard.global_position = player.global_position + Vector3(0.0, 0.0, -2.0)
	guard.apply_burn(3.0, 3.0)
	var guard_hp_burn := guard.health.current
	await _frames(60)
	_check(guard.health.current < guard_hp_burn and guard.health.current > guard_hp_burn - 4.0, "Glutnarben: Gegner brennt (3 pro Sekunde)")
	guard.health.revive()
	guard.attack_cooldown_left = 100.0
	player.health.revive()
	player.state_machine.transition_to(&"idle")
	await _frames(5)
	ambition.add(100.0)
	ambition._time_since_hit = 0.0
	player.stamina.refill()
	var stamina_full := player.stamina.current
	await _tap(&"attack_heavy")
	_check(player.state_machine.get_current_state_name() == &"attack", "Schwerer Angriff startet")
	await _frames(3)
	_check(is_equal_approx(player.stamina.current, stamina_full), "Gipfelsturm: voller Ehrgeiz, Angriff kostet keine Ausdauer")
	_check(guard.health.current <= guard.health.max_value - 25.0 and is_equal_approx(ambition.current, 0.0), "Lauffeuer: Feuerwelle trifft und verbraucht den Ehrgeiz")
	await _frames(60)
	GameState.unlocked_skills.clear()
	guard.reset_enemy()
	player.global_position = Vector3(0.0, 0.05, 2.0)
	await _frames(5)

	# Figur aus Daten laden (Tahirou)
	_check(GameState.select_character(&"tahirou"), "Tahirou kann gewählt werden")
	var tahirou: Player = PLAYER_SCENE.instantiate()
	add_child(tahirou)
	_check(tahirou.character_data.display_name == "Tahirou", "Spielfigur lädt Tahirous Daten")
	GameState.selected_character = null

	# Spielstart mit Spielstand: lädt vor dem Aufbau der Welt
	var west_mirror: AnchorMirror = arena.get_node("AnchorMirrors/MirrorWest")
	GameState.reset()
	GameState.memories = 33
	GameState.collected_pickups.append(&"arena_potions_start")
	GameState.dead_npcs.append(&"test_merchant")
	GameState.set_checkpoint(west_mirror.spawn_point.global_transform)
	SaveSystem.save_game()
	GameState.reset()
	arena.queue_free()
	tahirou.queue_free()
	await _frames(3)
	SaveSystem.auto_load_enabled = true
	var loaded_arena := ARENA.instantiate()
	add_child(loaded_arena)
	await _frames(5)
	var loaded_player: Player = loaded_arena.get_node("Player")
	_check(GameState.memories == 33, "Start lädt den Spielstand")
	_check(loaded_player.global_position.distance_to(GameState.checkpoint_transform.origin) < 0.5, "Start am gespeicherten Ankerspiegel")
	_check(not loaded_arena.has_node("Pickups/PotionsNearStart"), "Aufgehobener Gegenstand liegt nicht mehr da")
	_check(not loaded_arena.has_node("NPCs/Merchant") or loaded_arena.get_node("NPCs/Merchant").is_queued_for_deletion(), "Toter Händler bleibt nach dem Laden weg")
	SaveSystem.delete_save()

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


## Schickt eine echte Eingabe (für Menüs, die auf _unhandled_input hören).
func _send_action(action: StringName) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = true
	Input.parse_input_event(event)
	await _frames(2)
	event = InputEventAction.new()
	event.action = action
	event.pressed = false
	Input.parse_input_event(event)
	await _frames(1)


func _frames(count: int) -> void:
	for i in count:
		await get_tree().physics_frame


func _check(condition: bool, description: String) -> void:
	print("%s %s" % ["[OK]  " if condition else "[FEHLER]", description])
	if not condition:
		_failures += 1

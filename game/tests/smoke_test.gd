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
	GameState.test_start_money = 0
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
	var body_material := player.body_mesh.material_override as StandardMaterial3D
	_check(body_material.diffuse_mode == BaseMaterial3D.DIFFUSE_TOON and body_material.next_pass != null, "Gezeichneter Look: Toon-Schattierung und Umriss")
	var floor_mesh: MeshInstance3D = arena.get_node("Floor/Mesh")
	_check((floor_mesh.mesh.surface_get_material(0) as BaseMaterial3D).diffuse_mode == BaseMaterial3D.DIFFUSE_TOON, "Auch die Arena ist umgestellt")
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

	# Realitätsblick (Q): kostet Fokus, zeigt Dinge der wahren Welt
	var hidden_path := RealityLayerObject.new()
	var path_body := StaticBody3D.new()
	path_body.collision_layer = PhysicsLayers.WORLD
	hidden_path.add_child(path_body)
	hidden_path.position = Vector3(30.0, 0.0, 30.0)
	arena.add_child(hidden_path)
	var false_wall := RealityLayerObject.new()
	false_wall.exists_in = RealityLayerObject.Layer.ILLUSION
	false_wall.position = Vector3(32.0, 0.0, 30.0)
	arena.add_child(false_wall)
	_check(not hidden_path.is_present() and path_body.collision_layer == 0 and false_wall.is_present(), "Ohne Realitätsblick: versteckter Weg fehlt, Illusion steht")
	player.focus.refill()
	var focus_before := player.focus.current
	await _tap(&"reality_sight")
	var overlay: RealitySightOverlay = arena.get_node("GameUI/RealitySightOverlay")
	_check(GameState.reality_sight_active and player.focus.current < focus_before - 14.0, "Q: Realitätsblick kostet 15 Fokus")
	_check(hidden_path.is_present() and path_body.collision_layer == PhysicsLayers.WORLD and not false_wall.is_present(), "Mit Realitätsblick: Weg da und begehbar, Illusion weg")
	_check(overlay.visible, "Bildschirm zeigt die wahre Welt")
	await _frames(int(player.character_data.reality_sight_duration * 60.0) + 10)
	_check(not GameState.reality_sight_active and not hidden_path.is_present() and false_wall.is_present(), "Nach 5 Sekunden endet der Blick")
	player.focus.remove(player.focus.current)
	_check(not player.start_reality_sight() and not GameState.reality_sight_active, "Ohne Fokus kein Realitätsblick")
	player.focus.refill()
	hidden_path.queue_free()
	false_wall.queue_free()

	# Springen (Leertaste)
	await _frames(40)
	player.stamina.refill()
	var floor_y := player.global_position.y
	await _tap(&"jump")
	var max_y := floor_y
	for i in 20:
		await get_tree().physics_frame
		max_y = maxf(max_y, player.global_position.y)
	_check(max_y > floor_y + 0.8, "Leertaste springt (Höhe %.2f)" % (max_y - floor_y))
	await _frames(60)
	_check(player.is_on_floor(), "Figur landet wieder")

	# Doppelsprung nur mit Cyberbeinen
	var single_peak := floor_y + 2.0
	for with_legs: bool in [false, true]:
		if with_legs:
			GameState.inventory.add(&"cyber_legs")
		player.stamina.refill()
		await _tap(&"jump")
		await _frames(12)
		await _tap(&"jump")
		var peak := floor_y
		for i in 40:
			await get_tree().physics_frame
			peak = maxf(peak, player.global_position.y)
		if with_legs:
			_check(peak > single_peak + 0.5, "Cyberbeine: zweiter Sprung in der Luft (Höhe %.2f)" % (peak - floor_y))
		else:
			_check(peak < single_peak, "Ohne Cyberbeine kein Doppelsprung (Höhe %.2f)" % (peak - floor_y))
		await _frames(80)
	GameState.inventory.remove(&"cyber_legs")
	_check(player.is_on_floor(), "Nach dem Doppelsprung wieder am Boden")

	# Leben regeneriert nach 10 s ohne Schaden in 20er-Schritten
	var hp_regen_start := player.health.current
	player.health.time_since_damage = 9.5
	await _frames(30)
	_check(is_equal_approx(player.health.current, hp_regen_start), "Vor 10 s keine Regeneration")
	await _frames(70)
	_check(is_equal_approx(player.health.current, minf(hp_regen_start + 20.0, player.health.max_value)), "Nach 10 s: +20 Leben pro Sekunde (ist %.0f)" % player.health.current)
	player.health.take_damage(player.health.current - hp_regen_start)

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
	_check(remnant != null and not remnant.find_children("*", "MapMarker", true, false).is_empty(), "Erinnerungen sind auf der Karte markiert")
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
	var rest_menu: RestMenu = arena.get_node("GameUI/RestMenu")
	_check(rest_menu.is_open and get_tree().paused, "Rast-Menü öffnet sich, Spiel pausiert")
	GameState.memories = 150
	_check(rest_menu.try_increase(&"endurance") and GameState.stats.endurance == 2, "Im Rast-Menü Ausdauer erhöhen")
	_check(not rest_menu.try_increase(&"endurance"), "Zweite Stufe zu teuer (50 übrig, 112 nötig)")
	rest_menu.close()
	_check(not get_tree().paused and player.is_input_enabled(), "Menü schließen: Spiel läuft weiter")
	GameState.stats.from_dict({})
	GameState.memories = 0
	var pause_menu: PauseMenu = arena.get_node("GameUI/PauseMenu")
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
	var inventory_menu: InventoryMenu = arena.get_node("GameUI/InventoryMenu")
	await _send_action(&"inventory")
	_check(inventory_menu.is_open, "I öffnet das Inventar")
	inventory_menu.close()
	player.global_position = Vector3(0.0, 0.05, 2.0)
	await _frames(3)

	# Händler: ansprechen, Tränke kaufen
	var merchant: Merchant = arena.get_node("NPCs/Merchant")
	var dialogue: DialogueBox = arena.get_node("GameUI/DialogueBox")
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
	# Ausrüstung: Munition, Pistole, Waffen, Implantate, Radar
	GameState.money = 1000
	merchant.stock.append(ItemDatabase.get_item(&"pistol_ammo"))
	merchant.prices.append(30)
	merchant.stock.append(ItemDatabase.get_item(&"pistol"))
	merchant.prices.append(250)
	_check(merchant.buy(merchant.stock.size() - 2) and GameState.inventory.get_count(&"pistol_ammo") == 12, "Munition: 12 Schuss pro Kauf")
	_check(merchant.buy(merchant.stock.size() - 1) and GameState.equipped_firearm == &"pistol", "Gekaufte Pistole wird gleich ausgerüstet")
	_check(not merchant.buy(merchant.stock.size() - 1) and GameState.money == 1000 - 280, "Eine Pistole kauft man nur einmal")
	merchant.stock.resize(merchant.stock.size() - 2)
	merchant.prices.resize(merchant.prices.size() - 2)
	var sword := ItemDatabase.get_item(&"short_sword")
	GameState.inventory.add(&"short_sword")
	GameState.toggle_equip(sword)
	_check(is_equal_approx(player.get_light_attack().damage, 15.0) and is_equal_approx(player.get_heavy_attack().damage, 32.0), "Kurzschwert ersetzt die Grundangriffe")
	GameState.toggle_equip(sword)
	_check(is_equal_approx(player.get_light_attack().damage, 12.0), "Abgelegt: wieder Grundangriff")
	dummy.health.revive()
	player.global_position = dummy.global_position + Vector3(0.0, 0.05, 6.0)
	player.state_machine.transition_to(&"idle")
	player.lock_on.set_target(dummy)
	await _frames(3)
	var dummy_hp := dummy.health.current
	_check(player.fire_firearm() and dummy.health.current < dummy_hp and GameState.inventory.get_count(&"pistol_ammo") == 11, "V: Pistole trifft das Ziel (Puppe: %.0f)" % dummy.health.current)
	_check(not player.fire_firearm(), "Kurze Pause zwischen zwei Schüssen")
	await _frames(40)
	GameState.inventory.remove(&"pistol_ammo", GameState.inventory.get_count(&"pistol_ammo"))
	_check(not player.fire_firearm(), "Ohne Munition kein Schuss")
	player.lock_on.set_target(null)
	var speed_before := player.get_speed_multiplier()
	GameState.inventory.add(&"leg_servos")
	_check(is_equal_approx(player.get_speed_multiplier(), speed_before + 0.1), "Implantat Beinservos: +10 % Tempo")
	GameState.inventory.add(&"dermal_plating")
	player.health.revive()
	var plated_hit := HitData.new()
	plated_hit.damage = 20.0
	player.hurtbox.receive_hit(plated_hit)
	_check(is_equal_approx(player.health.current, player.health.max_value - 17.0), "Implantat Dermalpanzerung: −15 % Schaden")
	_check(not GameState.inventory.has_radar(), "Ohne Radar keine Gegner auf der Karte")
	GameState.inventory.add(&"radar_system")
	_check(GameState.inventory.has_radar(), "Radarsystem zeigt Gegner auf der Karte")
	for id: StringName in [&"leg_servos", &"dermal_plating", &"radar_system", &"pistol", &"short_sword"]:
		GameState.inventory.remove(id)
	GameState.equipped_firearm = &""
	player.health.revive()
	# Der Schuss hat die Leute erschreckt; warten, bis sie sich beruhigt haben.
	await _frames(260)
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

	# Karte: Marker, erledigte Missionen verschwinden, M öffnet die große Karte
	var markers := get_tree().get_nodes_in_group(&"map_markers")
	_check(markers.size() >= 5, "Karte kennt Händler, Ankerspiegel und Missionen (%d Marker)" % markers.size())
	var woman_marker: MapMarker = arena.get_node("NPCs/OldWoman/WomanMarker")
	_check(not woman_marker.is_shown(), "Erledigte Mission verschwindet von der Karte")
	var map_menu: WorldMapMenu = arena.get_node("GameUI/WorldMapMenu")
	await _send_action(&"map")
	await _frames(2)
	_check(map_menu.is_open and map_menu.legend.get_child_count() >= 2, "M öffnet die große Karte mit Legende")
	_check(get_tree().paused, "Bei offener Karte steht die Zeit still")
	await _send_action(&"map")
	_check(not map_menu.is_open and not get_tree().paused, "M schließt sie wieder, die Zeit läuft weiter")

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
	var select_menu: CharacterSelectMenu = arena.get_node("GameUI/CharacterSelectMenu")
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
	var skill_menu: SkillTreeMenu = arena.get_node("GameUI/SkillTreeMenu")
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

	# Tahirou: Rabenbund, Rabenschwarm, Gaben der Ahnen
	player.apply_character(load("res://resources/characters/tahirou.tres") as CharacterData)
	await _frames(2)
	var ravens := player.get_ravens()
	_check(ravens != null and player.get_ambition() == null and is_equal_approx(ravens.current, 0.0), "Tahirou hat den Rabenbund (startet bei 0), keinen Ehrgeiz")
	var gifts: Array[String] = []
	EventBus.raven_gift_granted.connect(func(gift_name: String, _text: String) -> void: gifts.append(gift_name))
	player.global_position = Vector3(-9.0, 0.05, -10.0)
	player.rotation = Vector3.ZERO
	guard.global_position = guard.home_transform.origin
	guard.state_machine.transition_to(&"idle")
	await _frames(10)
	player.health.revive()
	player.stamina.refill()
	Input.action_press(&"block")
	await _frames(2)
	var parry_hit := HitData.new()
	parry_hit.damage = 10.0
	parry_hit.direction = Vector3(0.0, 0.0, 1.0)
	player.hurtbox.receive_hit(parry_hit)
	Input.action_release(&"block")
	_check(is_equal_approx(ravens.current, 30.0), "Perfekte Parade: +30 Rabenbund")
	for node in get_tree().get_nodes_in_group(&"enemies"):
		(node as Enemy).attack_cooldown_left = 100.0
	guard.state_machine.transition_to(&"chase")
	await _frames(320)
	_check(ravens.current >= 40.0, "5 Sekunden ruhig kämpfen ohne Treffer: +10 (%.0f)" % ravens.current)
	player.state_machine.transition_to(&"idle")
	_check(not player.call_raven_swarm(), "Unter 50 Rabenbund kein Schwarm")
	ravens.add(55.0 - ravens.current)
	player.lock_on.set_target(guard)
	await _tap(&"call_spirit")
	await _frames(2)
	_check(guard.state_machine.get_current_state_name() == &"stagger" and guard.raven_mark_hits_left == 1, "F: Rabenschwarm unterbricht die Wache und markiert sie")
	_check(ravens.current < 10.0, "Schwarm kostet 50 Rabenbund")
	_check(is_equal_approx(player._modify_outgoing_damage(guard.hurtbox, 10.0), 20.0), "Rabenmal: nächster Treffer doppelter Schaden")
	_check(guard.raven_mark_hits_left == 0, "Rabenmal ist danach verbraucht")
	player.lock_on.set_target(null)
	var ravens_before_defenseless := ravens.current
	player.global_position = guard.global_position + Vector3(0.0, 0.05, 1.5)
	player.snap_towards(Vector3(0.0, 0.0, -1.0))
	guard.state_machine.transition_to(&"stagger", {"time": 1.0, "parried": true})
	await _tap(&"attack_light")
	await _frames(20)
	_check(ravens.current >= ravens_before_defenseless + 15.0, "Treffer auf wehrlosen Gegner: +15 Rabenbund")
	gifts.clear()
	ravens._last_gift_at = -100.0
	ravens._gift_ready_at.clear()
	player.health.take_damage(player.health.current - 10.0)
	await _frames(5)
	_check(gifts.has("Federkleid") and ravens.feather_cloak_left > 0.0 and player.health.current >= 25.0, "Wenig Leben: Ahnen leihen das Federkleid (+15 Leben)")
	var cloak_hit := HitData.new()
	cloak_hit.damage = 10.0
	var hp_cloak := player.health.current
	player.hurtbox.receive_hit(cloak_hit)
	_check(is_equal_approx(player.health.current, hp_cloak - 5.0), "Federkleid halbiert den Schaden")
	ravens.feather_cloak_left = 0.0
	ravens._last_gift_at = -100.0
	player.health.revive()
	player.stamina.consume(1000.0)
	await _frames(3)
	_check(gifts.has("Zweiter Atem") and player.stamina.current > player.stamina.max_value * 0.9, "Ausdauer leer: Zweiter Atem füllt sie auf")
	player.health.revive()
	await _frames(40)

	# Tahirous Fähigkeitenbaum
	var t_tree := player.character_data.skill_tree
	_check(t_tree != null and t_tree.branches == ["Rabenbund", "Vollstrecker", "Stille"] and t_tree.skills.size() == 9, "Tahirou hat einen eigenen Baum: Rabenbund, Vollstrecker, Stille")
	var default_window := player.get_parry_window()
	GameState.unlocked_skills.append_array([&"tahirou_execution", &"tahirou_fear", &"tahirou_no_mercy", &"tahirou_steady_hand", &"tahirou_clear_eye"])
	_check(is_equal_approx(player.get_parry_window(), default_window + 0.1), "Ruhige Hand: Parierfenster +0,1 s")
	guard.reset_enemy()
	await _frames(3)
	var guard2: Enemy = arena.get_node("Enemies/Guard2")
	guard2.global_position = guard.global_position + Vector3(3.0, 0.0, 0.0)
	guard2.attack_cooldown_left = 0.0
	player.global_position = guard.global_position + Vector3(0.0, 0.05, 1.5)
	player.snap_towards(Vector3(0.0, 0.0, -1.0))
	player.health.take_damage(30.0)
	var hp_before_execution := player.health.current
	guard.state_machine.transition_to(&"stagger", {"time": 1.0, "parried": true})
	var guard_hp_exec := guard.health.current
	await _tap(&"attack_light")
	await _frames(20)
	_check(guard_hp_exec - guard.health.current >= 35.0, "Hinrichtung: dreifacher Schaden auf wehrlose Wache (%.0f)" % (guard_hp_exec - guard.health.current))
	_check(guard2.attack_cooldown_left >= 2.5, "Furcht: andere Wache zögert")
	_check(player.health.current >= hp_before_execution + 14.0, "Ohne Gnade: Hinrichtung heilt")
	player.lock_on.set_target(guard)
	guard.state_machine.transition_to(&"chase")
	await _frames(2)
	_check(is_equal_approx(player._modify_outgoing_damage(guard.hurtbox, 10.0), 11.5), "Klarer Blick: +15 % aufs anvisierte Ziel")
	player.lock_on.set_target(null)
	GameState.unlocked_skills.clear()
	guard2.reset_enemy()
	guard.reset_enemy()
	player.apply_character(load("res://resources/characters/aurel.tres") as CharacterData)
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

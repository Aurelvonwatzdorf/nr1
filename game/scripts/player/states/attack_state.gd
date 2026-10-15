class_name PlayerAttackState
extends PlayerState
## Leichter oder schwerer Angriff in drei Phasen:
## Ausholen → Trefferphase (Hitbox an) → Erholung.
## In der Erholung kann man den nächsten Angriff puffern (Kombo) oder ausweichen.

enum Phase { STARTUP, ACTIVE, RECOVERY }

var _attack: AttackData
var _phase: Phase = Phase.STARTUP
var _time: float = 0.0
## Gepufferter Folgeangriff: -1 = keiner, 0 = leicht, 1 = schwer.
var _buffered: int = -1
var _heavy: bool = false


func is_heavy() -> bool:
	return _heavy


func enter(msg: Dictionary = {}) -> void:
	var heavy: bool = msg.get("heavy", false)
	var heavy_attack := player.get_heavy_attack()
	_attack = heavy_attack if heavy and heavy_attack else player.get_light_attack()
	_heavy = _attack == heavy_attack
	_phase = Phase.STARTUP
	_time = 0.0
	_buffered = -1
	player.combo_count = msg.get("combo", 1)
	var ambition := player.get_ambition()
	var free_attack := ambition != null and ambition.is_full() and GameState.has_skill(&"aurel_summit")
	if not free_attack:
		player.stamina.consume(_attack.stamina_cost)
	if _heavy and ambition and ambition.is_full() and GameState.has_skill(&"aurel_wildfire"):
		player.release_wildfire()
	# Mit Lock-on zielt der Schlag aufs Ziel, sonst in Laufrichtung.
	var aim := player.get_direction_to_lock_target()
	player.snap_towards(aim if aim != Vector3.ZERO else player.get_move_direction())
	player.animator.play_attack(_attack)


func exit() -> void:
	player.hitbox.deactivate()


func physics_update(delta: float) -> void:
	_time += delta
	player.apply_gravity(delta)
	_update_phase()
	_read_buffered_input()

	if _phase == Phase.RECOVERY:
		player.accelerate_to(Vector3.ZERO, delta)
		# Abbrechen durch Ausweichen ist in der Erholung erlaubt.
		if player.is_input_enabled() and player.stamina.can_act() and Input.is_action_just_pressed(&"dodge"):
			state_machine.transition_to(&"dodge")
			return
	else:
		# Kurzer Schub nach vorn beim Zuschlagen.
		var lunge := player.get_facing_direction() * _attack.lunge_speed
		player.velocity.x = lunge.x
		player.velocity.z = lunge.z

	if _time >= _attack.get_total_time():
		if _buffered >= 0 and player.stamina.can_act():
			state_machine.transition_to(&"attack", {"heavy": _buffered == 1, "combo": player.combo_count + 1})
		else:
			return_to_locomotion()


func _update_phase() -> void:
	if _phase == Phase.STARTUP and _time >= _attack.startup_time:
		_phase = Phase.ACTIVE
		player.hitbox.activate(_attack.damage * player.get_damage_multiplier(), _attack.knockback)
	if _phase == Phase.ACTIVE and _time >= _attack.startup_time + _attack.active_time:
		_phase = Phase.RECOVERY
		player.hitbox.deactivate()


func _read_buffered_input() -> void:
	# Eingaben ab der Trefferphase werden für den nächsten Schlag gemerkt.
	if _phase == Phase.STARTUP or not player.is_input_enabled():
		return
	if is_heavy_attack_pressed():
		_buffered = 1
	elif Input.is_action_just_pressed(&"attack_light"):
		_buffered = 0

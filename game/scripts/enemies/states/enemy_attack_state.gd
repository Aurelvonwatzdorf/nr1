class_name EnemyAttackState
extends EnemyState
## Angriff: Ausholen (leuchtet als Warnung, dreht sich noch zur Spielfigur)
## → Trefferphase (Richtung fest) → Erholung (Zeit zum Kontern).

enum Phase { STARTUP, ACTIVE, RECOVERY }

var _attack: AttackData
var _phase: Phase = Phase.STARTUP
var _time: float = 0.0


func enter(_msg: Dictionary = {}) -> void:
	_attack = enemy.data.attack
	_phase = Phase.STARTUP
	_time = 0.0
	enemy.set_telegraph(true)
	EventBus.enemy_attack_started.emit(enemy)


func exit() -> void:
	enemy.hitbox.deactivate()
	enemy.set_telegraph(false)
	enemy.attack_cooldown_left = enemy.data.attack_cooldown


func physics_update(delta: float) -> void:
	_time += delta
	match _phase:
		Phase.STARTUP:
			enemy.accelerate_to(Vector3.ZERO, delta)
			var player := enemy.get_player()
			if player:
				enemy.turn_towards(enemy.direction_to_node(player), delta)
			if _time >= _attack.startup_time:
				_phase = Phase.ACTIVE
				enemy.set_telegraph(false)
				enemy.hitbox.activate(_attack.damage, _attack.knockback)
		Phase.ACTIVE:
			var lunge := enemy.get_facing_direction() * _attack.lunge_speed
			enemy.velocity.x = lunge.x
			enemy.velocity.z = lunge.z
			if _time >= _attack.startup_time + _attack.active_time:
				_phase = Phase.RECOVERY
				enemy.hitbox.deactivate()
		Phase.RECOVERY:
			enemy.accelerate_to(Vector3.ZERO, delta)
			if _time >= _attack.get_total_time():
				state_machine.transition_to(&"chase")

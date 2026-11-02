class_name PlayerTakedownState
extends PlayerState
## Lautlos erledigen: einen ahnungslosen Gegner von hinten packen. E kurz =
## betäuben (2 s, er bleibt bewusstlos liegen), E halten = töten (1 s, leise,
## aber blutig). Wird man dabei getroffen, reißt er sich los und ist alarmiert.
## Moral (Nutzer-Entscheidung): Töten von hinten ist neutral; erst wer einen
## Bewusstlosen tötet, tötet einen Wehrlosen (siehe Enemy._on_died()).

var _enemy: Enemy
var _time: float = 0.0
## Noch offen, ob betäubt oder getötet wird (entscheidet sich nach `takedown_hold_time`).
var _decided: bool = false
var _kill: bool = false
var _finished: bool = false


func enter(msg: Dictionary = {}) -> void:
	_enemy = msg.get("enemy")
	_time = 0.0
	_decided = false
	_kill = false
	_finished = false
	player.velocity = Vector3.ZERO
	if _enemy == null:
		return_to_locomotion()
		return
	var facing := _enemy.get_facing_direction()
	player.global_position = _enemy.global_position - facing * 0.8 + Vector3.UP * (player.global_position.y - _enemy.global_position.y)
	player.snap_towards(facing)
	_enemy.start_grabbed()
	player.animator.play(&"use_item", 0.4)


func exit() -> void:
	if _enemy and not _finished and is_instance_valid(_enemy):
		_enemy.break_free(player)
	_enemy = null


func physics_update(delta: float) -> void:
	var data := player.character_data
	player.velocity = Vector3.ZERO
	_time += delta
	if not _decided:
		if not Input.is_action_pressed(&"interact"):
			_decided = true
		elif _time >= data.takedown_hold_time:
			_decided = true
			_kill = true
	var duration := data.takedown_kill_time if _kill else data.takedown_stun_time
	if _decided and _time >= duration:
		_finished = true
		if _kill:
			_enemy.silent_kill(player)
		else:
			_enemy.knock_out()
		return_to_locomotion()

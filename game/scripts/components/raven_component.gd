class_name RavenComponent
extends StatPoolComponent
## Tahirous Rabenbund (0 bis 100): die Raben aus der Geisterwelt, mit denen sein
## Clan seit Generationen in Symbiose lebt.
##
## Füllt sich durch präzises, ruhiges Spiel. Ab `get_swarm_cost()` kann man mit F
## einen Rabenschwarm rufen. Außerdem **leihen die alten Raben (die Ahnen)** in
## brenzligen Situationen von selbst kurz eine Gabe (nicht zu oft):
## - Federkleid (wenig Leben): erlittener Schaden halbiert, etwas Heilung.
## - Rabenauge (Gegner holt aus): die Zeit verlangsamt sich kurz.
## - Flügelschlag (umzingelt): Gegner ringsum zögern.
## - Zweiter Atem (Ausdauer leer): Ausdauer sofort voll.

@export var parry_gain: float = 30.0
@export var defenseless_hit_gain: float = 15.0
## Ruhiges Kämpfen: alle `calm_interval` Sekunden ohne erlittenen Treffer.
@export var calm_gain: float = 10.0
@export var calm_interval: float = 5.0
## Gleiche Gabe frühestens nach so vielen Sekunden wieder.
@export var gift_cooldown: float = 30.0
## Mindestabstand zwischen zwei Gaben.
@export var gift_min_gap: float = 8.0

## Name und Satz der Ahnen je Gabe.
const GIFTS: Dictionary[StringName, Array] = {
	&"feather_cloak": ["Federkleid", "Unsere Federn tragen, was du nicht tragen kannst."],
	&"raven_eye": ["Rabenauge", "Sieh, wie wir sehen."],
	&"wing_beat": ["Flügelschlag", "Wir sind viele. Sie sind wenige."],
	&"second_breath": ["Zweiter Atem", "Nimm von unserem Atem, Twin."],
}
const FEATHER_CLOAK_TIME := 8.0
const FEATHER_CLOAK_HEAL := 15.0
const RAVEN_EYE_TIME := 1.2
const RAVEN_EYE_TIME_SCALE := 0.4
const WING_BEAT_RADIUS := 6.0
const WING_BEAT_TIME := 2.5

var _player: Player
var _calm_time: float = 0.0
var _clock: float = 0.0
var _last_gift_at: float = -100.0
var _gift_ready_at: Dictionary[StringName, float] = {}
## Restzeit des Federkleids (Sekunden).
var feather_cloak_left: float = 0.0


func _ready() -> void:
	super._ready()
	current = 0.0
	_player = get_parent() as Player
	EventBus.enemy_attack_started.connect(_on_enemy_attack_started)


func _physics_process(delta: float) -> void:
	_clock += delta
	feather_cloak_left = maxf(feather_cloak_left - delta, 0.0)
	if _player == null or _player.health.is_dead:
		return
	if count_engaged_enemies(10.0) > 0:
		_calm_time += delta
		if _calm_time >= calm_interval:
			_calm_time -= calm_interval
			gain(calm_gain)
	else:
		_calm_time = 0.0
	_check_gifts()


func gain(amount: float) -> void:
	if GameState.has_skill(&"tahirou_old_voices"):
		amount *= 1.25
	add(amount)


func on_perfect_parry() -> void:
	gain(parry_gain)


func on_defenseless_hit() -> void:
	gain(defenseless_hit_gain)


func on_got_hit() -> void:
	_calm_time = 0.0


func get_swarm_cost() -> float:
	return 35.0 if GameState.has_skill(&"tahirou_ancestral_raven") else 50.0


func can_call_swarm() -> bool:
	return current >= get_swarm_cost()


## Faktor für erlittenen Schaden (Federkleid halbiert ihn).
func get_damage_taken_factor() -> float:
	return 0.5 if feather_cloak_left > 0.0 else 1.0


## Gegner im Umkreis, die gerade kämpfen (verfolgen, angreifen, taumeln).
func count_engaged_enemies(radius: float) -> int:
	var count := 0
	for enemy in _engaged_enemies(radius):
		count += 1
	return count


func _engaged_enemies(radius: float) -> Array[Enemy]:
	var result: Array[Enemy] = []
	for node: Node in get_tree().get_nodes_in_group(&"enemies"):
		var enemy := node as Enemy
		if enemy == null or enemy.health.is_dead:
			continue
		if enemy.global_position.distance_to(_player.global_position) > radius:
			continue
		if enemy.state_machine.get_current_state_name() in [&"chase", &"attack", &"stagger"]:
			result.append(enemy)
	return result


## Die Ahnen leihen eine Gabe. Gibt false zurück, wenn es gerade zu früh ist.
func grant_gift(gift: StringName) -> bool:
	if _clock < _gift_ready_at.get(gift, 0.0) or _clock - _last_gift_at < gift_min_gap:
		return false
	_gift_ready_at[gift] = _clock + gift_cooldown
	_last_gift_at = _clock
	match gift:
		&"feather_cloak":
			feather_cloak_left = FEATHER_CLOAK_TIME
			_player.health.heal(FEATHER_CLOAK_HEAL)
		&"raven_eye":
			HitStop.apply(RAVEN_EYE_TIME, RAVEN_EYE_TIME_SCALE)
		&"wing_beat":
			for enemy in _engaged_enemies(WING_BEAT_RADIUS):
				enemy.hesitate(WING_BEAT_TIME)
		&"second_breath":
			_player.stamina.refill()
	EventBus.raven_gift_granted.emit(GIFTS[gift][0], GIFTS[gift][1])
	return true


func _check_gifts() -> void:
	if _player.health.get_ratio() < 0.3:
		grant_gift(&"feather_cloak")
	elif _player.stamina.is_empty():
		grant_gift(&"second_breath")
	elif count_engaged_enemies(8.0) >= 3:
		grant_gift(&"wing_beat")


func _on_enemy_attack_started(enemy: Enemy) -> void:
	if _player == null or _player.health.is_dead:
		return
	if enemy.global_position.distance_to(_player.global_position) > 5.0:
		return
	if _player.state_machine.get_current_state_name() in [&"dodge", &"block"]:
		return
	grant_gift(&"raven_eye")

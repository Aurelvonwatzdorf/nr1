class_name RavenComponent
extends StatPoolComponent
## Tahirous Rabenbund (0 bis 100): die Raben aus der Geisterwelt, mit denen sein
## Clan seit Generationen in Symbiose lebt.
##
## Füllt sich durch präzises, ruhiges Spiel. Ab `get_swarm_cost()` kann man mit F
## einen Rabenschwarm rufen. Außerdem geben die alten Raben in brenzligen
## Situationen von selbst Ratschläge (nicht zu oft).

@export var parry_gain: float = 30.0
@export var defenseless_hit_gain: float = 15.0
## Ruhiges Kämpfen: alle `calm_interval` Sekunden ohne erlittenen Treffer.
@export var calm_gain: float = 10.0
@export var calm_interval: float = 5.0
## Gleicher Ratschlag frühestens nach so vielen Sekunden wieder.
@export var advice_cooldown: float = 12.0
## Mindestabstand zwischen zwei Ratschlägen.
@export var advice_min_gap: float = 4.0

const NUMBER_WORDS: Dictionary[int, String] = {3: "Drei", 4: "Vier", 5: "Fünf", 6: "Sechs"}

var _player: Player
var _calm_time: float = 0.0
var _clock: float = 0.0
var _last_advice_at: float = -100.0
var _advice_ready_at: Dictionary[StringName, float] = {}


func _ready() -> void:
	super._ready()
	current = 0.0
	_player = get_parent() as Player
	EventBus.enemy_attack_started.connect(_on_enemy_attack_started)


func _physics_process(delta: float) -> void:
	_clock += delta
	if _player == null or _player.health.is_dead:
		return
	if count_engaged_enemies(10.0) > 0:
		_calm_time += delta
		if _calm_time >= calm_interval:
			_calm_time -= calm_interval
			gain(calm_gain)
	else:
		_calm_time = 0.0
	_check_advice()


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


## Gegner im Umkreis, die gerade kämpfen (verfolgen, angreifen, taumeln).
func count_engaged_enemies(radius: float) -> int:
	var count := 0
	for node: Node in get_tree().get_nodes_in_group(&"enemies"):
		var enemy := node as Enemy
		if enemy == null or enemy.health.is_dead:
			continue
		if enemy.global_position.distance_to(_player.global_position) > radius:
			continue
		if enemy.state_machine.get_current_state_name() in [&"chase", &"attack", &"stagger"]:
			count += 1
	return count


## Ein Ratschlag der Raben. Gibt false zurück, wenn es gerade zu früh ist.
func advise(kind: StringName, text: String) -> bool:
	if _clock < _advice_ready_at.get(kind, 0.0) or _clock - _last_advice_at < advice_min_gap:
		return false
	_advice_ready_at[kind] = _clock + advice_cooldown
	_last_advice_at = _clock
	EventBus.raven_advice.emit(text)
	return true


func _check_advice() -> void:
	if _player.health.get_ratio() < 0.3:
		advise(&"low_health", "Du blutest, Twin. Zieh dich zurück.")
	elif _player.stamina.is_empty():
		advise(&"no_stamina", "Atme. Erst atmen, dann schlagen.")
	else:
		var engaged := count_engaged_enemies(8.0)
		if engaged >= 3:
			advise(&"surrounded", "%s von ihnen. Kämpf nicht in ihrer Mitte." % NUMBER_WORDS.get(engaged, "So viele"))


func _on_enemy_attack_started(enemy: Enemy) -> void:
	if _player == null or _player.health.is_dead:
		return
	if enemy.global_position.distance_to(_player.global_position) > 5.0:
		return
	if _player.state_machine.get_current_state_name() in [&"dodge", &"block"]:
		return
	advise(&"attack", "Er holt aus. Weich aus.")

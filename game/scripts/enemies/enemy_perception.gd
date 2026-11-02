class_name EnemyPerception
extends Node
## Wahrnehmung eines Gegners (Schleichgang): Sichtkegel mit Sichtstrahl, Verdacht
## 0–1, der sich füllt, solange er die Spielfigur sieht (schneller, je näher),
## und langsam wieder sinkt. Ganz nah merkt er es immer. Lärm (`EventBus.noise_made`,
## Schüsse, Rennen in der Nähe) lässt ihn nachsehen. Voller Verdacht = alarmiert.
## Über dem Kopf zeigt ein „?“ den Verdacht, „!“ den Alarm. In Spiegelrealitäten
## ist die Anzeige versteckt und nur mit dem Realitätsblick sichtbar
## (Kernmechanik 3: „sie ahnen etwas“).

## Lärm von Schüssen und Treffern (Meter).
const SHOT_NOISE_RADIUS := 25.0
const HIT_NOISE_RADIUS := 12.0

var enemy: Enemy
## Verdacht 0–1; bei 1 ist er alarmiert.
var awareness: float = 0.0
var alerted: bool = false
## Wo er die Spielfigur zuletzt gesehen/gehört hat.
var last_known_position: Vector3 = Vector3.ZERO
## Etwas gehört oder kurz gesehen: dort nachsehen (Suchen-Zustand).
var wants_to_investigate: bool = false
## Sieht er die Spielfigur gerade?
var sees_player: bool = false

var _indicator: Label3D


func setup(owner_enemy: Enemy) -> void:
	enemy = owner_enemy
	_indicator = Label3D.new()
	_indicator.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_indicator.no_depth_test = true
	_indicator.font_size = 64
	_indicator.outline_size = 12
	_indicator.position = Vector3(0.0, 2.6, 0.0)
	_indicator.visible = false
	enemy.add_child.call_deferred(_indicator)
	EventBus.noise_made.connect(hear)
	EventBus.shot_fired.connect(func(from: Vector3) -> void: hear(from, SHOT_NOISE_RADIUS))


## Jeden Physik-Frame vom Gegner aufgerufen (mit Welt-Tempo-`delta`).
func update(delta: float) -> void:
	var player := enemy.get_player()
	sees_player = false
	if player == null or enemy.health.is_dead:
		_fade(delta)
		_update_indicator()
		return
	var data := enemy.data
	var distance := enemy.global_position.distance_to(player.global_position)
	var crouched := player.is_crouched()
	var near := data.near_radius_crouched if crouched else data.near_radius
	if distance <= near:
		sees_player = true
		_notice(player, 1.0)
	elif can_see(player):
		sees_player = true
		var sight := get_sight_range(player)
		var notice_time := lerpf(data.notice_time_near, data.notice_time_far, clampf(distance / sight, 0.0, 1.0))
		_notice(player, delta / maxf(notice_time, 0.05))
	elif distance <= data.hear_running_radius and _is_running(player):
		_notice(player, delta / 0.6)
	else:
		_fade(delta)
	_update_indicator()


## Liegt die Spielfigur im Sichtkegel, in Sichtweite und ohne Wand dazwischen?
func can_see(player: Player) -> bool:
	var offset := player.global_position - enemy.global_position
	offset.y = 0.0
	var distance := offset.length()
	if distance > get_sight_range(player):
		return false
	if distance > 0.01:
		var facing := enemy.get_facing_direction()
		var angle := rad_to_deg(facing.angle_to(offset / distance))
		if angle > enemy.data.view_angle * 0.5:
			return false
	var eye := enemy.global_position + Vector3.UP * 1.6
	var target := player.global_position + Vector3.UP * minf(player.get_body_height() * 0.8, 1.4)
	var query := PhysicsRayQueryParameters3D.create(eye, target, PhysicsLayers.WORLD, [enemy.get_rid()])
	return enemy.get_world_3d().direct_space_state.intersect_ray(query).is_empty()


## Sichtweite für diese Spielfigur (geduckt kürzer, Firmenausweis usw.).
func get_sight_range(player: Player) -> float:
	var sight := enemy.get_detection_radius()
	if player.is_crouched():
		sight *= enemy.data.crouch_sight_factor
	return sight


## Lärm an einer Stelle: Ist er nah genug, geht er nachsehen.
func hear(position: Vector3, radius: float) -> void:
	if enemy == null or enemy.health.is_dead or alerted:
		return
	if enemy.global_position.distance_to(position) > radius:
		return
	last_known_position = position
	wants_to_investigate = true
	awareness = maxf(awareness, 0.5)


## Sofort alarmiert (z. B. getroffen).
func alert(at: Vector3) -> void:
	awareness = 1.0
	alerted = true
	last_known_position = at
	wants_to_investigate = false


func reset() -> void:
	awareness = 0.0
	alerted = false
	wants_to_investigate = false
	sees_player = false
	_update_indicator()


func _notice(player: Player, amount: float) -> void:
	last_known_position = player.global_position
	awareness = minf(awareness + amount, 1.0)
	if awareness >= 1.0:
		alerted = true
		wants_to_investigate = false
	elif awareness >= 0.5:
		wants_to_investigate = true


func _fade(delta: float) -> void:
	if alerted:
		return
	awareness = maxf(awareness - delta / maxf(enemy.data.forget_time, 0.05), 0.0)


func _is_running(player: Player) -> bool:
	return player.is_on_floor() and not player.is_crouched() \
		and Vector3(player.velocity.x, 0.0, player.velocity.z).length() > player.character_data.walk_speed + 0.5


func _update_indicator() -> void:
	if _indicator == null or not _indicator.is_inside_tree():
		return
	var show := awareness > 0.01 and not enemy.health.is_dead
	if show and enemy.get_tree().current_scene is RealityLevel:
		show = GameState.reality_sight_active
	_indicator.visible = show
	if not show:
		return
	if alerted:
		_indicator.text = "!"
		_indicator.modulate = Color(1.0, 0.3, 0.25)
	else:
		_indicator.text = "?"
		_indicator.modulate = Color(1.0, 0.85, 0.3, 0.35 + awareness * 0.65)

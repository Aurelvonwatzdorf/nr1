class_name PlayerUseItemState
extends PlayerState
## Gegenstand benutzen (z. B. Trank trinken). Dauert kurz, man geht nur langsam
## und kann nicht angreifen. Die Wirkung kommt erst am Ende.

var _item: ItemData
var _time_left: float = 0.0


func enter(msg: Dictionary = {}) -> void:
	_item = msg.get("item")
	_time_left = _item.use_time
	player.animator.play(&"use_item", _time_left)


func physics_update(delta: float) -> void:
	_time_left -= delta
	player.apply_gravity(delta)
	player.accelerate_to(player.get_move_direction() * 1.5, delta)
	if _time_left <= 0.0:
		player.apply_item_effect(_item)
		return_to_locomotion()

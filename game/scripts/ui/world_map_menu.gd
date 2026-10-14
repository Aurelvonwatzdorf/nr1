class_name WorldMapMenu
extends GameMenu
## Große Karte (Taste M): genordet, ganze Gegend, mit Legende.

@onready var title_label: Label = %TitleLabel
@onready var legend: VBoxContainer = %Legend


func _unhandled_input(event: InputEvent) -> void:
	if is_open and (event.is_action_pressed(&"menu") or event.is_action_pressed(&"map")):
		close()
		get_viewport().set_input_as_handled()
	elif not is_open and event.is_action_pressed(&"map") and not GameState.is_menu_open():
		open()
		get_viewport().set_input_as_handled()


func _on_opened() -> void:
	var map_data := get_tree().get_first_node_in_group(&"map_data") as MapData
	title_label.text = map_data.area_name if map_data and map_data.area_name != "" else "Karte"
	for child in legend.get_children():
		child.queue_free()
	var kinds_present: Array[MapMarker.Kind] = []
	for node: Node in get_tree().get_nodes_in_group(&"map_markers"):
		var marker := node as MapMarker
		if marker and marker.is_shown() and not kinds_present.has(marker.kind):
			kinds_present.append(marker.kind)
	kinds_present.sort()
	for kind in kinds_present:
		var row := Label.new()
		row.text = "%s   %s" % [MapMarker.STYLE[kind][0], MapMarker.get_kind_name(kind)]
		row.add_theme_color_override(&"font_color", MapMarker.STYLE[kind][1])
		legend.add_child(row)

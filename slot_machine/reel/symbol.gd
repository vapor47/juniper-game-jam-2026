extends RefCounted
class_name Symbol

var symbol_name: String
var type: Action.Type
var value: int
var icon: Texture2D  # kept for future art; Phase 1 cells render name+color, not icon

func _init(p_name: String, p_type: Action.Type, p_value: int, p_icon: Texture2D = null) -> void:
	symbol_name = p_name
	type = p_type
	value = p_value
	icon = p_icon

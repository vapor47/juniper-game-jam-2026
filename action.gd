extends RefCounted
class_name Action

enum Type { IDLE, ATTACK, DEFEND, HEAL }

var type: Type
var value: int
var display_string: String

func _init(p_type: Type, p_value: int, p_display_string: String) -> void:
	type = p_type
	value = p_value
	display_string = p_display_string

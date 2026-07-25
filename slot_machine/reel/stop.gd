extends RefCounted
class_name Stop

var symbol: Symbol
var modifiers: Array[StopModifier] = []

func _init(p_symbol: Symbol) -> void:
	symbol = p_symbol

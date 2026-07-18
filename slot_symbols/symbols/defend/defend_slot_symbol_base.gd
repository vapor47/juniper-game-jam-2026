class_name DefendSlotSymbolBase
extends SlotSymbol

func _init() -> void:
	symbol_name = "Defend"
	result_modifier = func(prev): return prev + symbol_value


func get_symbol_type() -> Action.Type:
	return Action.Type.DEFEND

func get_symbol_icon() -> Texture2D:
	return preload("res://at-icons_v1.3.0/addons/at-icons/node2d/shield.svg")

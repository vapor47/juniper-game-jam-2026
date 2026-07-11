@icon("res://at-icons_v1.3.0/addons/at-icons/control/cutlass.svg")

class_name AttackSlotSymbolBase
extends SlotSymbol


func _init() -> void:
	#symbol_type = SymbolType.ATTACK
	result_modifier = func(prev): return prev + symbol_value
	icon = preload("res://at-icons_v1.3.0/addons/at-icons/control/cutlass.svg")

func get_symbol_type() -> SymbolType:
	return SymbolType.ATTACK

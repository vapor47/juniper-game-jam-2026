class_name AttackSlotSymbolBase
extends SlotSymbol

func _init() -> void:
	#symbol_type = SymbolType.ATTACK
	result_modifier = func(prev): return prev + symbol_value
	icon = preload("res://assets/icons/attack_icon.svg")

func get_symbol_type() -> SymbolType:
	return SymbolType.ATTACK

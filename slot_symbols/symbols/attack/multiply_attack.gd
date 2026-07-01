class_name MultiplyAttack
extends AttackSlotSymbolBase

const BASE_VALUE = 3

func _init() -> void:
	symbol_name = "Multiply Attack"
	symbol_value = BASE_VALUE
	result_modifier = func(prev): return prev * symbol_value

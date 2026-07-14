class_name MultiplyDefend
extends DefendSlotSymbolBase

const BASE_VALUE = 1

func _init() -> void:
	symbol_name = "Multiply Defend"
	symbol_value = BASE_VALUE
	value_type = ValueType.MULT
	icon = preload("res://assets/icons/defend/multiply_defend_icon.svg")

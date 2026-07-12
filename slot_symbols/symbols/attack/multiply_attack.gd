class_name MultiplyAttack
extends AttackSlotSymbolBase

const BASE_VALUE = 1

func _init() -> void:
	symbol_name = "Multiply Attack"
	symbol_value = BASE_VALUE
	value_type = ValueType.MULT

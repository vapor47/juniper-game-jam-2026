class_name MultiplyHeal
extends HealSlotSymbolBase

const BASE_VALUE = 1

func _init() -> void:
	symbol_name = "Multiply Heal"
	symbol_value = BASE_VALUE
	value_type = ValueType.MULT

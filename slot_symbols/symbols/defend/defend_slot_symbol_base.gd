class_name DefendSlotSymbolBase
extends SlotSymbol

func _init() -> void:
	symbol_name = "Defend"
	result_modifier = func(prev): return prev + symbol_value


func get_symbol_type() -> SymbolType:
	return SymbolType.DEFEND

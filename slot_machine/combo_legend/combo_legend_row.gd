extends RefCounted
class_name ComboLegendRow

class Result:
	var type: SlotSymbol.SymbolType
	var value: int
	
	func _init(p_symbol: SlotSymbol, p_count: int) -> void:
		type = p_symbol.get_symbol_type()
		value = SymbolResolver._get_combo_value(p_symbol.symbol_value, p_count)

var category: SlotSymbol.SymbolType
var required_symbols: Array[SlotSymbol]
var result: Result

func _init(p_symbol: SlotSymbol, p_count: int) -> void:
	for i in p_count:
		required_symbols.append(p_symbol)
	
	category = p_symbol.get_symbol_type()
	result = Result.new(p_symbol, p_count)

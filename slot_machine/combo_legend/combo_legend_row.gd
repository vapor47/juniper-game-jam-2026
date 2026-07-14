extends RefCounted
class_name ComboLegendRow

#class Result:
	#var type: SlotSymbol.SymbolType
	#var value: int
	#
	#func _init(p_symbol: SlotSymbol, p_count: int) -> void:
		#type = p_symbol.get_symbol_type()
		#value = SymbolResolver._combo_value_from_sum(p_symbol.symbol_value, p_count)

var category: SlotSymbol.SymbolType
var symbol: SlotSymbol
var required_symbols: Array[SlotSymbol]
var result: int


func _init(p_symbol: SlotSymbol, p_count: int) -> void:
	for i in p_count:
		required_symbols.append(p_symbol)
	
	category = p_symbol.get_symbol_type()
	symbol = p_symbol
	result = SymbolResolver._combo_value_from_sum(p_symbol.symbol_value, p_count)

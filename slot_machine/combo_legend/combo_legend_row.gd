extends RefCounted
class_name ComboLegendRow

var category: Action.Type
var symbol: Symbol
var required_symbols: Array[Symbol]
var result: int


func _init(p_symbol: Symbol, p_count: int) -> void:
	for i in p_count:
		required_symbols.append(p_symbol)

	category = p_symbol.type
	symbol = p_symbol
	result = PaylineScorer.run_value(p_symbol, p_count)

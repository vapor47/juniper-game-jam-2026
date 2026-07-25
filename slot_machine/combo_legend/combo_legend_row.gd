extends RefCounted
class_name ComboLegendRow

var category: Action.Type
var symbol: Symbol
var required_symbols: Array[Symbol]
var result: int


## Mirrors PaylineScorer's per-run bonus (§4) — same formula, do not retune here.
func _init(p_symbol: Symbol, p_count: int) -> void:
	for i in p_count:
		required_symbols.append(p_symbol)

	category = p_symbol.type
	symbol = p_symbol
	var run_value := p_symbol.value * p_count
	if p_count >= 2:
		var scale := pow(p_count - 1, 1.3)
		run_value = roundi(run_value + run_value * 0.12 * scale + scale)
	result = run_value

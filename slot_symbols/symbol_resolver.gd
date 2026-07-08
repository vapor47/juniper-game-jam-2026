extends Node

# Takes in ReelStops to account for ReelStop modifiers
# TODO: this whole function will eventually need to be redone
# 		to account for modifiers
func resolve(stops: Array[ReelStop]) -> Array:
	print_debug("Resolving Symbols...")
	var effects = []
	
	var counts = {}
	for stop in stops:
		var symbol = stop.slot_symbol
		counts[symbol] = counts.get(symbol, 0) + 1
	
	var applied_combos = []
	var flat_attack_damage := 0
	var flat_block := 0
	var attack_multiplier := 1
	var block_multiplier := 1
	
	# First check for any combos
	# We need the action type + value, or the action name.
	# but if we go with action name, we still need the value
	for symbol: SlotSymbol in counts:
		var count: int = counts[symbol]
		if count >= 3:
			if symbol.get_symbol_type() == SlotSymbol.SymbolType.ATTACK:
				flat_attack_damage += _get_combo_value(symbol.symbol_value, count)
			elif symbol.get_symbol_type() == SlotSymbol.SymbolType.DEFEND:
				flat_block += _get_combo_value(symbol.symbol_value, count)
			
			applied_combos.append(symbol)
	
	# Then continue resolving effects for non-combos
	for stop: ReelStop in stops:
		var symbol: SlotSymbol = stop.slot_symbol
		if symbol in applied_combos:
			continue
		match symbol.get_symbol_type():
			SlotSymbol.SymbolType.ATTACK:
				if symbol.symbol_name == "Multiply Attack":
					attack_multiplier += 1
				else:
					flat_attack_damage += symbol.symbol_value
			SlotSymbol.SymbolType.DEFEND:
				if symbol.symbol_name == "Multiply Defend":
					block_multiplier += 1
				else:
					flat_block += symbol.symbol_value
	
	var total_attack_damage: int = flat_attack_damage * attack_multiplier
	var total_block: int = flat_block * block_multiplier
	effects.append({ "type": "damage", "value": total_attack_damage})
	effects.append({ "type": "block", "value": total_block})
	
	return effects

func _get_combo_value(symbol_value: int, count: int) -> int:
	return (symbol_value * count) + ((count ** 2) * 4)
#func _resolve_combos(stops: Array[ReelStop]) -> String:
	#pass
"""
input:
	SlotSymbols with name, type, and modifier
	
output:
	Array of Effect objects
		{type: str, value: int}
		
we need to be able to keep track of amounts such that we can score combo
so before iterating at all, we need to check total counts

"""

"""
Symbol Resolver logic:
	Modifiers are applied to a specific reel stop
		Disregard modifiers for now. Brainstorm for time being
	First check for any combos:
		Combo == if 3+ of same symbol appear.
		Result is base_value * 5
		Add symbol to applied_combos, so as to not recount
		
	Then iterate through each stop/symbol:
		if symbol in applied combos:
			continue
		else: apply result_modifier
"""

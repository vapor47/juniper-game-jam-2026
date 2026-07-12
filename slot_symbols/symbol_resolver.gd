extends Node

# symbol_resolver.gd (reworked core — adapt names to your current structure)
static func resolve(ctx: ResolutionContext) -> Array:
	var selected_stops := ctx.selected_stops

	# ---- Phase 1: per-stop values through HOOK A
	var stop_values: Dictionary[ReelStop, int] = {}
	for stop: ReelStop in selected_stops:
		var v := stop.slot_symbol.symbol_value
		for mod: StopModifier in stop.modifiers:
			v = mod.modify_stop_value(v, ctx, stop)
		stop_values[stop] = v

	# ---- Phase 2: combo counting with HOOK C bonuses
	# effective count per symbol = actual count + sum of combo_count_bonus on those stops
	var by_symbol: Dictionary = {}     # SlotSymbol -> Array[ReelStop]
	for stop in selected_stops:
		by_symbol.get_or_add(stop.slot_symbol, []).append(stop)

	var totals: Dictionary[SlotSymbol.SymbolType, int] = {
		#SlotSymbol.SymbolType.ATTACK: 0,
		#SlotSymbol.SymbolType.DEFEND: 0,
		#SlotSymbol.SymbolType.HEAL: 0
	}
	
	for symbol: SlotSymbol in by_symbol:
		var stops: Array = by_symbol[symbol]
		var eff_count := stops.size()
		var value_sum := 0
		for stop: ReelStop in stops:
			value_sum += stop_values[stop]
			for mod: StopModifier in stop.modifiers:
				eff_count += mod.combo_count_bonus()

		var contribution: int
		if eff_count >= 2:
			contribution = _combo_value_from_sum(value_sum, eff_count)
			ctx.combo_symbols.append(symbol)
		else:
			contribution = value_sum
			
		# TODO: Move up?
		if symbol.value_type == SlotSymbol.ValueType.MULT:
			continue
		_add_to_type_total(totals, symbol, contribution)

	# ---- Phase 3: result totals through HOOK B
	for stop in selected_stops:
		for mod: StopModifier in stop.modifiers:
			totals[stop.slot_symbol.get_symbol_type()] = mod.modify_result_total(
					totals[stop.slot_symbol.get_symbol_type()], ctx, stop)
		
		if stop.slot_symbol.value_type == SlotSymbol.ValueType.MULT:
			totals[stop.slot_symbol.get_symbol_type()] = int(ceil(totals[stop.slot_symbol.get_symbol_type()] * (1 + float(stop_values[stop]) / 4)))

	# ---- Phase 4: side effects, HOOK D
	for stop in selected_stops:
		for mod: StopModifier in stop.modifiers:
			mod.on_resolved(ctx, stop)

	return _totals_to_actions(totals)
	
## Locked combo formula, sum-based variant (Phase 1 already individualized stop
## values, so this takes the modified sum rather than symbol_value * count).
## combo = sum + (sum * 0.12 * scale) + scale, scale = (eff_count - 1)^1.3
static func _combo_value_from_sum(value_sum: int, eff_count: int) -> int:
	if eff_count <= 1:
		return value_sum
	var scale := pow(eff_count - 1, 1.3)
	return roundi(value_sum + (value_sum * 0.12 * scale) + scale)

static func _add_to_type_total(totals: Dictionary[SlotSymbol.SymbolType, int], symbol: SlotSymbol, contribution: int) -> void:
	var t := symbol.get_symbol_type()
	totals[t] = totals.get(t, 0) + contribution

static func _totals_to_actions(totals: Dictionary) -> Array[CombatManager.Action]:
	var actions: Array[CombatManager.Action] = []
	for type: SlotSymbol.SymbolType in totals:
		if totals[type] != 0:
			actions.append(CombatManager.Action.new(type, totals[type], ""))
	return actions

# Takes in ReelStops to account for ReelStop modifiers
# TODO: this whole function will eventually need to be redone
# 		to account for modifiers
func resolve_old(stops: Array[ReelStop]) -> Array[CombatManager.Action]:
	print_debug("Resolving Symbols...")
	var effects = []
	
	var counts = {}
	for stop in stops:
		var symbol = stop.slot_symbol
		counts[symbol] = counts.get(symbol, 0) + 1
	
	var applied_combos = []
	var attack_flat := 0
	var attack_mult := 1
	var block_flat := 0
	var heal_flat := 0
	var block_mult := 1
	var heal_mult := 1
	
	# First check for any combos
	# We need the action type + value, or the action name.
	# but if we go with action name, we still need the value
	for symbol: SlotSymbol in counts:
		var count: int = counts[symbol]
		if count >= 2:
			if symbol.get_symbol_type() == SlotSymbol.SymbolType.ATTACK and not symbol.symbol_name.contains("Multiply"):
				attack_flat += _get_combo_value(symbol.symbol_value, count)
			elif symbol.get_symbol_type() == SlotSymbol.SymbolType.DEFEND and not symbol.symbol_name.contains("Multiply"):
				block_flat += _get_combo_value(symbol.symbol_value, count)
			elif symbol.get_symbol_type() == SlotSymbol.SymbolType.HEAL and not symbol.symbol_name.contains("Multiply"):
				heal_flat += _get_combo_value(symbol.symbol_value, count)
			
			applied_combos.append(symbol)
	
	# Then continue resolving effects for non-combos
	for stop: ReelStop in stops:
		var symbol: SlotSymbol = stop.slot_symbol
		var count: int = counts[stop.slot_symbol]
		if symbol in applied_combos:
			continue
		match symbol.get_symbol_type():
			SlotSymbol.SymbolType.ATTACK:
				if symbol.symbol_name == "Multiply Attack":
					attack_mult += count
				else:
					attack_flat += symbol.symbol_value
			SlotSymbol.SymbolType.DEFEND:
				if symbol.symbol_name == "Multiply Defend":
					block_mult += count
				else:
					block_flat += symbol.symbol_value
			SlotSymbol.SymbolType.HEAL:
				if symbol.symbol_name == "Multiply Heal":
					heal_mult += count
				else:
					heal_flat += symbol.symbol_value
				
	
	#var total_attack_damage: int = attack_flat * attack_mult
	#var total_block: int = block_flat * block_mult
	#var total_heal: int = heal_flat * heal_mult
	
	var actions: Array[CombatManager.Action] = [
		CombatManager.Action.new(SlotSymbol.SymbolType.ATTACK, attack_flat * attack_mult, "Attacked enemy for %d!" % (attack_flat * attack_mult)),
		CombatManager.Action.new(SlotSymbol.SymbolType.DEFEND, block_flat * block_mult, "Blocked for %d!" % (block_flat * block_mult)),
		CombatManager.Action.new(SlotSymbol.SymbolType.HEAL, heal_flat * heal_mult, "Healed for %d!" % (heal_flat * heal_mult))
	]
	
	return actions
	

func _get_actions_for_symbols(symbols: Array[SlotSymbol]) -> Array[CombatManager.Action]:
	var symbol_count: Dictionary[SlotSymbol, int] = {}
	for symbol in symbols:
		symbol_count[symbol] = symbol_count.get(symbol, 0) + 1
	var actions: Array[CombatManager.Action] = _consolidate_symbols(symbol_count)
	return actions

func _consolidate_symbols(symbol_count: Dictionary[SlotSymbol, int]) -> Array[CombatManager.Action]:
	var actions: Array[CombatManager.Action]
	
#	How do we take our symbol count and get back a list of action
	var attack_flat: int = 0
	var attack_mult: int = 1
	
	var block_flat: int = 0
	var block_mult: int = 1
	
	var heal_flat: int = 0
	var heal_mult: int = 1
	
	for symbol: SlotSymbol in symbol_count.keys():
		var count = symbol_count[symbol]
		match symbol.get_symbol_type():
			SlotSymbol.SymbolType.ATTACK:
				if "Multiply" in symbol.symbol_name:
					attack_mult += count
				else:
					attack_flat += symbol.symbol_value * count
			SlotSymbol.SymbolType.DEFEND:
				if "Multiply" in symbol.symbol_name:
					block_mult += count
				else:
					block_flat += symbol.symbol_value * count
			SlotSymbol.SymbolType.HEAL:
				if "Multiply" in symbol.symbol_name:
					heal_mult += count
				else:
					heal_flat += symbol.symbol_value * count
	
	actions = [
		CombatManager.Action.new(SlotSymbol.SymbolType.ATTACK, attack_flat * attack_mult, "Attacked enemy for %d!" % (attack_flat * attack_mult)),
		CombatManager.Action.new(SlotSymbol.SymbolType.DEFEND, block_flat * block_mult, "Blocked for %d!" % (block_flat * block_mult)),
		CombatManager.Action.new(SlotSymbol.SymbolType.HEAL, heal_flat * heal_mult, "Healed for %d!" % (heal_flat * heal_mult))
	]
#	from which we need a unique display string for each action
	return actions

func _get_combo_value(symbol_value: int, count: int) -> int:
	if count <= 1:
		return symbol_value * count
	var flat_sum := symbol_value * count
	var scale := pow(count - 1, 1.3)
	return roundi(flat_sum + (flat_sum * 0.12 * scale) + scale)

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

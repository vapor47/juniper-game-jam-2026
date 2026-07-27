extends RefCounted
class_name PaylineScorer
## §4: sum of symbols + per-run bonus for consecutive exact-symbol runs, min
## run 2. One Action per run (not merged by type) so each run resolves and
## animates independently, in left-to-right board order.
##
## §4 calls for retuning both knobs, noting that at the old 0.12 the additive
## `+scale` floor carried almost all the weight at pairs — which is where most
## matches land, so matching barely registered. At 0.35 the multiplicative
## term dominates from a pair upward, and the steeper exponent widens the gap
## between consolidating a run and merely collecting copies.
##
## Hook policy, and the reason scoring is split in two:
##   - *Value* hooks (modify_stop_value, combo_count_bonus, modify_result_total)
##     run inside score_line, because the hover preview has to show what the
##     line will actually pay.
##   - *Side-effect* hooks (on_combo_landed, on_resolved) run only from
##     apply_side_effects, called once at lock-in. The panel re-scores every
##     line on every hover, so firing them here would mint gold on mouseover.
const BONUS_RATE: float = 0.35
const BONUS_EXPONENT: float = 1.35


## One contiguous same-symbol run along a line.
class Run extends RefCounted:
	var symbol: Symbol
	var count: int          # cells actually occupied
	var effective_count: int  # count + combo_count_bonus, what the bonus uses
	var start_column: int
	var value: int          # total contribution incl. bonus
	var bonus: int          # the bonus portion alone (0 when no match)

	func _init(p_symbol: Symbol, p_count: int, p_effective: int, p_start: int,
			p_value: int, p_bonus: int) -> void:
		symbol = p_symbol
		count = p_count
		effective_count = p_effective
		start_column = p_start
		value = p_value
		bonus = p_bonus

	func is_match() -> bool:
		return count >= 2


## Everything the UI and the resolver need from scoring one line.
class LineResult extends RefCounted:
	var runs: Array[Run] = []
	var attack: int = 0
	var block: int = 0
	var heal: int = 0
	var gold: int = 0
	var tokens: int = 0
	## Set when the line came up all Wilds. Combat uses it to mark the moment;
	## nothing announces it beforehand.
	var wild_jackpot: bool = false
	## Payouts that don't map to a single typed run — a Lucky Seven line pays
	## tokens *and* gold off one run.
	var extra: Array[Action] = []

	## One Action per run, in left-to-right board order.
	func to_actions() -> Array[Action]:
		var actions: Array[Action] = []
		for run: Run in runs:
			if run.value != 0:
				actions.append(Action.new(run.symbol.type, run.value, ""))
		actions.append_array(extra)
		return actions

	func matched_runs() -> Array[Run]:
		return runs.filter(func(r: Run) -> bool: return r.is_match())


## What a run of `count` identical symbols pays at base value, bonus included.
## Used by the combo legend, which quotes the unmodified figure — the single
## source of truth for the formula so the two can't drift apart.
## What a clean run of `count` pays, with no modifiers or run effects in play.
## Must honour `combos` the same way score_line does: flat-only symbols (Token)
## pay face value however many land, so a run of three Tokens is 3, not the
## bonus curve's 5. The paytable reads this, and a table that disagrees with
## the machine is worse than no table.
static func run_value(symbol: Symbol, count: int) -> int:
	var flat := symbol.value * count
	return flat if not symbol.combos else _payout(flat, count)


## flat total for the run, and the count the bonus curve is driven by.
static func _payout(flat: int, effective_count: int) -> int:
	if effective_count < 2:
		return flat
	var scale := pow(effective_count - 1, BONUS_EXPONENT)
	return roundi(flat + flat * BONUS_RATE * scale + scale)


static func _active_effects() -> Array[RunEffect]:
	if Global.player == null:
		return [] as Array[RunEffect]
	return Global.player.get_active_effects()


static func score_line(stops: Array[Stop], ctx: ResolutionContext = null) -> LineResult:
	var context := ctx if ctx != null else ResolutionContext.preview(stops)
	# Before any hook runs: adjacency hooks ask the context which cells sit
	# beside them, and one context is reused across every line of a resolution.
	context.line_stops = stops
	var effects := _active_effects()

	# Per-stop value first: stop modifiers, then run-wide effects (§ HOOK A).
	var values: Array[int] = []
	for stop: Stop in stops:
		var v := stop.symbol.value
		for modifier: StopModifier in stop.modifiers:
			v = modifier.modify_stop_value(v, context, stop)
		for effect: RunEffect in effects:
			v = effect.modify_stop_value(v, context, stop)
		values.append(v)

	var result := LineResult.new()

	if _is_all_wild(stops):
		_award_wild_jackpot(result)
		return result

	for span: Array in _runs_in(stops):
		var symbol: Symbol = span[0]
		var from: int = span[1]
		var run_len: int = span[2]

		# Jackpot symbols pay from a table and nothing below their threshold.
		if not symbol.payout.is_empty():
			if run_len >= symbol.min_run:
				_award_jackpot(result, symbol, run_len, from)
			continue

		if symbol.type == Action.Type.NONE:
			continue

		# A wild pays as whatever it stands in for, so its own (zero) value is
		# replaced by the adopted symbol's — its **base** value, deliberately,
		# not the modified one from values[]. A wild beside a Gilded stop copies
		# the symbol, not the investment in that particular stop. Decided rather
		# than inherited; §0's interaction table records it as live behaviour.
		var flat := 0
		for j in range(from, from + run_len):
			flat += values[j] if not stops[j].symbol.is_wild else symbol.value

		# Count bonuses only deepen an existing match; they never turn a
		# single cell into one (§ HOOK C).
		var effective := run_len
		if run_len >= 2 and symbol.combos:
			for j in range(from, from + run_len):
				for modifier: StopModifier in stops[j].modifiers:
					effective += modifier.combo_count_bonus()
			for effect: RunEffect in effects:
				effective += effect.combo_count_bonus()

		# Flat-only symbols (tokens) pay their face value however many land.
		var total := flat if not symbol.combos else _payout(flat, effective)
		if total != 0:
			result.runs.append(Run.new(symbol, run_len, effective, from, total, total - flat))
			_accumulate(result, symbol.type, total)
			if run_len >= 2 and symbol not in context.combo_symbols:
				context.combo_symbols.append(symbol)

	_apply_result_totals(result, stops, context)
	return result


## Runs along the line as [symbol, start, length].
##
## A wild substitutes for whatever it sits beside, so it belongs to every run
## it touches: between two Light Atks it makes one run of three, and between a
## Light Atk and a Med Blk it makes a pair of each. That means runs can overlap
## on a wild cell, which is exactly the intent — the wild is being two symbols
## at once.
static func _runs_in(stops: Array[Stop]) -> Array:
	var runs: Array = []
	var n := stops.size()
	var i := 0
	while i < n:
		if stops[i].symbol.is_wild:
			i += 1
			continue

		var symbol := stops[i].symbol
		# Reach backwards over wilds, then forwards over matches and wilds.
		var from := i
		while from > 0 and stops[from - 1].symbol.is_wild:
			from -= 1
		var to := i
		var probe := i + 1
		while probe < n and (stops[probe].symbol == symbol or stops[probe].symbol.is_wild):
			if stops[probe].symbol == symbol:
				to = probe
			probe += 1
		# Trailing wilds join the run too — they stand in for this symbol.
		while to + 1 < n and stops[to + 1].symbol.is_wild:
			to += 1

		runs.append([symbol, from, to - from + 1])
		# Resume after the last real match, so a wild between two different
		# symbols is reconsidered for the run on its right.
		i = probe
	return runs


static func _is_all_wild(stops: Array[Stop]) -> bool:
	if stops.is_empty():
		return false
	for stop: Stop in stops:
		if not stop.symbol.is_wild:
			return false
	return true


## See SymbolTable.WILD_JACKPOT — an all-wild line would otherwise score
## nothing, since a Wild has no identity to adopt.
static func _award_wild_jackpot(result: LineResult) -> void:
	var j: Dictionary = SymbolTable.WILD_JACKPOT
	result.wild_jackpot = true
	result.attack = j["attack"]
	result.block = j["block"]
	result.heal = j["heal"]
	result.gold = j["gold"]
	result.tokens = j["tokens"]
	for pair in [[Action.Type.ATTACK, j["attack"]], [Action.Type.DEFEND, j["block"]],
			[Action.Type.HEAL, j["heal"]], [Action.Type.GOLD, j["gold"]],
			[Action.Type.TOKEN, j["tokens"]]]:
		if pair[1] > 0:
			result.extra.append(Action.new(pair[0], pair[1], ""))


## Pays straight from the symbol's table, clamped to its longest listed run.
static func _award_jackpot(result: LineResult, symbol: Symbol, run_len: int, from: int) -> void:
	var best := 0
	for length: int in symbol.payout:
		if length <= run_len and length > best:
			best = length
	if best == 0:
		return

	var pair: Array = symbol.payout[best]
	var tokens: int = pair[0]
	var gold: int = pair[1]
	result.runs.append(Run.new(symbol, run_len, run_len, from, 0, 0))
	if tokens > 0:
		result.tokens += tokens
		result.extra.append(Action.new(Action.Type.TOKEN, tokens, ""))
	if gold > 0:
		result.gold += gold
		result.extra.append(Action.new(Action.Type.GOLD, gold, ""))


static func _accumulate(result: LineResult, type: Action.Type, amount: int) -> void:
	match type:
		Action.Type.ATTACK:
			result.attack += amount
		Action.Type.DEFEND:
			result.block += amount
		Action.Type.HEAL:
			result.heal += amount
		Action.Type.GOLD:
			result.gold += amount
		Action.Type.TOKEN:
			result.tokens += amount


## HOOK B — a stop on the line can adjust the line's total for its own type.
static func _apply_result_totals(result: LineResult, stops: Array[Stop],
		ctx: ResolutionContext) -> void:
	for stop: Stop in stops:
		if stop.modifiers.is_empty() or stop.symbol.type == Action.Type.NONE:
			continue
		for modifier: StopModifier in stop.modifiers:
			match stop.symbol.type:
				Action.Type.ATTACK:
					result.attack = modifier.modify_result_total(result.attack, ctx, stop)
				Action.Type.DEFEND:
					result.block = modifier.modify_result_total(result.block, ctx, stop)
				Action.Type.HEAL:
					result.heal = modifier.modify_result_total(result.heal, ctx, stop)


## Fired once, at lock-in — never from a preview. Grants combo payoffs and lets
## modifiers act on having been played (§ HOOK D).
static func apply_side_effects(result: LineResult, stops: Array[Stop],
		ctx: ResolutionContext) -> void:
	for run: Run in result.matched_runs():
		Global.player.broadcast("on_combo_landed", [run.symbol, ctx])
	for stop: Stop in stops:
		for modifier: StopModifier in stop.modifiers:
			modifier.on_resolved(ctx, stop)


## Convenience for callers that only want the actions.
static func score(stops: Array[Stop], ctx: ResolutionContext = null) -> Array[Action]:
	return score_line(stops, ctx).to_actions()

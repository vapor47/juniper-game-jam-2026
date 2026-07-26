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

	## One Action per run, in left-to-right board order.
	func to_actions() -> Array[Action]:
		var actions: Array[Action] = []
		for run: Run in runs:
			if run.value != 0:
				actions.append(Action.new(run.symbol.type, run.value, ""))
		return actions

	func matched_runs() -> Array[Run]:
		return runs.filter(func(r: Run) -> bool: return r.is_match())


## What a run of `count` identical symbols pays at base value, bonus included.
## Used by the combo legend, which quotes the unmodified figure — the single
## source of truth for the formula so the two can't drift apart.
static func run_value(symbol: Symbol, count: int) -> int:
	return _payout(symbol.value * count, count)


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
	var i := 0
	while i < stops.size():
		var symbol := stops[i].symbol
		var run_len := 1
		while i + run_len < stops.size() and stops[i + run_len].symbol == symbol:
			run_len += 1

		if symbol.type != Action.Type.NONE:
			var flat := 0
			for j in range(i, i + run_len):
				flat += values[j]

			# Count bonuses only deepen an existing match; they never turn a
			# single cell into one (§ HOOK C).
			var effective := run_len
			if run_len >= 2:
				for j in range(i, i + run_len):
					for modifier: StopModifier in stops[j].modifiers:
						effective += modifier.combo_count_bonus()
				for effect: RunEffect in effects:
					effective += effect.combo_count_bonus()

			var total := _payout(flat, effective)
			if total != 0:
				result.runs.append(Run.new(symbol, run_len, effective, i, total, total - flat))
				_accumulate(result, symbol.type, total)
				if run_len >= 2 and symbol not in context.combo_symbols:
					context.combo_symbols.append(symbol)

		i += run_len

	_apply_result_totals(result, stops, context)
	return result


static func _accumulate(result: LineResult, type: Action.Type, amount: int) -> void:
	match type:
		Action.Type.ATTACK:
			result.attack += amount
		Action.Type.DEFEND:
			result.block += amount
		Action.Type.HEAL:
			result.heal += amount


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

extends RefCounted
class_name PaylineScorer
## §4: sum of symbols + per-run bonus for consecutive exact-symbol runs, min
## run 2. One Action per run (not merged by type) so each run resolves and
## animates independently, in left-to-right board order.
##
## Bonus formula and both constants (0.12, 1.3) are locked per §4 —
## do not retune here.

const BONUS_RATE: float = 0.12
const BONUS_EXPONENT: float = 1.3


## One contiguous same-symbol run along a line.
class Run extends RefCounted:
	var symbol: Symbol
	var count: int
	var start_column: int
	var value: int      # total contribution incl. bonus
	var bonus: int      # the bonus portion alone (0 when count < 2)

	func _init(p_symbol: Symbol, p_count: int, p_start: int, p_value: int, p_bonus: int) -> void:
		symbol = p_symbol
		count = p_count
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


static func score_line(stops: Array[Stop]) -> LineResult:
	var result := LineResult.new()
	var i := 0
	while i < stops.size():
		var symbol := stops[i].symbol
		var run_len := 1
		while i + run_len < stops.size() and stops[i + run_len].symbol == symbol:
			run_len += 1

		if symbol.type != Action.Type.NONE:
			var flat := symbol.value * run_len
			var total := flat
			var bonus := 0
			if run_len >= 2:
				var scale := pow(run_len - 1, BONUS_EXPONENT)
				total = roundi(flat + flat * BONUS_RATE * scale + scale)
				bonus = total - flat

			if total != 0:
				result.runs.append(Run.new(symbol, run_len, i, total, bonus))
				match symbol.type:
					Action.Type.ATTACK:
						result.attack += total
					Action.Type.DEFEND:
						result.block += total
					Action.Type.HEAL:
						result.heal += total

		i += run_len
	return result


## Convenience for callers that only want the actions (Phase 1 shape).
static func score(stops: Array[Stop]) -> Array[Action]:
	return score_line(stops).to_actions()
